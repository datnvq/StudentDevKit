$root = Split-Path $PSScriptRoot -Parent
$dir = Join-Path $env:APPDATA 'Code\User\snippets'
New-Item $dir -ItemType Directory -Force | Out-Null
Copy-Item (Join-Path $root 'snippets\cpp.json') (Join-Path $dir 'studentdevkit-cpp.code-snippets') -Force
Write-Host '[OK] C++ snippets installed.'
