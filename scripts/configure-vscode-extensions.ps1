. "$PSScriptRoot\common.ps1"
$root = Split-Path $PSScriptRoot -Parent
$cfg = Get-Config -Path "$root\config\components.json"
if (-not (Test-CommandExists 'code')) { throw 'Install VS Code first.' }
foreach ($ext in @($cfg.vscodeExtensions)) {
    Write-Host "  -> code --install-extension $ext"
    & code --install-extension $ext --force
    if ($LASTEXITCODE -ne 0) { throw "VS Code extension install failed: $ext" }
}
Write-Host '[OK] VS Code extensions configured.'
