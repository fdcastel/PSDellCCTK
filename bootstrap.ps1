# Enables TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$url = 'https://codeload.github.com/fdcastel/PSDellCCTK/zip/master'
$fileName = Join-Path $env:TEMP 'PSDellCCTK-master.zip'

$ProgressPreference = 'SilentlyContinue'    # Faster downloads
Invoke-RestMethod $url -OutFile $fileName
Expand-Archive $fileName -DestinationPath $env:TEMP -Force

Set-Location "$env:TEMP\PSDellCCTK-master"

Remove-Item './Rebuild-Options.ps1' > $null
attrib +R './get-options.txt'
attrib +R './set-options.txt'
