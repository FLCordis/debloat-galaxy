# Mede RAM, armazenamento, apps, temperatura, CPU e abertura de Configuracoes.
# Uso: medir.sh ANTES ou medir.sh DEPOIS. Espera a pessoa largar o celular, sem interromper.
. "$(dirname "$0")/comum.sh"
ROTULO="${1:-MEDIDA}"
ARQ="$SAIDA/medidas-$ROTULO.txt"

# Nao abre tela enquanto a pessoa usa o aparelho.
largar 900
if tela_bloqueada; then echo "TELA BLOQUEADA: preciso que desbloqueie e deixe parado"; exit 4; fi

ABERTURAS="$DG_DIR/ab.tmp"
: > "$ABERTURAS"
for i in 1 2 3; do
  am force-stop com.android.settings
  sleep 2
  am start -W -n com.android.settings/.Settings | tr -d '\r' | grep -E 'LaunchState|TotalTime|Error' | tr '\n' ' ' >> "$ABERTURAS"
  echo >> "$ABERTURAS"
  sleep 3
done
input keyevent KEYCODE_HOME

# Agora a tela pode apagar: daqui em diante nada depende dela.
esperar_parado 120000 900
R=$?
[ "$R" = "1" ] && { echo "TEMPO ESGOTADO: nao ficou 2 minutos sem toque"; exit 3; }
if [ "$R" = "2" ]; then sleep 120; TOQUE="nao informado por este Android; esperei 2 minutos sem poder confirmar"; else TOQUE="$(ultimo_toque_ms) ms"; fi

{
  echo "===== $ROTULO: $(date '+%Y-%m-%d %H:%M:%S') ====="
  echo "sem toque ha: $TOQUE"
  echo "tempo ligado: $(awk '{printf "%.1f horas", $1/3600}' /proc/uptime)"
  grep -E 'MemTotal|MemAvailable|SwapTotal|SwapFree' /proc/meminfo
  dumpsys diskstats | grep -E '^Data-Free'
  echo "apps ativos: $(pm list packages -e --user 0 | wc -l)"
  dumpsys battery | tr -d '\r' | grep -E '^ *(level|temperature|USB powered|AC powered):' | sed 's/^ *//'
  dumpsys thermalservice | grep -E '^Thermal Status'
  echo "CPU, segunda amostra de 30 s:"
  top -b -n 2 -d 30 -m 8 -s 1 -o %CPU,%MEM,NAME > "$DG_DIR/top.tmp"
  L=$(grep -n 'Tasks:' "$DG_DIR/top.tmp" | tail -1 | cut -d: -f1)
  sed -n "$((L+3)),\$p" "$DG_DIR/top.tmp" | cut -c1-90
  echo "abertura de Configuracoes:"
  cat "$ABERTURAS"
} > "$ARQ"
rm -f "$ABERTURAS" "$DG_DIR/top.tmp"
cat "$ARQ"
