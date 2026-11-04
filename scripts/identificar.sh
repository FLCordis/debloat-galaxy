# Ajuda a descobrir o que e um pacote de nome estranho, sem consultar a internet.
# Uso: identificar.sh PACOTE. Somente leitura.
. "$(dirname "$0")/comum.sh"
P="$1"
[ -z "$P" ] && { echo "uso: identificar.sh PACOTE"; exit 2; }
T="$DG_DIR/id.tmp"
dumpsys package "$P" | tr -d '\r' > "$T"
ARQ="$SAIDA/identificar-$P.txt"
{
  echo "===== $P ====="
  grep -E 'versionName=|firstInstallTime=|lastUpdateTime=|installerPackageName=|initiatingPackageName=' "$T" | sed 's/^ *//' | sort -u
  echo "tela principal: $(cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.LAUNCHER "$P" | tr -d '\r' | tail -1)"
  echo "uso (5 isento, 10 agora, 20 frequente, 30 regular, 40 raro, 45 restrito, 50 nunca): $(am get-standby-bucket "$P" | tr -d '\r')"
  echo "-- componentes, agrupados pelo prefixo. O nome das classes costuma revelar a marca e os SDKs"
  grep -oE "$P/[A-Za-z0-9_.\$]+" "$T" | sed "s#^$P/##" | grep -E '^[a-z]' | cut -d. -f1-3 | sort | uniq -c | sort -rn | head -25
  echo "-- SDKs de anuncio, rastreio ou beacon reconhecidos"
  grep -oiE 'applovin|ironsource|unity3d\.ads|facebook\.ads|gms\.ads|altbeacon|technopartner|adjust\.sdk|appsflyer|branch\.io|inmobi|mintegral|bytedance\.sdk|kochava|singular\.sdk|clevertap|onesignal|braze' "$T" | tr 'A-Z' 'a-z' | sort -u | tr '\n' ' '
  echo
  echo "-- permissoes concedidas"
  grep -E ': granted=true' "$T" | sed -E 's/^ *//; s/: granted=true.*//' | sort -u | grep -E '^android\.permission\.' | sed 's/android.permission.//' | tr '\n' ' '
  echo
  echo "-- sobras no armazenamento (so nomes)"
  find /storage/emulated/0/ -maxdepth 5 -iname "*$P*" 2>/dev/null | sed 's#/storage/emulated/0/##' | higienizar | head -15
} | higienizar > "$ARQ"
rm -f "$T"
cat "$ARQ"
