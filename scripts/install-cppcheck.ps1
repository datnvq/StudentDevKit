. "$PSScriptRoot\common.ps1"
if (Test-CommandExists 'cppcheck') { Write-Host '[OK] Cppcheck already installed.'; exit 0 }
Install-WingetPackage -PackageId 'Cppcheck.Cppcheck'
