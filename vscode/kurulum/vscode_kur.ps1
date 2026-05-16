$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$src = Join-Path $root "uxm-dil-destegi-v11"
$dest = Join-Path $env:USERPROFILE ".vscode\extensions\uxm-dil-destegi-v11"
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null
Copy-Item $src $dest -Recurse -Force
Write-Host "UXM VSCode eklentisi kuruldu / extension installed: $dest"
