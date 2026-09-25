# scripts/install-java.ps1
# Cài đặt OpenJDK 21 qua winget

$root = Split-Path $PSScriptRoot -Parent
. (Join-Path $root 'scripts\common.ps1')

$config = Get-Config -Path (Join-Path $root 'config\components.json')
$pkg = $config.wingetPackages.java

if (-not $pkg) { throw "Chua cau hinh winget package cho java" }

Write-Host "  -> Dang tai va cai dat Java ($pkg) qua winget..."
Install-WingetPackage -Id $pkg -Name "Java JDK 21"

Write-Host '[OK] Cai dat Java hoan tat.'
