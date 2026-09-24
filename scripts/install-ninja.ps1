. "$PSScriptRoot\common.ps1"
if (Test-CommandExists 'ninja') { Write-Host '[OK] Ninja already installed.'; exit 0 }
Install-WingetPackage -PackageId 'Ninja-build.Ninja'
