# Fase 1: somente leitura. Nao toca na tela e nao muda nada.
. "$(dirname "$0")/comum.sh"
ARQ="$SAIDA/varredura.txt"
TMP="$DG_DIR/v.tmp"

A() { "$@" 2>&1 | tr -d '\r'; }

{
echo "Varredura iniciada: $(date '+%Y-%m-%d %H:%M:%S')"

titulo "IDENTIDADE E INTEGRIDADE"
for p in ro.product.model ro.product.device ro.build.version.release ro.build.version.oneui ro.build.display.id ro.build.version.security_patch ro.soc.model ro.boot.verifiedbootstate ro.boot.flash.locked ro.boot.warranty_bit ro.csc.sales_code knox.kg.state; do
  printf '%s = %s\n' "$p" "$(getprop "$p" | tr -d '\r')"
done
printf 'uptime_h = %s\n' "$(awk '{printf "%.1f", $1/3600}' /proc/uptime)"

titulo "DEVICE POLICY"
A dumpsys device_policy | higienizar > "$TMP"
grep -E 'Enabled Device Admins|^    [a-zA-Z].*/.*:$' "$TMP" | cut -c1-160
grep -A3 -E 'Device Owner|Profile Owner' "$TMP" | grep -v '^--' | cut -c1-160 | head -20

titulo "USUARIOS E CONTAS (sem nomes)"
A pm list users | sed -E 's/UserInfo\{([0-9]+):[^:]*:/UserInfo{\1:<nome>:/'
A dumpsys account | grep -E 'Account \{name=' | sed -E 's/.*type=([^}]+)\}.*/\1/' | sort | uniq -c

titulo "APPS: contagens"
A pm list packages -e --user 0 | cut -d: -f2 | sort > "$SAIDA/antes.txt"
echo "ativos=$(wc -l < "$SAIDA/antes.txt")"
echo "desativados=$(A pm list packages -d --user 0 | wc -l)"
echo "sistema=$(A pm list packages -s --user 0 | wc -l)"
echo "terceiros=$(A pm list packages -3 --user 0 | wc -l)"

titulo "APPS DESATIVADOS: quem desativou (enabled 2 sistema, 3 usuario, 4 ate usar; auto_disabler e a Samsung por falta de uso)"
for p in $(A pm list packages -d --user 0 | cut -d: -f2); do
  A dumpsys package "$p" > "$TMP"
  e=$(grep -m1 -E '^ *User 0:' "$TMP" | grep -oE ' enabled=[0-9]' | head -1)
  c=$(grep -m1 -oE 'lastDisabledCaller: [^ ]+' "$TMP")
  echo "$p$e $c"
done | sort

titulo "APPS DE TERCEIROS: instalador fora de Play e Galaxy Store"
A pm list packages -i -3 --user 0 | grep -vE 'installer=(com.android.vending|com.sec.android.app.samsungapps)$' | sed 's/^package://' | sort

titulo "APPS DE TERCEIROS: datas, instalador e permissoes sensiveis concedidas"
SENS='READ_SMS|RECEIVE_SMS|SEND_SMS|READ_CALL_LOG|WRITE_CALL_LOG|CALL_PHONE|ANSWER_PHONE_CALLS|READ_CONTACTS|RECORD_AUDIO|CAMERA|ACCESS_FINE_LOCATION|ACCESS_BACKGROUND_LOCATION|READ_PHONE_STATE|SYSTEM_ALERT_WINDOW|QUERY_ALL_PACKAGES|REQUEST_INSTALL_PACKAGES|PACKAGE_USAGE_STATS|MANAGE_EXTERNAL_STORAGE|BLUETOOTH_SCAN|READ_MEDIA_IMAGES|READ_MEDIA_VIDEO'
for p in $(A pm list packages -3 --user 0 | cut -d: -f2); do
  A dumpsys package "$p" > "$TMP"
  echo "## $p"
  grep -E 'versionName=|firstInstallTime=|lastUpdateTime=|installerPackageName=|initiatingPackageName=' "$TMP" | sed 's/^ *//' | sort -u | tr '\n' ' '
  echo
  echo "perm: $(grep -E ': granted=true' "$TMP" | grep -E "android\.permission\.($SENS):" | sed -E 's/^ *android\.permission\.//; s/: granted=true.*//' | sort -u | tr '\n' ' ')"
done | higienizar

titulo "APPS QUE PARECEM SERVICO DE FABRICA OU DE PARCEIRO"
grep -E '^com\.(facebook|microsoft|linkedin|netflix|amazon|hiya|applovin|ironsource|digitalturbine)' "$SAIDA/antes.txt"

titulo "USO: buckets de terceiros ativos (5 isento, 10 agora, 20 frequente, 30 regular, 40 raro, 45 restrito, 50 nunca)"
for p in $(A pm list packages -3 -e --user 0 | cut -d: -f2); do echo "$(am get-standby-bucket "$p" | tr -d '\r') $p"; done | sort -n

titulo "PODERES PERIGOSOS"
echo "-- acessibilidade"; A settings get secure enabled_accessibility_services
echo "-- leitura de notificacoes"; A settings get secure enabled_notification_listeners | tr ':' '\n' | cut -d/ -f1
echo "-- sobreposicao"; A appops query-op --user 0 SYSTEM_ALERT_WINDOW allow
echo "-- instalar apps"
for p in $(A appops query-op --user 0 REQUEST_INSTALL_PACKAGES allow); do echo "$p: $(A cmd appops get --user 0 "$p" REQUEST_INSTALL_PACKAGES | head -1 | cut -c1-110)"; done
echo "-- estatisticas de uso"; A appops query-op --user 0 GET_USAGE_STATS allow
echo "-- todos os arquivos"; A appops query-op --user 0 MANAGE_EXTERNAL_STORAGE allow
for r in DIALER SMS BROWSER HOME ASSISTANT; do echo "-- papel $r: $(papel "$r")"; done
echo "-- teclado: $(A settings get secure default_input_method)"
A ime list -s
echo "-- isentos de otimizacao de bateria pelo usuario"; A dumpsys deviceidle whitelist | grep -E '^user,' | cut -d, -f2

titulo "REDE"
for k in http_proxy global_http_proxy_host global_http_proxy_port private_dns_mode private_dns_specifier wifi_scan_always_enabled ble_scan_always_enabled; do
  printf '%s = %s\n' "$k" "$(A settings get global "$k")"
done
printf 'always_on_vpn_app = %s\n' "$(A settings get secure always_on_vpn_app)"
A dumpsys connectivity > "$TMP"
grep -oE 'UsePrivateDns: [a-z]+|PrivateDnsServerName: [^ ]+|ValidatedPrivateDnsAddresses: *\[[^]]*\]' "$TMP" | sed -E 's/\[.+\]/[validado]/; s/\[ *\]/[vazio]/' | sort -u
grep -cE 'ni\{VPN' "$TMP" | sed 's/^/redes_vpn_ativas = /'
echo "-- certificados de usuario"; A ls /data/misc/user/0/cacerts-added

titulo "BATERIA: saude"
A dumpsys battery | grep -E '^ *(AC powered|USB powered|Wireless powered|status|health|level|temperature|mProtectBatteryMode|mProtectionThreshold|mMaximumProtectionThreshold):|mSavedBatteryAsoc|FirstUseDate:|mSavedBatteryMaxTemp' | sed 's/^ *//'
for k in protect_battery battery_protection_threshold; do printf '%s = %s\n' "$k" "$(A settings get global "$k")"; done

titulo "TERMICO"
A dumpsys thermalservice | grep -E '^Thermal Status|mName=(AP|BAT|SKIN)' | head -8 | cut -c1-90

titulo "ARMAZENAMENTO"
A df -h /data | tail -1
A dumpsys diskstats > "$TMP"
grep -E '^(Data-Free|App Size:|App Data Size:|App Cache Size:|Photos Size:|Videos Size:|Audio Size:)' "$TMP"
echo "-- top por dados e cache. 'nao instalado' e dado antigo: o diskstats recalcula uma vez por dia"
A pm list packages --user 0 | cut -d: -f2 > "$DG_DIR/inst.tmp"
awk -v LISTA="$DG_DIR/inst.tmp" '
function arr(l,a,  n,i){ sub(/^[^[]*\[/,"",l); sub(/\].*$/,"",l); n=split(l,a,","); for(i=1;i<=n;i++) gsub(/"/,"",a[i]); return n }
function top(v,titulo,  i,j,m,mx,usado){ print titulo; for(j=1;j<=12;j++){ mx=-1; m=0; for(i=1;i<=N;i++) if(!(i in usado)&&v[i]+0>mx){mx=v[i]+0;m=i} if(!m||mx<=0)break; usado[m]=1; printf "%7.2f GB %s%s\n", mx/1073741824, nome[m], (nome[m] in ativo)?"":" (nao instalado)" } }
BEGIN{ while((getline x < LISTA)>0) ativo[x]=1 }
/^Package Names:/{ N=arr($0,nome) } /^App Data Sizes:/{ arr($0,dado) } /^Cache Sizes:/{ arr($0,cache) }
END{ top(dado,"dados"); top(cache,"cache") }' "$TMP"
rm -f "$DG_DIR/inst.tmp"
echo "-- pastas (MB)"
A sh -c 'du -s -m /storage/emulated/0/* 2>/dev/null' | sed 's#/storage/emulated/0/##' | sort -rn | head -15 | higienizar
for d in media data obb; do
  echo "-- Android/$d (MB)"
  A sh -c "du -s -m /storage/emulated/0/Android/$d/* 2>/dev/null" | sed "s#/storage/emulated/0/Android/$d/##" | sort -rn | head -8
done

titulo "CAMERA"
for p in $(A pm list packages --user 0 | cut -d: -f2 | grep -iE 'camera|photo|retouch|gallery'); do
  echo "$p $(A dumpsys package "$p" | grep -E 'versionName=|lastUpdateTime=' | sed 's/^ *//' | sort -u | tr '\n' ' ')"
done
echo "-- logcat E/W de camera, ultimas 3000 linhas"
A logcat -d -t 3000 | grep -iE 'camera|camx' | grep -E ' [EW] ' | higienizar | sed -E 's#/storage/emulated/0/[^ ]*#<caminho>#g' | cut -c1-200 | head -40

echo
echo "Varredura concluida: $(date '+%Y-%m-%d %H:%M:%S')"
} > "$ARQ"
rm -f "$TMP"
echo "ok: $(wc -l < "$ARQ") linhas em varredura.txt"
