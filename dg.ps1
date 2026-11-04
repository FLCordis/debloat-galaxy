# Atalho para Windows.
#   .\dg.ps1 preparar          baixa o ADB oficial, se preciso, e confere a assinatura
#   .\dg.ps1 esperar           espera o celular autorizar a depuracao USB
#   .\dg.ps1 rodar SCRIPT ...  envia os scripts, roda um deles e traz o resultado
#   .\dg.ps1 limpar            recupera resultados e apaga a pasta temporaria do celular
param(
  [Parameter(Position = 0)][string]$Comando,
  [Parameter(Position = 1, ValueFromRemainingArguments = $true)][string[]]$Resto
)
$Raiz = $PSScriptRoot
$Res = if ($env:DG_RESULTADOS) { $env:DG_RESULTADOS } else { Join-Path $Raiz 'resultados' }
$Adb = Join-Path $Raiz 'platform-tools\adb.exe'
$Dir = '/data/local/tmp/dg'

function Preparar {
  if (-not (Test-Path $Adb)) {
    $t = Join-Path $env:TEMP ('dg-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force $t | Out-Null
    $z = Join-Path $t 'pt.zip'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = 'SilentlyContinue'
    Write-Output 'Baixando o ADB oficial do Google...'
    Invoke-WebRequest -Uri 'https://dl.google.com/android/repository/platform-tools-latest-windows.zip' -OutFile $z -UseBasicParsing
    Expand-Archive -Path $z -DestinationPath $Raiz -Force
    Remove-Item -Recurse -Force $t
  }
  $s = Get-AuthenticodeSignature $Adb
  if ($s.Status -ne 'Valid' -or $s.SignerCertificate.Subject -notmatch 'Google') {
    Write-Output "ERRO: assinatura do adb.exe inesperada: $($s.Status)"
    exit 1
  }
  & $Adb version | Select-Object -First 2
  Write-Output 'assinatura do Google: valida'
}

function Esperar([int]$Limite = 600) {
  $t = 0; $reinicio = $false; $ult = ''
  while ($t -lt $Limite) {
    $linhas = @(& $Adb devices | Select-Object -Skip 1 | Where-Object { $_ -match '\S' })
    if ($linhas.Count -gt 1 -and -not $env:ANDROID_SERIAL) {
      Write-Output 'VARIOS APARELHOS: defina ANDROID_SERIAL'
      $linhas | ForEach-Object { Write-Output ('  ' + ($_ -split '\s+')[1]) }
      exit 2
    }
    $e = if ($linhas.Count) { ($linhas[0] -split '\s+')[1] } else { '' }
    if ($e -ne $ult) { Write-Output "estado: $(if ($e) { $e } else { 'sem aparelho' })"; $ult = $e }
    if ($e -eq 'device') { return }
    if ($e -eq 'unauthorized' -and -not $reinicio -and $t -ge 20) {
      & $Adb kill-server | Out-Null; & $Adb start-server | Out-Null; $reinicio = $true
    }
    Start-Sleep -Seconds 5; $t += 5
  }
  Write-Output "TEMPO ESGOTADO: estado final $(if ($e) { $e } else { 'sem aparelho' })"
  exit 3
}

function Rodar([string]$S, [string[]]$Args2) {
  if (-not (Test-Path (Join-Path $Raiz "scripts\$S.sh"))) { Write-Output "ERRO: script $S nao existe"; exit 2 }
  New-Item -ItemType Directory -Force $Res | Out-Null
  if (("" + (& $Adb shell "[ -d $Dir ] && echo sim")).Trim() -eq 'sim') {
    & $Adb pull "$Dir/saida/." "$Res/" 2>$null | Out-Null
    Write-Output 'OCUPADO: outra execucao esta rodando, ou a ultima foi interrompida. Espere terminar. Se nada estiver rodando, use: limpar'
    exit 6
  }
  & $Adb shell "mkdir -p $Dir/saida"
  & $Adb push (Join-Path $Raiz 'scripts\.') "$Dir/" | Out-Null
  if (Test-Path (Join-Path $Res 'plano.txt')) { & $Adb push (Join-Path $Res 'plano.txt') "$Dir/plano.txt" | Out-Null }
  foreach ($f in 'alteracoes.txt', 'removidos.txt', 'restaurar-acoes.txt') {
    if (Test-Path (Join-Path $Res $f)) { & $Adb push (Join-Path $Res $f) "$Dir/saida/$f" | Out-Null }
  }
  & $Adb shell sh "$Dir/$S.sh" @Args2
  $r = $LASTEXITCODE
  & $Adb pull "$Dir/saida/." "$Res/" | Out-Null
  & $Adb shell "rm -rf $Dir"
  exit $r
}

function Limpar {
  New-Item -ItemType Directory -Force $Res | Out-Null
  & $Adb pull "$Dir/saida/." "$Res/" 2>$null | Out-Null
  & $Adb shell "rm -rf $Dir"
  if ($LASTEXITCODE -ne 0) { Write-Output 'ERRO: celular nao encontrado; nada foi removido'; exit 1 }
  Write-Output 'pasta temporaria removida do celular; resultados recuperados, se havia'
}

switch ($Comando) {
  'preparar' { Preparar }
  'esperar' { if ($Resto) { Esperar ([int]$Resto[0]) } else { Esperar } }
  'rodar' { Rodar $Resto[0] @($Resto | Select-Object -Skip 1) }
  'limpar' { Limpar }
  default { Write-Output 'uso: .\dg.ps1 preparar | esperar [segundos] | rodar SCRIPT [argumentos] | limpar'; exit 2 }
}
