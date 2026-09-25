. "$PSScriptRoot\common.ps1"
# Kiem tra Python that (khong phai Windows Store stub)
$pyCmd = Get-Command 'python' -ErrorAction SilentlyContinue
if ($pyCmd -and $pyCmd.Source -notlike '*\WindowsApps\python*') {
    Write-Host '[OK] Python already installed.'; exit 0
}
Install-WingetPackage -PackageId 'Python.Python.3.13'
