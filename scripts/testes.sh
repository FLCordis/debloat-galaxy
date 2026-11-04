# Fase 4: faz sozinho o que da para testar e confere se o plano persistiu.
# Abre Camera, Galeria, Telefone e Mensagens sem fotografar, ligar ou ler nada.
. "$(dirname "$0")/comum.sh"
ARQ="$SAIDA/testes.txt"
PLANO="$DG_DIR/plano.txt"

largar 300
if tela_bloqueada; then echo "TELA BLOQUEADA: preciso que desbloqueie e deixe parado"; exit 4; fi

res() { printf '%-7s %s\n' "$1" "$2"; }
crashes() { logcat -d -b crash | tr -d '\r' | grep -c 'FATAL EXCEPTION'; }

abre() {
  _nome="$1"; shift
  _s=$(am start -W "$@" 2>&1 | tr -d '\r' | grep -E '^Status|Error' | head -1)
  sleep 2
  _f=$(foco | sed -E 's/.* u0 ([^\/ }]+).*/\1/')
  case "$_s" in
    *ok*) res OK "$_nome abriu: $_f";;
    *) res FALHOU "$_nome: ${_s:-sem resposta}";;
  esac
}

{
  echo "===== Testes: $(date '+%Y-%m-%d %H:%M:%S') ====="
  echo "-- conexao"
  ping -c 2 -W 3 google.com >/dev/null 2>&1 && res OK "internet" || res FALHOU "internet"
  M=$(settings get global private_dns_mode | tr -d '\r')
  if [ "$M" = "hostname" ]; then
    dumpsys connectivity 2>/dev/null | grep -qE 'ValidatedPrivateDnsAddresses: *\[[^] ]' && res OK "DNS privado validado: $(settings get global private_dns_specifier | tr -d '\r')" || res FALHOU "DNS privado configurado mas nao validado"
  else
    res INFO "DNS privado: $M"
  fi
  res INFO "Bluetooth ligado: $(settings get global bluetooth_on | tr -d '\r')"
  res INFO "chips: $(getprop gsm.sim.state | tr -d '\r')"

  echo "-- padroes"
  for r in DIALER SMS BROWSER HOME; do
    p=$(papel "$r")
    [ -n "$p" ] && res OK "$r: $p" || res FALHOU "$r sem app padrao"
  done
  T=$(settings get secure default_input_method | tr -d '\r')
  ime list -s | tr -d '\r' | grep -qx "$T" && res OK "teclado: ${T%%/*}" || res FALHOU "teclado ativo nao esta na lista: $T"

  echo "-- apps essenciais abrem"
  C0=$(crashes)
  abre "Camera" -a android.media.action.STILL_IMAGE_CAMERA
  input keyevent KEYCODE_HOME; sleep 1
  abre "Galeria" -a android.intent.action.MAIN -c android.intent.category.APP_GALLERY
  input keyevent KEYCODE_HOME; sleep 1
  abre "Telefone" -a android.intent.action.DIAL
  input keyevent KEYCODE_HOME; sleep 1
  abre "Mensagens" -a android.intent.action.MAIN -c android.intent.category.APP_MESSAGING
  input keyevent KEYCODE_HOME; sleep 2
  case "$(foco)" in
    *"$(papel HOME)"*) res OK "tela inicial voltou";;
    *) res FALHOU "tela inicial nao voltou: $(foco | cut -c1-80)";;
  esac
  C1=$(crashes)
  [ "$C1" = "$C0" ] && res OK "nenhum crash novo durante os testes" || res FALHOU "$((C1 - C0)) crash(es) durante os testes"
  echo "crashes registrados no log atual, por processo:"
  logcat -d -b crash | tr -d '\r' | grep -E 'Process: ' | sed -E 's/.*Process: ([^,]+).*/\1/' | sort | uniq -c | sed 's/^/  /'

  if [ -f "$PLANO" ]; then
    echo "-- plano persistiu depois do reinicio"
    normalizar_plano "$PLANO"
    exec 3< "$PLANO.lf"
    while read -r ACAO A1 A2 A3 <&3; do
      case "$ACAO" in
        remover|desativar)
          if ! pm list packages --user 0 "$A1" | tr -d '\r' | grep -qx "package:$A1"; then res OK "fora: $A1"
          elif pm list packages -d --user 0 "$A1" | tr -d '\r' | grep -qx "package:$A1"; then res OK "desativado: $A1"
          else res FALHOU "continua ativo: $A1"; fi;;
        restringir)
          cmd appops get --user 0 "$A1" RUN_ANY_IN_BACKGROUND | grep -q ': ignore' && res OK "restrito: $A1" || res FALHOU "nao restrito: $A1";;
        revogar)
          dumpsys package "$A1" 2>/dev/null | grep -q "$A2: granted=true" && res FALHOU "voltou a ter $A2: $A1" || res OK "sem ${A2##*.}: $A1";;
        negar-instalar)
          cmd appops get --user 0 "$A1" REQUEST_INSTALL_PACKAGES | grep -q ': deny' && res OK "nao instala apps: $A1" || res FALHOU "pode instalar apps: $A1";;
        ajuste)
          V=$(settings get "$A1" "$A2" | tr -d '\r')
          [ "$V" = "$A3" ] && res OK "$A2 = $A3" || res FALHOU "$A2 = $V, esperado $A3";;
      esac
    done
    exec 3<&-
  fi
} > "$ARQ" 2>&1
cat "$ARQ"
