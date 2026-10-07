# Enables TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$url = 'https://codeload.github.com/fdcastel/PSDellCCTK/zip/master'
$fileName = Join-Path $env:TEMP 'PSDellCCTK-master.zip'
$folder = Join-Path $env:TEMP 'PSDellCCTK-master'

$ProgressPreference = 'SilentlyContinue'    # Faster downloads
Invoke-RestMethod $url -OutFile $fileName

Expand-Archive $fileName -DestinationPath $env:TEMP -Force
Remove-Item $fileName

Set-Location $folder
