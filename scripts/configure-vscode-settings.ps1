# scripts/configure-vscode-settings.ps1
# Merges StudentDevKit VS Code settings into user's settings.json.
#
# Safe merge strategy:
#   - DevKit-owned keys (C_Cpp.*) are always written / updated.
#   - Suggested keys (editor.*, files.*) are written ONLY if the key
#     does not already exist in the user's settings — never overwrite.
#   - All other existing user settings are preserved.
#   - Creates settings.json if it doesn't exist yet.
# Compatible: PowerShell 5.1+

. "$PSScriptRoot\detect.ps1"   # For Get-Msys2Root, Get-DevKitOwnedSettingKeys

$root        = Split-Path $PSScriptRoot -Parent
$userDir     = Join-Path $env:APPDATA 'Code\User'
$targetFile  = Join-Path $userDir 'settings.json'
$sourceFile  = Join-Path $root 'vscode\settings.json'

if (-not (Test-Path $sourceFile)) {
    throw "Source settings file not found: $sourceFile"
}

# Ensure user Code\User directory exists
New-Item $userDir -ItemType Directory -Force | Out-Null

# Keys StudentDevKit owns — these are always overwritten
$ownedKeys = Get-DevKitOwnedSettingKeys

# Determine actual MSYS2 g++ path for the compiler setting
$msys2Root   = Get-Msys2Root
$compilerPath = Join-Path $msys2Root 'ucrt64\bin\g++.exe'

# Build the set of values StudentDevKit wants to apply
# Owned keys are always applied. Suggested keys are only defaults.
$devkitValues = [ordered]@{
    'C_Cpp.default.compilerPath' = $compilerPath
    'C_Cpp.default.cppStandard'  = 'c++17'
}

$suggestedValues = [ordered]@{
    'editor.formatOnSave' = $true
    'files.autoSave'      = 'afterDelay'
}

# Load or create existing settings
if (Test-Path $targetFile) {
    try {
        $existing = Get-Content $targetFile -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        Write-Host '[WARN] Existing settings.json could not be parsed. Creating backup and starting fresh.'
        $backup = "$targetFile.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
        Copy-Item $targetFile $backup -Force
        Write-Host "  Backup saved to: $backup"
        $existing = New-Object PSObject
    }
} else {
    $existing = New-Object PSObject
}

$changed = $false

# Apply DevKit-owned keys (always overwrite)
foreach ($key in $devkitValues.Keys) {
    $val = $devkitValues[$key]
    $prop = $existing.PSObject.Properties[$key]
    $currentVal = if ($prop) { $prop.Value } else { $null }
    if ($null -eq $currentVal -or "$currentVal" -ne "$val") {
        $existing | Add-Member -MemberType NoteProperty -Name $key -Value $val -Force
        $changed = $true
        Write-Host "  [SET] $key = $val"
    }
}

# Apply suggested keys (only if not present)
foreach ($key in $suggestedValues.Keys) {
    $val = $suggestedValues[$key]
    $currentProp = $existing.PSObject.Properties[$key]
    if ($null -eq $currentProp) {
        $existing | Add-Member -MemberType NoteProperty -Name $key -Value $val -Force
        $changed = $true
        Write-Host "  [DEFAULT] $key = $val (key was absent)"
    } else {
        Write-Host "  [KEPT] $key = $($currentProp.Value) (user value preserved)"
    }
}

if ($changed) {
    $existing | ConvertTo-Json -Depth 20 | Set-Content $targetFile -Encoding UTF8
    Write-Host "[OK] VS Code settings updated: $targetFile"
} else {
    Write-Host '[OK] VS Code settings already up to date. No changes made.'
}
