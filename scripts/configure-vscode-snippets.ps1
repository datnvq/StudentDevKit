# scripts/configure-vscode-snippets.ps1
$root = Split-Path $PSScriptRoot -Parent
$dir = Join-Path $env:APPDATA 'Code\User\snippets'
New-Item $dir -ItemType Directory -Force | Out-Null

$snippetFiles = Get-ChildItem -Path (Join-Path $root 'snippets') -Filter *.json
foreach ($file in $snippetFiles) {
    $destName = "studentdevkit-$($file.BaseName).code-snippets"
    Copy-Item $file.FullName (Join-Path $dir $destName) -Force
    Write-Host "[OK] $($file.BaseName) snippets installed."
}
Write-Host '[OK] VS Code snippets configured.'
