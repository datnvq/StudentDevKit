. "$PSScriptRoot\common.ps1"
$root = Split-Path $PSScriptRoot -Parent
$config = Get-Config -Path (Join-Path $root 'config\components.json')

$compId = $env:STUDENTDEVKIT_CURRENT_COMP_ID
if (-not $compId) { $compId = 'python' }

$pkg = $config.wingetPackages.$compId
if (-not $pkg) { throw "Chua cau hinh winget package cho $compId" }

# Kiem tra Python that (khong phai Windows Store stub)
$pyCmd = Get-Command 'python' -ErrorAction SilentlyContinue
if ($pyCmd -and $pyCmd.Source -notlike '*\WindowsApps\python*') {
    Write-Host '[OK] Python already installed.'; exit 0
}
Install-WingetPackage -PackageId $pkg

