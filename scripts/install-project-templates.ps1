# scripts/install-project-templates.ps1
# Deploys starter templates to the user's Documents folder.
# Safe to re-run: skips existing files but copies missing ones. Does NOT delete user files.
# Compatible: PowerShell 5.1+

$root      = Split-Path $PSScriptRoot -Parent
$sourceBase = Join-Path $root 'templates'
$deployBase = Join-Path ([System.Environment]::GetFolderPath('MyDocuments')) 'StudentDevKit'

# Verify source exists
if (-not (Test-Path $sourceBase)) {
    throw "Source templates directory not found: $sourceBase"
}

$templateDirs = Get-ChildItem -Path $sourceBase -Directory
foreach ($dir in $templateDirs) {
    $lang = $dir.Name
    $sourceDir = $dir.FullName
    $deployDir = Join-Path $deployBase "$lang-template"
    
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
            # Only copy if destination file does not exist, to avoid overwriting user's work
            if (-not (Test-Path $dest)) {
                Copy-Item $_.FullName $dest -Force
            }
        }
    }
    Write-Host "[OK] $lang template deployed to: $deployDir"
}

Write-Host "     Open these folders in VS Code to start coding."
