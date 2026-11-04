# Guia passo a passo

Este guia é para quem nunca usou ADB nem um agente de IA no terminal. Reserve cerca de **40 minutos**, com o celular perto, e faça o backup antes.

## Antes de começar

**O que você vai precisar**

- Um computador com Windows, macOS ou Linux.
- Um cabo USB **de dados**. Alguns cabos só carregam.
- Um agente de IA que rode comandos no terminal. Este guia usa o Claude Code.
- Fotos e conversas com backup em dia.

**Instalar o Claude Code e o Git**

1. Siga o [guia oficial do Claude Code](https://docs.claude.com/en/docs/claude-code/overview).
2. Instale o [Git](https://git-scm.com/downloads). Se preferir não instalar, baixe este projeto pelo botão **Code > Download ZIP** no GitHub e extraia.

## Passo 1: abrir o projeto

Abra o terminal e rode:

```bash
git clone https://github.com/FLCordis/debloat-galaxy.git
cd debloat-galaxy
claude
```

Escreva `começar`. A IA vai avisar o que passa por ela e abrir o primeiro quiz.

## Passo 2: responder ao quiz

Você escolhe opções em vez de digitar. As perguntas são sobre o que te incomoda, desde quando, o que mudou nessa época e quanto ela pode mexer.

| Opção | O que significa |
|---|---|
| **Equilibrado** | Tira o que é seguro e sem uso. É a recomendada. |
| **Cauteloso** | Só privacidade e telemetria. |
| **Só diagnóstico** | Só o relatório, sem nenhuma mudança. |

## Passo 3: ligar a depuração USB

No celular:

1. Abra **Configurações > Sobre o telefone > Informações do software**.
2. Toque **7 vezes** em **Número de compilação** até aparecer que o modo desenvolvedor foi ativado.
3. Volte a **Configurações** e abra **Opções do desenvolvedor**, que fica no fim da lista.
4. Ligue **Depuração USB**.
5. Conecte o cabo com a tela desbloqueada.
6. Na janela **Permitir depuração USB?**, marque **Sempre permitir deste computador** e toque em **Permitir**.

Não precisa avisar a IA: ela fica esperando e segue sozinha. O caminho muda um pouco de uma marca para outra, então ela adapta depois de saber o modelo.

## Passo 4: varredura

A IA descobre sozinha o que dá: contas, chip, recursos, bancos e 2FA. Depois faz um quiz curto só com o que falta, como quais recursos você usa e se falta proteger algum app.

A varredura só lê dados e leva cerca de 1 minuto. Algumas telas de ajustes podem abrir sozinhas no celular para ela ler o que aparece. Nada é alterado.

## Passo 5: ler o relatório e aprovar

Você recebe os achados por gravidade, as causas prováveis de cada sintoma e o que não deu para ver. Depois vem o plano, por grupos, com o risco e como voltar de cada item.

Para cada grupo, escolha **Aprovar**, **Revisar item por item** ou **Não aplicar**. Na dúvida, não aplique: nenhum item é obrigatório.

## Passo 6: aplicar

Deixe o celular **parado, desbloqueado e no cabo**. A IA:

1. Pergunta sobre o backup.
2. Mede como o aparelho está agora.
3. Simula o plano e depois aplica, conferindo a tela inicial a cada grupo.
4. Reinicia o celular. Quando ligar, **desbloqueie com o PIN** e deixe parado.

Se você estiver usando o celular, ela espera você largar. Se a tela bloquear, ela pede para desbloquear.

## Passo 7: testar

A IA testa internet, DNS, teclado e a abertura de Câmera, Galeria, Telefone e Mensagens, sem fotografar, ligar ou ler nada. Depois confere se cada mudança continua valendo.

Você só marca o que falhou entre o que depende de uma pessoa: ligação, SMS, foto, compartilhamento, Bluetooth, Modos e Rotinas, Carteira, bancos e 2FA.

## Passo 8: teste da noite

Se a bateria é o seu problema, é este teste que dá a resposta:

1. Carregue até parar sozinho, em 100% ou no limite da proteção de bateria. Assim, a medida de amanhã não se mistura com a de antes da limpeza.
2. Antes de dormir, tire da tomada e não use.
3. De manhã, conecte o cabo **antes de carregar** e abra a conversa com a IA de novo.

Não precisa anotar nada. O celular guarda o histórico, e a IA calcula quanto gastou por hora.

## Passo 9: terminar

Quando estiver tudo certo, desligue **Configurações > Opções do desenvolvedor > Depuração USB**. Os arquivos ficam na pasta `resultados/`, e o `resumo.txt` é o que vale a pena ler.

**Não publique a pasta `resultados/`:** ela tem identificadores do seu aparelho.

## Como desfazer

Conecte o celular e dê dois cliques em `resultados\restaurar.bat`, no Windows, ou rode `bash resultados/restaurar.sh`, no macOS e no Linux. Depois, reinicie o celular.

Apps de loja desinstalados voltam pela própria loja. Para desfazer um item só, peça para a IA.

Se você quiser religar a varredura de Wi-Fi e Bluetooth pela tela, abra **Configurações > Localização > Serviços de localização**.

## Problemas comuns

| O que acontece | O que fazer |
|---|---|
| O celular não aparece | Confira se **Depuração USB** continua ligada, mesmo que já tenha ligado antes. Depois, troque o cabo, escolha **Transferência de arquivos** na notificação de USB e instale o driver USB do fabricante. |
| Aparece "não autorizado" | Desbloqueie e procure a janela **Permitir depuração USB?**. Se não vier, toque em **Revogar autorizações de depuração USB** nas Opções do desenvolvedor e reconecte. |
| Continua não autorizado (Samsung) | Veja se o **Bloqueador automático** está ligado em **Segurança e privacidade**. Ele pode bloquear comandos pelo cabo. A decisão de desligar é sua; religue no final. |
| `only root can delete system app` | É o esperado no Android 17 ou mais novo. A IA desativa o app no lugar. |
| Algum app parou de funcionar | Rode o `restaurar` ou peça para a IA desfazer o último grupo. |
| Um app desativado voltou | Foi uma atualização do sistema. Rode o processo de novo. |
| Mensagens de "Permission denied" | Sem root, algumas áreas não abrem. A IA anota como indisponível e segue. |

## Perguntas frequentes

**Isso tira o vírus do meu celular?**
Não é um antivírus. Se aparecer algo confirmado, o relatório traz o plano B: trocar senhas a partir de outro aparelho, revisar acessos e fazer o reset de fábrica você mesmo.

**Posso perder dados?**
Nenhum arquivo pessoal é apagado sem confirmação específica. Um app desinstalado perde os dados dele, por isso o backup vem antes.

**Vai perder a garantia?**
O processo não usa root nem desbloqueia o bootloader, e o Knox continua intacto.

**Vou ganhar muita bateria?**
Depende do que estiver gastando. Remover apps de fábrica costuma mudar pouco. O relatório mostra quanto cada um gastava, então você decide sabendo disso.

**O que a IA vê do meu celular?**
Lista de apps, permissões, tipos de conta, consumo e ajustes. Ela não lê mensagens, fotos, contatos ou senhas. Esses dados passam pelo provedor da IA que você escolheu.

**Funciona em outro Android?**
O roteiro serve para qualquer Android, mas foi testado em Samsung. O que não existir no seu aparelho é marcado como indisponível.
