# scripts/install-cpp-template.ps1
# Deploys the C++ starter template to the user's Documents folder.
# Detection: checks the DEPLOYED location, not the repo file.
# Safe to re-run: skips if already deployed. Does NOT delete user files.
# Compatible: PowerShell 5.1+

$root      = Split-Path $PSScriptRoot -Parent
$sourceDir = Join-Path $root 'templates\cpp'
$deployDir = Join-Path ([System.Environment]::GetFolderPath('MyDocuments')) 'StudentDevKit\cpp-template'
$targetMain = Join-Path $deployDir 'main.cpp'

# Already deployed — skip
if (Test-Path $targetMain) {
    Write-Host "[OK] C++ template already deployed at: $deployDir"
    exit 0
}

# Verify source exists
if (-not (Test-Path $sourceDir)) {
    throw "Source template directory not found: $sourceDir"
}

# Create deploy directory and copy files
New-Item $deployDir -ItemType Directory -Force | Out-Null
Get-ChildItem $sourceDir -Recurse | ForEach-Object {
    $relative = $_.FullName.Substring($sourceDir.Length).TrimStart('\')
    $dest = Join-Path $deployDir $relative
    if ($_.PSIsContainer) {
        New-Item $dest -ItemType Directory -Force | Out-Null
    } else {
        $destDir = Split-Path $dest -Parent
        if (-not (Test-Path $destDir)) { New-Item $destDir -ItemType Directory -Force | Out-Null }
        Copy-Item $_.FullName $dest -Force
    }
}

if (-not (Test-Path $targetMain)) {
    throw "Template deployment failed — main.cpp not found at '$targetMain'."
}

Write-Host "[OK] C++ template deployed to: $deployDir"
Write-Host "     Open this folder in VS Code and press Ctrl+Alt+N (Code Runner) to run."
