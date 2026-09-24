# scripts/install-cpp-gcc.ps1
# Installs GCC + G++ for C/C++ via MSYS2 UCRT64.
# Auto-detects existing MSYS2 installation (does NOT hardcode C:\msys64).
# Compatible: PowerShell 5.1+

. "$PSScriptRoot\common.ps1"
. "$PSScriptRoot\detect.ps1"

$msys2Root = Get-Msys2Root
$ucrt64Bin = Join-Path $msys2Root 'ucrt64\bin'
$gcc  = Join-Path $ucrt64Bin 'gcc.exe'
$gxx  = Join-Path $ucrt64Bin 'g++.exe'
$bash = Join-Path $msys2Root 'usr\bin\bash.exe'

Write-Host "[INFO] Using MSYS2 root: $msys2Root"

# Already installed — just ensure PATH is set
if ((Test-Path $gcc) -and (Test-Path $gxx)) {
    Add-MachinePath $ucrt64Bin
    Write-Host '[OK] GCC + G++ already installed.'
    exit 0
}

# MSYS2 is not present — install it via winget
if (-not (Test-Path $bash)) {
    Write-Host '[1/4] Installing MSYS2 via winget...'
    Install-WingetPackage -PackageId 'MSYS2.MSYS2'
    Update-SessionPath

    # Re-probe MSYS2 root after install (winget may install to detected path)
    $msys2Root = Get-Msys2Root
    $ucrt64Bin = Join-Path $msys2Root 'ucrt64\bin'
    $gcc       = Join-Path $ucrt64Bin 'gcc.exe'
    $gxx       = Join-Path $ucrt64Bin 'g++.exe'
    $bash      = Join-Path $msys2Root 'usr\bin\bash.exe'
}

if (-not (Test-Path $bash)) {
    throw "MSYS2 bash not found at '$bash' after install. Please install MSYS2 manually from https://www.msys2.org/"
}

# pacman -Syu: first run exits non-zero to complete core update — this is expected
Write-Host '[2/4] Updating MSYS2 core (first run may exit early — this is normal)...'
& $bash -lc 'pacman -Syu --noconfirm' 2>&1 | Write-Host
if ($LASTEXITCODE -ne 0) {
    Write-Host "[INFO] First MSYS2 update returned exit code $LASTEXITCODE — continuing to package database refresh."
}

# Guard: do not run pacman concurrently
$pacmanRunning = Get-Process -Name 'pacman' -ErrorAction SilentlyContinue
if ($pacmanRunning) {
    throw 'pacman is already running. Wait for it to finish, then re-run the installer.'
}

Write-Host '[3/4] Refreshing MSYS2 package database...'
& $bash -lc 'pacman -Sy --noconfirm' 2>&1 | Write-Host
if ($LASTEXITCODE -ne 0) {
    throw "MSYS2 package database refresh failed (exit $LASTEXITCODE)."
}

Write-Host '[4/4] Installing GCC + G++ (mingw-w64-ucrt-x86_64-gcc)...'
& $bash -lc 'pacman -S --needed --noconfirm mingw-w64-ucrt-x86_64-gcc' 2>&1 | Write-Host
if ($LASTEXITCODE -ne 0) {
    throw "GCC/G++ installation failed (exit $LASTEXITCODE)."
}

if (-not (Test-Path $gcc) -or -not (Test-Path $gxx)) {
    throw "gcc.exe / g++.exe not found at '$ucrt64Bin' after installation."
}

Add-MachinePath $ucrt64Bin
Write-Host "[OK] GCC + G++ installed at: $ucrt64Bin"
