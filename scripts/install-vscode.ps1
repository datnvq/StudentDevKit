. "$PSScriptRoot\common.ps1"
if (Test-CommandExists 'code') { Write-Host '[OK] VS Code already installed.'; exit 0 }
Install-WingetPackage -PackageId 'Microsoft.VisualStudioCode'
