# Referência Samsung

Ponto de partida, não lista pronta. Confira cada pacote no aparelho e na vida de quem o usa antes de propor qualquer coisa. Todos estes aparelhos eram da região Brasil, com chip, conta Google e conta Samsung.

## Galaxy S25+ (SM-S936B), Android 17, One UI 9.0, novembro de 2026

A remoção de app de sistema foi recusada, então eles foram desativados.

**Desativados:**

| Pacote | Função |
|---|---|
| `com.facebook.appmanager` | Gerenciador de apps da Meta. Baixou 777 MB em 9 horas nesse aparelho. |
| `com.facebook.services` | Serviços de fábrica da Meta |
| `com.facebook.system` | Instalador de fábrica da Meta |
| `com.samsung.android.dqagent` | Telemetria de qualidade |
| `com.sec.android.diagmonagent` | Telemetria de diagnóstico |
| `com.samsung.android.ipsgeofence` | Geofence de marketing (Visit In) |
| `com.samsung.android.rubin.app` | Serviço de personalização. Teste Modos e Rotinas depois. |
| `com.samsung.accessory.budsunitemgr` | Gerenciador dos fones, sem uso nesse aparelho |
| `com.samsung.android.kidsinstaller` | Samsung Kids, sem uso |
| `com.samsung.android.app.parentalcare` | Controle parental, sem uso |

**Desinstalados, porque aparecem como apps de loja:**

| Pacote | Função |
|---|---|
| `com.samsung.android.gearrplugin` | Plugin do relógio, sem uso nesse aparelho |
| `com.samsung.android.app.watchmanager` | Galaxy Wearable, sem uso |
| `com.samsung.accessory` | Serviço de acessórios, sem uso |
| `com.samsung.accessory.atticmgr` | Gerenciador dos fones, sem uso |
| `com.sec.android.app.kidshome` | Samsung Kids, sem uso |

**Mantidos porque a pessoa usava:** Link to Windows, Smart View, Clima, Android Auto, Modos e Rotinas, Carteira.

**O que mais ajudou a entender a bateria:**

- O app com maior consumo foi o WhatsApp, com uma tarefa de conexão rodando 407 vezes em 9 horas.
- Os pacotes de fábrica que deu para medir gastaram quase nada: cerca de 7 de 2.391 mAh. Dois deles estão no UID do sistema e não dá para separar. O ganho foi em privacidade e dados.
- Um pacote sem marca no nome, `com.nvt.cs`, era o app de uma operadora. O `identificar.sh` descobre isso pelas classes internas, sem internet.

## Galaxy S22 (SM-S901E), Android 16, One UI 8.0, outubro de 2026

`pm uninstall --user 0` ainda funcionava nesta versão.

**Removidos:**
`com.facebook.appmanager` `com.facebook.services` `com.facebook.system` `com.samsung.android.rubin.app` `com.samsung.android.dqagent` `com.sec.android.diagmonagent` `com.samsung.android.ipsgeofence` `com.samsung.android.app.spage` `com.microsoft.appmanager` `com.samsung.android.app.taskedge` `com.samsung.android.app.clipboardedge` `com.sec.android.autodoodle.service` `com.samsung.android.stickercenter` `com.samsung.storyservice` `com.samsung.android.dynamiclock` `com.samsung.android.widget.pictureframe` `com.samsung.android.smartswitchassistant` `com.sec.android.easyMover.Agent` `com.samsung.android.kidsinstaller` `com.samsung.android.app.parentalcare` `com.samsung.SMT.lang_es_mx_f00` `com.samsung.SMT.lang_en_us_l03` `com.samsung.android.smartmirroring` `com.samsung.android.allshare.service.mediashare` `com.samsung.android.mdx.kit` `com.sec.android.daemonapp`

**Mantidos de propósito:**
`com.samsung.android.messaging` `com.samsung.android.scloud` `com.samsung.android.mobileservice` `com.samsung.android.scs` `com.samsung.android.bbc.bbcagent` `com.samsung.android.knox.analytics.uploader` `com.samsung.android.knox.app.networkfilter` `com.samsung.android.knox.attestation` `com.samsung.android.app.sharelive` `com.samsung.android.aware.service` `com.samsung.android.beaconmanager` `com.samsung.android.mapsagent` `com.samsung.android.forest` `com.samsung.android.app.routines` `com.sec.android.mimage.photoretouching` `com.samsung.android.themecenter` `com.samsung.android.app.dressroom` `com.samsung.android.game.gos` `com.sec.android.smartfpsadjuster`

**Ausentes no One UI 8:**
`com.samsung.android.app.settings.bixby` `com.samsung.android.app.appsedge` `com.samsung.android.app.cocktailbarservice` `com.samsung.android.galaxycontinuity` `com.samsung.android.mdx.quickboard` `com.sec.android.app.DataCreate` `com.applovin.array.apphub.samsung`

## O que nunca remover

A lista de proteção do `scripts/comum.sh` recusa estes mesmo que o plano peça: Knox, Knox Guard, Samsung Pass, Encontre Meu Celular, Carteira, Play Services, Play Store, telefone, mensagens, teclado, tela inicial, câmera, galeria e atualizações de segurança.
