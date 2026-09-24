. "$PSScriptRoot\common.ps1"
if (Test-CommandExists 'node') { Write-Host '[OK] Node.js already installed.'; exit 0 }
Install-WingetPackage -PackageId 'OpenJS.NodeJS.LTS'
