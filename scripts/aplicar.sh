# Fase 3: aplica somente o que esta em plano.txt e registra cada passo.
# Uso: aplicar.sh ou aplicar.sh --simular
#
# Formato de plano.txt, uma acao por linha, comecando por aparelho e depois grupo:
#   aparelho MODELO           precisa ser o modelo do celular conectado
#   grupo NOME
#   remover PACOTE            desinstala; em app de sistema recusado, desativa
#   desativar PACOTE
#   restringir PACOTE         segundo plano como "Restrito"
#   revogar PACOTE PERMISSAO
#   negar-instalar PACOTE     tira a permissao de instalar apps
#   ajuste global|secure|system CHAVE VALOR
#
# Saidas: 0 ok, 2 plano ausente ou invalido, 3 celular em uso, 4 tela bloqueada, 5 grupo desfeito por erro.
. "$(dirname "$0")/comum.sh"
SIMULAR=0
[ "$1" = "--simular" ] && SIMULAR=1
PLANO="$DG_DIR/plano.txt"
LOG="$SAIDA/alteracoes.txt"
REM="$SAIDA/removidos.txt"
ACOES="$SAIDA/restaurar-acoes.txt"
DESFAZER="$DG_DIR/desfazer.tmp"
[ -f "$PLANO" ] || { echo "ERRO: plano.txt nao encontrado"; exit 2; }
normalizar_plano "$PLANO"
awk -v M="$(getprop ro.product.model | tr -d '\r')" '
  /^[ \t]*(#|$)/ { next }
  !a {
    x=$0; sub(/^aparelho[ \t]+/,"",x); sub(/[ \t]+$/,"",x)
    if ($1!="aparelho") { print "ERRO: a primeira acao do plano deve ser: aparelho " M; e=1; exit }
    if (x!=M) { print "ERRO: este plano e de " x ", e o aparelho conectado e " M; e=1; exit }
    a=1; next
  }
  !g { if ($1!="grupo") { print "ERRO: a primeira acao depois de aparelho deve ser um grupo"; e=1; exit } g=1 }
  $1!~/^(grupo|remover|desativar|restringir|revogar|negar-instalar|ajuste)$/ { print "ERRO: acao desconhecida: " $1; e=1; exit }
  END { exit e }' "$PLANO.lf" || exit 2
touch "$LOG" "$REM" "$ACOES"

registrar() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG"; }
volta() { echo "$*" >> "$ACOES"; }
listado() { pm list packages --user 0 "$1" | tr -d '\r' | grep -qx "package:$1"; }
desativado() { pm list packages -d --user 0 "$1" | tr -d '\r' | grep -qx "package:$1"; }
terceiro() { pm list packages -3 --user 0 "$1" | tr -d '\r' | grep -qx "package:$1"; }
concedida() { dumpsys package "$1" 2>/dev/null | grep -q "$2: granted=true"; }
barrado() { if protegido "$1"; then registrar "RECUSADO pela lista de protecao: $2 $1"; return 0; fi; return 1; }

conferir_tela() {
  input keyevent KEYCODE_HOME
  sleep 3
  tela_bloqueada && return 4
  foco | grep -q "$(papel HOME)"
}

fechar_grupo() {
  [ -z "$GRUPO" ] && return 0
  [ "$SIMULAR" = "1" ] && { GRUPO=""; return 0; }
  conferir_tela
  case $? in
    0) registrar "GRUPO $GRUPO: tela inicial ok"; rm -f "$DESFAZER";;
    4) registrar "GRUPO $GRUPO: tela bloqueou no meio; desbloqueie para conferir"; gerar_restaurar; exit 4;;
    *) registrar "GRUPO $GRUPO: TELA INICIAL NAO VOLTOU, desfazendo o grupo"
       if [ -f "$DESFAZER" ]; then
         sh "$DESFAZER" </dev/null
         grep -vxFf "$DESFAZER" "$ACOES" > "$ACOES.tmp"; mv "$ACOES.tmp" "$ACOES"
         sed -n 's/^pm install-existing --user 0 //p' "$DESFAZER" > "$DESFAZER.pk"
         grep -vxFf "$DESFAZER.pk" "$REM" > "$REM.tmp"; mv "$REM.tmp" "$REM"
         rm -f "$DESFAZER.pk"
       fi
       gerar_restaurar
       registrar "GRUPO $GRUPO: desfeito. Apps de terceiro desinstalados so voltam pela loja."
       exit 5;;
  esac
  GRUPO=""
}

