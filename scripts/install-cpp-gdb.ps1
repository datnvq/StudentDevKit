# scripts/install-cpp-gdb.ps1
# Installs GDB debugger via MSYS2 UCRT64.
# Robust mirror fix: -Syy (force double-refresh) + -Suu (allow downgrade) + retry 3x.
# Compatible: PowerShell 5.1+

. $PSScriptRoot\common.ps1
. $PSScriptRoot\detect.ps1

$msys2Root = Get-Msys2Root
$ucrt64Bin = Join-Path $msys2Root 'ucrt64\bin'
$gdb       = Join-Path $ucrt64Bin 'gdb.exe'
$bash      = Join-Path $msys2Root 'usr\bin\bash.exe'

Write-Host [INFO] Using MSYS2 root: $msys2Root

# Already installed
if (Test-Path $gdb) {
    Add-MachinePath $ucrt64Bin
    Write-Host '[OK] GDB already installed.'
    exit 0
}

# Install MSYS2 if not present
if (-not (Test-Path $bash)) {
    Write-Host '[1/3] Installing MSYS2 via winget...'
    Install-WingetPackage -PackageId 'MSYS2.MSYS2'
    Update-SessionPath
    $msys2Root = Get-Msys2Root
    $ucrt64Bin = Join-Path $msys2Root 'ucrt64\bin'
    $gdb       = Join-Path $ucrt64Bin 'gdb.exe'
    $bash      = Join-Path $msys2Root 'usr\bin\bash.exe'
    if (-not (Test-Path $bash)) {
        throw MSYS2 bash not found at '$bash'. Please install MSYS2 manually from https://www.msys2.org/
    }
    Write-Host '[INFO] Initializing MSYS2 core...'
    & $bash -lc 'pacman -Syu --noconfirm 2>&1' | ForEach-Object { Write-Host  $_ }
} else {
    Write-Host '[1/3] MSYS2 already present.'
}

# Guard concurrent pacman
$pacmanRunning = Get-Process -Name 'pacman' -ErrorAction SilentlyContinue
if ($pacmanRunning) {
    throw 'pacman (MSYS2) dang chay. Cho no hoan tat roi thu lai.'
}

# Force-refresh package DB from upstream
Write-Host '[2/3] Syncing MSYS2 package database (force refresh)...'
& $bash -lc 'pacman -Syy --noconfirm 2>&1' | ForEach-Object { Write-Host  $_ }
if ($LASTEXITCODE -ne 0) {
    Write-Host [WARN] pacman -Syy exit $LASTEXITCODE - continuing anyway.
}

# Install GDB with retry
$maxRetries = 3
$installed  = $false

Write-Host '[3/3] Installing GDB (mingw-w64-ucrt-x86_64-gdb) with retry...'
for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
    if ($attempt -gt 1) {
        Write-Host [RETRY $attempt/$maxRetries] Waiting 8s then retrying...
        Start-Sleep -Seconds 8
        & $bash -lc 'pacman -Syy --noconfirm 2>&1' | ForEach-Object { Write-Host  $_ }
    }
    & $bash -lc 'pacman -Suu --needed --noconfirm --disable-download-timeout mingw-w64-ucrt-x86_64-gdb 2>&1' | ForEach-Object { Write-Host  $_ }
    if ($LASTEXITCODE -eq 0) { $installed = $true; break }
    Write-Host [WARN] Attempt $attempt failed (exit $LASTEXITCODE).
}

if (-not $installed) {
    Write-Host '[FALLBACK] Trying plain -Sy install...'
    & $bash -lc 'pacman -Sy --needed --noconfirm --disable-download-timeout mingw-w64-ucrt-x86_64-gdb 2>&1' | ForEach-Object { Write-Host  $_ }
    if ($LASTEXITCODE -ne 0) {
        throw GDB installation failed after $maxRetries retries. Kiem tra ket noi mang va thu lai sau.
    }
}

if (-not (Test-Path $gdb)) {
    throw gdb.exe not found at '$ucrt64Bin' after installation.
}

Add-MachinePath $ucrt64Bin
Write-Host [OK] GDB installed at: $ucrt64Bin
