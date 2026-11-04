# Funcoes comuns aos scripts que rodam no celular.
DG_DIR="${DG_DIR:-/data/local/tmp/dg}"
SAIDA="$DG_DIR/saida"
mkdir -p "$SAIDA"

# Tira e-mail, IP, MAC, SSID e identificadores antes de qualquer coisa ir para arquivo.
higienizar() {
  sed -E \
    -e '/versionName=|versionCode=/!s/([0-9]{1,3}\.){3}[0-9]{1,3}(\/[0-9]+)?/<ip>/g' \
    -e 's/([0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}/<mac>/g' \
    -e 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/<email>/g' \
    -e 's/[Ss][Ss][Ii][Dd][=:] *"?[^",]*"?/ssid=<oculto>/g' \
    -e 's/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/<id>/g' \
    -e 's/(IMEI|imei|IMSI|imsi|ICCID|iccid|[Ss]erial)[=: ]+[0-9a-zA-Z]+/\1=<oculto>/g'
}

titulo() { printf '\n\n===== %s =====\n' "$1"; }

# Tempo desde o ultimo toque. Vazio significa que este Android nao informa.
ultimo_toque_ms() {
  dumpsys power 2>/dev/null | sed -n 's/^ *lastUserActivityTime=.*(\([0-9]*\) ms ago).*/\1/p' | head -1
}

tela_bloqueada() { dumpsys window 2>/dev/null | grep -q 'isKeyguardShowing=true'; }

foco() { dumpsys window 2>/dev/null | grep -m1 'mCurrentFocus' | sed 's/^ *//'; }

papel() { cmd role get-role-holders --user 0 "android.app.role.$1" | tr -d '\r' | head -1; }

# $1 = milissegundos sem toque, $2 = limite de espera em segundos.
# Retorna 0 parado, 1 tempo esgotado, 2 este Android nao informa o ultimo toque.
esperar_parado() {
  _espera=0
  while :; do
    _i=$(ultimo_toque_ms)
    [ -z "$_i" ] && return 2
    [ "$_i" -ge "$1" ] && return 0
    [ "$_espera" -ge "$2" ] && return 1
    sleep 10
    _espera=$((_espera + 10))
  done
}

# Espera a pessoa largar o celular. Sem como saber, avisa e da um tempo curto.
largar() {
  esperar_parado 20000 "$1"
  case $? in
    1) echo "TEMPO ESGOTADO: o celular continuou em uso"; exit 3;;
    2) echo "AVISO: este Android nao informa o ultimo toque; esperando 20 s sem poder confirmar"; sleep 20;;
  esac
}

# Aceita plano com CRLF, BOM e sem quebra de linha no fim.
normalizar_plano() { { tr -d '\r\357\273\277' < "$1"; echo; } > "$1.lf"; }

# Nada aqui pode ser removido, desativado ou restringido, mesmo que o plano peca.
PROTEGIDOS='^(android|com\.android\.(vending|settings|systemui|phone|bluetooth|nfc|server\.telecom|shell|permissioncontroller|packageinstaller|providers\..*)|com\.google\.android\.(gms|gsf|gmsintegration|permissioncontroller|packageinstaller|webview|networkstack.*|ext\..*|apps\.walletnfcrel)|com\.samsung\.android\.(knox\..*|kgclient|samsungpass.*|authfw|fmm|spay.*|dialer|messaging|incallui|honeyboard|game\.gos|scloud|mobileservice|scs)|com\.samsung\.knox\..*|com\.sec\.enterprise\.knox\..*|com\.knox\..*|com\.osp\.app\.signin|com\.wssyncmldm|com\.sec\.android\.soagent|com\.sec\.android\.smartfpsadjuster|com\.sec\.android\.app\.(launcher|camera|samsungapps)|com\.sec\.android\.gallery3d)$'

# Ajustes de seguranca e atualizacao que o plano nao pode mexer.
AJUSTES_PROIBIDOS='^(package_verifier.*|verifier_.*|always_finish_activities|adb_enabled|development_settings_enabled|ota_.*|auto_update.*)$'

protegido() {
  echo "$1" | grep -qE "$PROTEGIDOS" && return 0
  for _p in DIALER SMS HOME ASSISTANT; do
    [ "$(papel "$_p")" = "$1" ] && return 0
  done
  [ "$(settings get secure default_input_method | cut -d/ -f1)" = "$1" ] && return 0
  return 1
}
