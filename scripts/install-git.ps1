. "$PSScriptRoot\common.ps1"
if (Test-CommandExists 'git') { Write-Host '[OK] Git already installed.'; exit 0 }
Install-WingetPackage -PackageId 'Git.Git'
