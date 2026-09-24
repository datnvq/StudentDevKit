. "$PSScriptRoot\common.ps1"
if (Test-CommandExists 'python') { Write-Host '[OK] Python already installed.'; exit 0 }
Install-WingetPackage -PackageId 'Python.Python.3.13'
