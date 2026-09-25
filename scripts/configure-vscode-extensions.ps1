. "$PSScriptRoot\common.ps1"
$root = Split-Path $PSScriptRoot -Parent
. "$root\scripts\detect.ps1"
$cfg = Get-Config -Path "$root\config\components.json"

# Tìm lệnh code (code có thể không nằm trong PATH ngay sau cài)
$codeCmd = Get-Command 'code' -ErrorAction SilentlyContinue
if (-not $codeCmd) {
    $codePaths = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'),
        (Join-Path $env:ProgramFiles 'Microsoft VS Code\bin\code.cmd')
    )
    foreach ($p in $codePaths) {
        if ($p -and (Test-Path $p)) { $codeCmd = $p; break }
    }
}
if (-not $codeCmd) { throw 'VS Code chua duoc cai dat hoac chua nhan PATH. Cai VS Code truoc.' }

$codeExe = if ($codeCmd -is [string]) { $codeCmd } else { $codeCmd.Source }

# Collect extensions to install
$extensionsToInstall = [System.Collections.Generic.List[string]]::new()

# Global extensions
if ($cfg.vscodeExtensions) {
    foreach ($ext in $cfg.vscodeExtensions) {
        if (-not $extensionsToInstall.Contains($ext)) {
            [void]$extensionsToInstall.Add($ext)
        }
    }
}

# Component-specific extensions (only if component is installed)
foreach ($comp in $cfg.components) {
    if ($comp.vscodeExtensions) {
        if (Test-ComponentInstalled -Id $comp.id) {
            foreach ($ext in $comp.vscodeExtensions) {
                if (-not $extensionsToInstall.Contains($ext)) {
                    [void]$extensionsToInstall.Add($ext)
                }
            }
        }
    }
}

foreach ($ext in $extensionsToInstall) {
    Write-Host "  -> code --install-extension $ext"
    & $codeExe --install-extension $ext --force
    if ($LASTEXITCODE -ne 0) { Write-Host "[WARNING] VS Code extension install failed: $ext" -ForegroundColor Yellow }
}
Write-Host '[OK] VS Code extensions configured.'
