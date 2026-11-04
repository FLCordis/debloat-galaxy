#!/usr/bin/env bash
# Atalho para macOS, Linux e Git Bash.
#   ./dg.sh preparar          baixa o ADB oficial, se preciso
#   ./dg.sh esperar           espera o celular autorizar a depuracao USB
#   ./dg.sh rodar SCRIPT ...  envia os scripts, roda um deles e traz o resultado
#   ./dg.sh limpar            recupera resultados e apaga a pasta temporaria do celular
set -u
export MSYS_NO_PATHCONV=1
# No Git Bash, o adb.exe precisa de caminho do Windows.
RAIZ="$(cd "$(dirname "$0")" && { pwd -W 2>/dev/null || pwd; })"
RES="${DG_RESULTADOS:-$RAIZ/resultados}"
PT="$RAIZ/platform-tools"
DIR=/data/local/tmp/dg
ADB="$PT/adb"
case "$(uname -s)" in
  Darwin) ALVO=darwin;;
  Linux) ALVO=linux;;
  *) ALVO=windows; ADB="$PT/adb.exe";;
esac

preparar() {
  [ -x "$ADB" ] && { "$ADB" version | head -2; return 0; }
  command -v curl >/dev/null && command -v unzip >/dev/null || { echo "ERRO: preciso de curl e unzip"; return 1; }
  T="$(mktemp -d)"
  echo "Baixando o ADB oficial do Google..."
  curl -fsSL -o "$T/pt.zip" "https://dl.google.com/android/repository/platform-tools-latest-$ALVO.zip" || return 1
  unzip -q "$T/pt.zip" -d "$RAIZ" || return 1
  rm -rf "$T"
  "$ADB" version | head -2
}

esperar() {
  LIMITE="${1:-600}"; t=0; reinicio=0; ult=""
  while [ "$t" -lt "$LIMITE" ]; do
    L="$("$ADB" devices | tr -d '\r' | sed -n '2,$p' | grep -v '^$' || true)"
    n="$(printf '%s' "$L" | grep -c . || true)"
    if [ "$n" -gt 1 ] && [ -z "${ANDROID_SERIAL:-}" ]; then
      echo "VARIOS APARELHOS: defina ANDROID_SERIAL"; printf '%s\n' "$L" | awk '{print "  " $2}'; return 2
    fi
    E="$(printf '%s' "$L" | awk '{print $2}' | head -1)"
    [ "$E" != "$ult" ] && { echo "estado: ${E:-sem aparelho}"; ult="$E"; }
    [ "$E" = "device" ] && return 0
    if [ "$E" = "unauthorized" ] && [ "$reinicio" = 0 ] && [ "$t" -ge 20 ]; then
      "$ADB" kill-server >/dev/null 2>&1; "$ADB" start-server >/dev/null 2>&1; reinicio=1
    fi
    sleep 5; t=$((t+5))
  done
  echo "TEMPO ESGOTADO: estado final ${E:-sem aparelho}"; return 3
}

rodar() {
  S="$1"; shift
  [ -f "$RAIZ/scripts/$S.sh" ] || { echo "ERRO: script $S nao existe"; return 2; }
  mkdir -p "$RES"
  if [ "$("$ADB" shell "[ -d $DIR ] && echo sim" | tr -d '\r')" = "sim" ]; then
    "$ADB" pull "$DIR/saida/." "$RES/" >/dev/null 2>&1
    echo "OCUPADO: outra execucao esta rodando, ou a ultima foi interrompida. Espere terminar. Se nada estiver rodando, use: limpar"
    return 6
  fi
  "$ADB" shell "mkdir -p $DIR/saida" || return 1
  "$ADB" push "$RAIZ/scripts/." "$DIR/" >/dev/null || return 1
  [ -f "$RES/plano.txt" ] && "$ADB" push "$RES/plano.txt" "$DIR/plano.txt" >/dev/null
  for f in alteracoes.txt removidos.txt restaurar-acoes.txt; do
    [ -f "$RES/$f" ] && "$ADB" push "$RES/$f" "$DIR/saida/$f" >/dev/null
  done
  "$ADB" shell sh "$DIR/$S.sh" "$@"
  R=$?
  "$ADB" pull "$DIR/saida/." "$RES/" >/dev/null
  "$ADB" shell "rm -rf $DIR"
  return $R
}

limpar() {
  mkdir -p "$RES"
  "$ADB" pull "$DIR/saida/." "$RES/" >/dev/null 2>&1
  "$ADB" shell "rm -rf $DIR" || { echo "ERRO: celular nao encontrado; nada foi removido"; return 1; }
  echo "pasta temporaria removida do celular; resultados recuperados, se havia"
}

case "${1:-}" in
  preparar) preparar;;
  esperar) shift; esperar "$@";;
  rodar) shift; rodar "$@";;
  limpar) limpar;;
  *) echo "uso: dg.sh preparar | esperar [segundos] | rodar SCRIPT [argumentos] | limpar"; exit 2;;
esac
