. "$PSScriptRoot\common.ps1"
if (Test-CommandExists 'cmake') { Write-Host '[OK] CMake already installed.'; exit 0 }
Install-WingetPackage -PackageId 'Kitware.CMake'