remover() {
  barrado "$1" remover && return
  listado "$1" || { registrar "ja estava fora: $1"; return; }
  if [ "$SIMULAR" = "1" ]; then
    terceiro "$1" && registrar "SIMULACAO: desinstalaria $1 (terceiro)" || registrar "SIMULACAO: tentaria remover $1 (sistema); se recusado, desativaria"
    return
  fi
  if terceiro "$1"; then
    INST=$(pm list packages -i --user 0 "$1" | tr -d '\r' | grep -E "package:$1 " | sed 's/.*installer=//')
    for f in $(pm path "$1" | tr -d '\r' | cut -d: -f2); do
      registrar "SHA-256 de ${f##*/} de $1: $(sha256sum "$f" | cut -d' ' -f1)"
    done
    r=$(pm uninstall --user 0 "$1" | tr -d '\r' | tail -1)
    if listado "$1"; then registrar "NAO desinstalado $1 ($r)"; else
      echo "$1" >> "$REM"; registrar "desinstalado $1 ($r)"; volta "# $1: para voltar, reinstale pela loja ($INST)"
    fi
    return
  fi
  r=$(pm uninstall --user 0 "$1" | tr -d '\r' | tail -1)
  if ! listado "$1"; then
    echo "$1" >> "$REM"; registrar "removido $1 ($r)"; volta "pm install-existing --user 0 $1"
    echo "pm install-existing --user 0 $1" >> "$DESFAZER"
    return
  fi
  registrar "remocao recusada: $1 ($r); desativando"
  desativar "$1"
}

desativar() {
  barrado "$1" desativar && return
  listado "$1" || { registrar "ausente: $1"; return; }
  desativado "$1" && { registrar "ja estava desativado: $1"; return; }
  [ "$SIMULAR" = "1" ] && { registrar "SIMULACAO: desativaria $1"; return; }
  r=$(pm disable-user --user 0 "$1" | tr -d '\r' | tail -1)
  if desativado "$1"; then
    registrar "desativado $1"; volta "pm enable --user 0 $1"; echo "pm enable --user 0 $1" >> "$DESFAZER"
  else
    registrar "NAO desativado $1 ($r)"
  fi
}

restringir() {
  barrado "$1" restringir && return
  listado "$1" || { registrar "ausente: $1"; return; }
  cmd appops get --user 0 "$1" RUN_ANY_IN_BACKGROUND | grep -q ': ignore' && { registrar "ja estava restrito: $1"; return; }
  [ "$SIMULAR" = "1" ] && { registrar "SIMULACAO: restringiria o segundo plano de $1"; return; }
  cmd appops set --user 0 "$1" RUN_ANY_IN_BACKGROUND ignore
  if cmd appops get --user 0 "$1" RUN_ANY_IN_BACKGROUND | grep -q ': ignore'; then
    registrar "segundo plano restrito: $1"
    volta "cmd appops set --user 0 $1 RUN_ANY_IN_BACKGROUND default"
    echo "cmd appops set --user 0 $1 RUN_ANY_IN_BACKGROUND default" >> "$DESFAZER"
  else
    registrar "FALHOU restringir: $1"
  fi
}

revogar() {
  barrado "$1" revogar && return
  listado "$1" || { registrar "ausente: $1"; return; }
  concedida "$1" "$2" || { registrar "ja estava sem a permissao: $1 $2"; return; }
  [ "$SIMULAR" = "1" ] && { registrar "SIMULACAO: retiraria $2 de $1"; return; }
  pm revoke --user 0 "$1" "$2" >/dev/null 2>&1
  if concedida "$1" "$2"; then registrar "FALHOU retirar: $1 $2"; else
    registrar "permissao retirada: $1 $2"; volta "pm grant --user 0 $1 $2"; echo "pm grant --user 0 $1 $2" >> "$DESFAZER"
  fi
}

