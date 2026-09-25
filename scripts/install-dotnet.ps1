# scripts/install-dotnet.ps1
# Cài đặt .NET SDK 8 qua winget

$root = Split-Path $PSScriptRoot -Parent
. (Join-Path $root 'scripts\common.ps1')

$config = Get-Config -Path (Join-Path $root 'config\components.json')
$pkg = $config.wingetPackages.csharp

if (-not $pkg) { throw "Chua cau hinh winget package cho csharp" }

Write-Host "  -> Dang tai va cai dat .NET SDK ($pkg) qua winget..."
Install-WingetPackage -Id $pkg -Name ".NET SDK 8"

Write-Host '[OK] Cai dat .NET SDK hoan tat.'
