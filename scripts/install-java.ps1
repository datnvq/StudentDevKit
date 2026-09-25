# scripts/install-java.ps1
# Cài đặt OpenJDK qua winget (Hỗ trợ chọn phiên bản)

$root = Split-Path $PSScriptRoot -Parent
. (Join-Path $root 'scripts\common.ps1')

$compId = $env:STUDENTDEVKIT_CURRENT_COMP_ID
if (-not $compId) { $compId = 'java' }

$config = Get-Config -Path (Join-Path $root 'config\components.json')
$pkg = $config.wingetPackages.$compId

if (-not $pkg) { throw "Chua cau hinh winget package cho $compId" }

Write-Host "  -> Dang tai va cai dat Java ($pkg) qua winget..."
Install-WingetPackage -PackageId $pkg

Write-Host '[OK] Cai dat Java hoan tat.'
