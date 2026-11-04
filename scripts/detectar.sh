# Descobre sozinho o que o quiz nao precisa perguntar. Somente leitura.
. "$(dirname "$0")/comum.sh"
ARQ="$SAIDA/detectar.txt"
LISTA="$DG_DIR/lista.tmp"
pm list packages -e --user 0 | tr -d '\r' | cut -d: -f2 | sort > "$LISTA"

tem() { grep -qx "$1" "$LISTA"; }
balde() {
  case "$(am get-standby-bucket "$1" 2>/dev/null | tr -d '\r')" in
    5) echo isento;; 10) echo uso-agora;; 20) echo uso-frequente;; 30) echo uso-regular;;
    40) echo uso-raro;; 45) echo restrito;; 50) echo nunca-usado;; *) echo desconhecido;;
  esac
}
recurso() {
  _nome="$1"; shift
  for _pk in "$@"; do
    if tem "$_pk"; then echo "recurso_$_nome=$_pk $(balde "$_pk")"; return; fi
  done
  echo "recurso_$_nome=ausente"
}
candidatos() { grep -iE "$2" "$LISTA" | tr '\n' ' ' | sed "s/^/$1=/; s/ *$//"; echo; }

{
  echo "# aparelho"
  for p in ro.product.manufacturer ro.product.model ro.product.device ro.build.version.release ro.build.version.sdk ro.build.version.oneui ro.build.version.security_patch ro.soc.model ro.csc.sales_code ro.boot.verifiedbootstate ro.boot.flash.locked ro.boot.warranty_bit knox.kg.state gsm.sim.state; do
    echo "$p=$(getprop "$p" | tr -d '\r')"
  done
  echo "uptime_h=$(awk '{printf "%.1f", $1/3600}' /proc/uptime)"

  echo "# controle do aparelho"
  dumpsys device_policy | tr -d '\r' | grep -A3 -E 'Device Owner Type|Device Owner:|Profile Owner' | grep -v '^--' | sed 's/^ *//' | higienizar | head -20
  dumpsys device_policy | tr -d '\r' | awk '/Enabled Device Admins/{f=1;next} f&&/^    [a-zA-Z].*\/.*:$/{gsub(/[ :]/,"");print "admin="$0} /^  [A-Z]/{if(!/Enabled Device Admins/)f=0}'
  echo "usuarios=$(pm list users | tr -d '\r' | grep -c UserInfo)"
  pm list users | tr -d '\r' | grep -q 'UserInfo{150:' && echo "pasta_segura_criada=sim" || echo "pasta_segura_criada=nao"
  pm list users | tr -d '\r' | grep -qE 'UserInfo\{1[0-9]:' && echo "perfil_trabalho=possivel" || echo "perfil_trabalho=nao"

  echo "# contas, so tipo e quantidade"
  dumpsys account | tr -d '\r' | grep -E 'Account \{name=' | sed -E 's/.*type=([^}]+)\}.*/\1/' | sort | uniq -c | awk '{print "conta_"$2"="$1}'

  echo "# recursos que dependem de uso"
  recurso carteira_samsung com.samsung.android.spay
  recurso carteira_google com.google.android.apps.walletnfcrel
  recurso rotinas com.samsung.android.app.routines
  recurso link_windows com.microsoft.appmanager
  recurso smart_view com.samsung.android.smartmirroring
  recurso android_auto com.google.android.projection.gearhead
  recurso relogio com.samsung.android.app.watchmanager
  recurso fones com.samsung.accessory.atticmgr com.samsung.accessory.budsunitemgr com.samsung.accessory.pearlmgr
  recurso kids com.sec.android.app.kidshome com.samsung.android.kidsinstaller
  recurso clima com.sec.android.daemonapp
  recurso paineis_laterais com.samsung.android.app.taskedge com.samsung.android.app.clipboardedge
  recurso alexa com.amazon.dee.app

  echo "# padroes atuais"
  for r in DIALER SMS BROWSER HOME ASSISTANT; do echo "papel_$r=$(papel "$r")"; done
  echo "teclado=$(settings get secure default_input_method | tr -d '\r' | cut -d/ -f1)"
  candidatos navegadores 'com\.android\.chrome|sbrowser|org\.mozilla|com\.brave\.|com\.microsoft\.emmx|com\.opera\.|duckduckgo|vivaldi|kiwibrowser'

  echo "# candidatos a proteger, a confirmar no quiz"
  candidatos protege_banco 'bank|banco|banking|bradesco|itau|\.nu\.|nubank|santander|caixa|sicredi|sicoob|\.inter\.|c6bank|picpay|mercadopago|pagseguro|pagbank|neon|btg|\.xp\.|binance|coinbase|paypal|revolut|\.wise|nomad|cloudwalk|\.bb\.android|sofisa|safra'
  candidatos protege_2fa_senhas 'authenticator|authy|2fa|twofas|ente\.auth|yubi|bitwarden|1password|lastpass|dashlane|keepass|proton\.pass'
  candidatos protege_trabalho 'slack|\.teams|office\.outlook|zoom|webex|intune|okta|duosecurity|whatsapp\.w4b|salesforce|atlassian'
  candidatos protege_governo '\.gov\.|serpro|dataprev|tse\.'

  echo "# ajustes atuais"
  for k in private_dns_mode private_dns_specifier http_proxy wifi_scan_always_enabled ble_scan_always_enabled stay_on_while_plugged_in animator_duration_scale protect_battery battery_protection_threshold; do
    echo "$k=$(settings get global "$k" | tr -d '\r')"
  done
  echo "always_on_vpn_app=$(settings get secure always_on_vpn_app | tr -d '\r')"

  echo "# capacidade"
  S=$(getprop ro.build.version.sdk | tr -d '\r')
  if [ "${S:-0}" -ge 37 ]; then echo "remover_app_de_sistema=provavelmente recusado; usar desativacao"; else echo "remover_app_de_sistema=provavelmente aceito"; fi
} > "$ARQ"
rm -f "$LISTA"
cat "$ARQ"
