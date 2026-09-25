. "$PSScriptRoot\common.ps1"
$root = Split-Path $PSScriptRoot -Parent
$config = Get-Config -Path (Join-Path $root 'config\components.json')

$compId = $env:STUDENTDEVKIT_CURRENT_COMP_ID
if (-not $compId) { $compId = 'node' }

$pkg = $config.wingetPackages.$compId
if (-not $pkg) { throw "Chua cau hinh winget package cho $compId" }

if (Test-CommandExists 'node') { Write-Host '[OK] Node.js already installed.'; exit 0 }
Install-WingetPackage -PackageId $pkg
