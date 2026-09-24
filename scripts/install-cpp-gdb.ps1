# scripts/install-cpp-gdb.ps1
# Installs GDB debugger via MSYS2 UCRT64.
# Auto-detects existing MSYS2 installation (does NOT hardcode C:\msys64).
# Compatible: PowerShell 5.1+

. "$PSScriptRoot\common.ps1"
. "$PSScriptRoot\detect.ps1"

$msys2Root = Get-Msys2Root
$ucrt64Bin = Join-Path $msys2Root 'ucrt64\bin'
$gdb       = Join-Path $ucrt64Bin 'gdb.exe'
$bash      = Join-Path $msys2Root 'usr\bin\bash.exe'

Write-Host "[INFO] Using MSYS2 root: $msys2Root"

# Already installed — just ensure PATH is set
if (Test-Path $gdb) {
    Add-MachinePath $ucrt64Bin
    Write-Host '[OK] GDB already installed.'
    exit 0
}

# MSYS2 is not present — install it via winget
if (-not (Test-Path $bash)) {
    Write-Host '[1/3] Installing MSYS2 via winget...'
    Install-WingetPackage -PackageId 'MSYS2.MSYS2'
    Update-SessionPath

    # Re-probe after install
    $msys2Root = Get-Msys2Root
    $ucrt64Bin = Join-Path $msys2Root 'ucrt64\bin'
    $gdb       = Join-Path $ucrt64Bin 'gdb.exe'
    $bash      = Join-Path $msys2Root 'usr\bin\bash.exe'
}

if (-not (Test-Path $bash)) {
    throw "MSYS2 bash not found at '$bash' after install. Please install MSYS2 manually from https://www.msys2.org/"
}

# Guard: do not run pacman concurrently
$pacmanRunning = Get-Process -Name 'pacman' -ErrorAction SilentlyContinue
if ($pacmanRunning) {
    throw 'pacman is already running. Wait for it to finish, then re-run the installer.'
}

Write-Host '[2/3] Refreshing MSYS2 package database...'
& $bash -lc 'pacman -Sy --noconfirm' 2>&1 | Write-Host
if ($LASTEXITCODE -ne 0) {
    throw "MSYS2 package database refresh failed (exit $LASTEXITCODE)."
}

Write-Host '[3/3] Installing GDB (mingw-w64-ucrt-x86_64-gdb)...'
& $bash -lc 'pacman -S --needed --noconfirm mingw-w64-ucrt-x86_64-gdb' 2>&1 | Write-Host
if ($LASTEXITCODE -ne 0) {
    throw "GDB installation failed (exit $LASTEXITCODE)."
}

if (-not (Test-Path $gdb)) {
    throw "gdb.exe not found at '$ucrt64Bin' after installation."
}

Add-MachinePath $ucrt64Bin
Write-Host "[OK] GDB installed at: $ucrt64Bin"
