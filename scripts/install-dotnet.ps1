# scripts/install-dotnet.ps1
# Cài đặt .NET SDK qua winget (Hỗ trợ chọn phiên bản)

$root = Split-Path $PSScriptRoot -Parent
. (Join-Path $root 'scripts\common.ps1')

$compId = $env:STUDENTDEVKIT_CURRENT_COMP_ID
if (-not $compId) { $compId = 'csharp' }

$config = Get-Config -Path (Join-Path $root 'config\components.json')
$pkg = $config.wingetPackages.$compId

if (-not $pkg) { throw "Chua cau hinh winget package cho $compId" }

Write-Host "  -> Dang tai va cai dat .NET SDK ($pkg) qua winget..."
Install-WingetPackage -PackageId $pkg

Write-Host '[OK] Cai dat .NET SDK hoan tat.'
