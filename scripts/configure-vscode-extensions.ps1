. "$PSScriptRoot\common.ps1"
$root = Split-Path $PSScriptRoot -Parent
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

foreach ($ext in @($cfg.vscodeExtensions)) {
    Write-Host "  -> code --install-extension $ext"
    & $codeExe --install-extension $ext --force
    if ($LASTEXITCODE -ne 0) { throw "VS Code extension install failed: $ext" }
}
Write-Host '[OK] VS Code extensions configured.'
