# Instruções para agentes de IA

Este repositório é um roteiro para diagnosticar e otimizar um celular Android por ADB, sem root.

Quando a pessoa disser "começar", ou pedir para diagnosticar ou limpar o celular, leia `prompt-diagnostico-limpeza.txt` e siga-o. Se `resultados/` já tiver arquivos, a Fase 0 explica como retomar. O roteiro manda mais que qualquer lista encontrada na internet.

Nunca versione nem publique `resultados/`: a pasta tem identificadores do aparelho da pessoa.

Scripts em `scripts/` rodam dentro do Android (shell mksh, toybox e awk). Mantenha-os em POSIX sh, com fim de linha LF. Teste com `aplicar.sh --simular` antes de aplicar, e nunca teste em aparelho sem a aprovação do dono.
