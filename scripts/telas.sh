# Abre uma tela de ajustes e le o texto dela, para a pessoa nao precisar procurar.
# Uso: telas.sh certificados | playprotect | anuncios | busca
# So le telas de ajustes, nunca tira imagem e guarda apenas o texto filtrado em tela-NOME.txt.
# Nao toca em nenhum botao.
. "$(dirname "$0")/comum.sh"
case "$1" in
  certificados) ACAO=com.android.settings.TRUSTED_CREDENTIALS_USER;;
  playprotect)  ACAO=com.google.android.gms.settings.VERIFY_APPS_SETTINGS;;
  anuncios)     ACAO=com.google.android.gms.settings.ADS_PRIVACY;;
  busca)        ACAO=android.settings.LOCATION_SCANNING_SETTINGS;;
  *) echo "uso: telas.sh certificados|playprotect|anuncios|busca"; exit 2;;
esac

largar 300
if tela_bloqueada; then echo "TELA BLOQUEADA: preciso que desbloqueie e deixe parado"; exit 4; fi

XML="$DG_DIR/tela.xml"
R=$(am start -W -a "$ACAO" 2>&1 | tr -d '\r' | grep -E '^Status|Error' | head -1)
case "$R" in
  *ok*) ;;
  *) echo "INDISPONIVEL: esta tela nao abriu neste aparelho (${R:-sem resposta})"; exit 1;;
esac
sleep 3
# Se a pessoa tiver aberto outro app nesse meio tempo, nao le: poderia ser uma conversa.
case "$(foco)" in
  *settings*|*com.google.android.gms*) ;;
  *) echo "SEM LEITURA: outra tela esta aberta. Pergunte a pessoa o que aparece."; exit 1;;
esac
uiautomator dump "$XML" >/dev/null 2>&1
case "$(foco)" in
  *settings*|*com.google.android.gms*) ;;
  *) rm -f "$XML"; echo "SEM LEITURA: a tela mudou durante a leitura."; exit 1;;
esac
if [ ! -s "$XML" ]; then
  echo "SEM LEITURA: a tela abriu, mas nao deu para ler. Pergunte a pessoa o que aparece."
  exit 1
fi
{
  echo "===== Tela $1: $(date '+%Y-%m-%d %H:%M:%S') ====="
  tr '>' '\n' < "$XML" | grep -oE ' (text|content-desc)="[^"]+"' | sed -E 's/^ (text|content-desc)="//; s/"$//; s/&#10;/ /g; s/00000000-0000-0000-0000-000000000000/<id-zerado>/g' | higienizar | awk 'NF && !v[$0]++' | cut -c1-120 | head -30
} | tee "$SAIDA/tela-$1.txt"
rm -f "$XML"
