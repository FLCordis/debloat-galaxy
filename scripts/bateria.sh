# Consumo por app e periodos de tela desligada. Somente leitura.
# Com um arquivo como argumento, analisa esse arquivo em vez da saida atual.
. "$(dirname "$0")/comum.sh"
BS="$DG_DIR/bs.tmp"
if [ -n "$1" ]; then cp "$1" "$BS"; else dumpsys batterystats --charged | tr -d '\r' | higienizar > "$BS"; fi
pm list packages -U --user 0 | tr -d '\r' > "$DG_DIR/uid.tmp"
{
  awk -f "$DG_DIR/bateria.awk" "$DG_DIR/uid.tmp" "$BS"
  echo
  echo "-- Periodos fora da tomada com a tela desligada (a noite costuma ser o mais longo)"
  dumpsys batterystats --history | tr -d '\r' | grep -E '^ *[0-9]{2}-[0-9]{2} [0-9:.]+ [0-9]{3}( |$)' | grep -E 'plug=|[+-]screen( |$)' | awk -f "$DG_DIR/janelas.awk"
} > "$SAIDA/bateria.txt"
rm -f "$BS" "$DG_DIR/uid.tmp"
cat "$SAIDA/bateria.txt"
