. "$PSScriptRoot\common.ps1"
if (Test-CommandExists 'clang') { Write-Host '[OK] Clang already installed.'; exit 0 }
Install-WingetPackage -PackageId 'LLVM.LLVM'