negar_instalar() {
  barrado "$1" negar-instalar && return
  listado "$1" || { registrar "ausente: $1"; return; }
  cmd appops get --user 0 "$1" REQUEST_INSTALL_PACKAGES | grep -q ': deny' && { registrar "ja nao podia instalar: $1"; return; }
  [ "$SIMULAR" = "1" ] && { registrar "SIMULACAO: negaria instalar apps a $1"; return; }
  cmd appops set --user 0 "$1" REQUEST_INSTALL_PACKAGES deny
  if cmd appops get --user 0 "$1" REQUEST_INSTALL_PACKAGES | grep -q ': deny'; then
    registrar "instalar apps negado: $1"
    volta "cmd appops set --user 0 $1 REQUEST_INSTALL_PACKAGES allow"
    echo "cmd appops set --user 0 $1 REQUEST_INSTALL_PACKAGES allow" >> "$DESFAZER"
  else
    registrar "FALHOU negar instalar: $1"
  fi
}

ajuste() {
  echo "$2" | grep -qE "$AJUSTES_PROIBIDOS" && { registrar "RECUSADO, ajuste protegido: $2"; return; }
  ANTES=$(settings get "$1" "$2" | tr -d '\r')
  [ "$ANTES" = "$3" ] && { registrar "ajuste ja estava certo: $2 = $3"; return; }
  [ "$SIMULAR" = "1" ] && { registrar "SIMULACAO: $2 de $ANTES para $3"; return; }
  settings put "$1" "$2" "$3"
  if [ "$(settings get "$1" "$2" | tr -d '\r')" = "$3" ]; then
    registrar "ajuste: $2 = $3 (era $ANTES)"
    if [ "$ANTES" = "null" ]; then V="settings delete $1 $2"; else V="settings put $1 $2 $ANTES"; fi
    volta "$V"; echo "$V" >> "$DESFAZER"
  else
    registrar "FALHOU ajuste: $2"
  fi
}

gerar_restaurar() {
  awk '!v[$0]++' "$ACOES" > "$ACOES.tmp" && mv "$ACOES.tmp" "$ACOES"
  {
    printf '@echo off\r\n'
    printf 'REM Desfaz as alteracoes registradas em alteracoes.txt.\r\n'
    printf 'set "ADB=%%~dp0..\\platform-tools\\adb.exe"\r\n'
    printf '"%%ADB%%" wait-for-device\r\n'
    while IFS= read -r l; do
      case "$l" in
        \#*) printf 'REM %s\r\n' "${l#\# }";;
        *) printf '"%%ADB%%" shell %s\r\n' "$l";;
      esac
    done < "$ACOES"
    printf 'echo Pronto. Reinicie o celular.\r\n'
    printf 'pause\r\n'
  } > "$SAIDA/restaurar.bat"
  {
    echo '#!/usr/bin/env bash'
    echo '# Desfaz as alteracoes registradas em alteracoes.txt.'
    echo 'export MSYS_NO_PATHCONV=1'
    echo 'D="$(cd "$(dirname "$0")/.." && pwd)/platform-tools"'
    echo 'ADB=adb; for a in "$D/adb" "$D/adb.exe"; do [ -x "$a" ] && ADB="$a"; done'
    echo '"$ADB" wait-for-device'
    while IFS= read -r l; do
      case "$l" in
        \#*) echo "$l";;
        *) echo "\"\$ADB\" shell $l";;
      esac
    done < "$ACOES"
    echo 'echo "Pronto. Reinicie o celular."'
  } > "$SAIDA/restaurar.sh"
}

if [ "$SIMULAR" = "0" ]; then
  largar 600
  tela_bloqueada && { echo "TELA BLOQUEADA: preciso que desbloqueie e deixe parado"; exit 4; }
fi

GRUPO=""
rm -f "$DESFAZER"
exec 3< "$PLANO.lf"
while read -r ACAO A1 A2 A3 <&3; do
  case "$ACAO" in
    ''|\#*|aparelho) ;;
    grupo) fechar_grupo; GRUPO=$(echo $A1 $A2 $A3); registrar "GRUPO $GRUPO: inicio";;
    remover) remover "$A1";;
    desativar) desativar "$A1";;
    restringir) restringir "$A1";;
    revogar) revogar "$A1" "$A2";;
    negar-instalar) negar_instalar "$A1";;
    ajuste) ajuste "$A1" "$A2" "$A3";;
    *) registrar "ACAO DESCONHECIDA ignorada: $ACAO";;
  esac
done
exec 3<&-
fechar_grupo
[ "$SIMULAR" = "0" ] && gerar_restaurar
rm -f "$DESFAZER"
registrar "fim da aplicacao$([ "$SIMULAR" = "1" ] && echo ' (simulacao)')"
