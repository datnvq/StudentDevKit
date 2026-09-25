# scripts/install-cpp-gcc.ps1
# Installs GCC + G++ for C/C++ via MSYS2 UCRT64.
# Auto-detects existing MSYS2 installation (does NOT hardcode C:\msys64).
# Robust mirror fix: -Syy (force double-refresh DB) + -Suu (allow downgrade)
# + retry 3x to avoid 404 when mirror has not synced the newest package yet.
# Compatible: PowerShell 5.1+

. $PSScriptRoot\common.ps1
. $PSScriptRoot\detect.ps1

$msys2Root = Get-Msys2Root
$ucrt64Bin = Join-Path $msys2Root 'ucrt64\bin'
$gcc  = Join-Path $ucrt64Bin 'gcc.exe'
$gxx  = Join-Path $ucrt64Bin 'g++.exe'
$bash = Join-Path $msys2Root 'usr\bin\bash.exe'

Write-Host [INFO] Using MSYS2 root: $msys2Root

# Already installed
if ((Test-Path $gcc) -and (Test-Path $gxx)) {
    Add-MachinePath $ucrt64Bin
    Write-Host '[OK] GCC + G++ already installed.'
    exit 0
}

# Install MSYS2 if not present
if (-not (Test-Path $bash)) {
    Write-Host '[1/4] Installing MSYS2 via winget...'
    Install-WingetPackage -PackageId 'MSYS2.MSYS2'
    Update-SessionPath
    $msys2Root = Get-Msys2Root
    $ucrt64Bin = Join-Path $msys2Root 'ucrt64\bin'
    $gcc       = Join-Path $ucrt64Bin 'gcc.exe'
    $gxx       = Join-Path $ucrt64Bin 'g++.exe'
    $bash      = Join-Path $msys2Root 'usr\bin\bash.exe'
    if (-not (Test-Path $bash)) {
        throw MSYS2 bash not found at '$bash' after install. Please install MSYS2 manually from https://www.msys2.org/
    }
    Write-Host '[INFO] Initializing MSYS2 core (first-time)...'
    & $bash -lc 'pacman -Syu --noconfirm 2>&1' | ForEach-Object { Write-Host  $_ }
    Write-Host '[INFO] MSYS2 core init done.'
} else {
    Write-Host '[1/4] MSYS2 already present.'
}

# Guard concurrent pacman
$pacmanRunning = Get-Process -Name 'pacman' -ErrorAction SilentlyContinue
if ($pacmanRunning) {
    throw 'pacman (MSYS2) dang chay. Cho no hoan tat roi thu lai.'
}

# Update UCRT64 mirrorlist to add reliable mirrors first (fixes stale mirror 404)
Write-Host '[2/4] Checking MSYS2 mirrorlist...'
$mlPath = Join-Path $msys2Root 'etc\pacman.d\mirrorlist.ucrt64'
if (Test-Path $mlPath) {
    $existingContent = Get-Content $mlPath -Encoding UTF8 -ErrorAction SilentlyContinue
    if ($existingContent -and ($existingContent -join '') -notmatch 'Managed by StudentDevKit') {
        $preferredServers = @(
            'Server = https://repo.msys2.org/mingw/ucrt64/',
            'Server = https://mirror.msys2.org/mingw/ucrt64/',
            'Server = https://sourceforge.net/projects/msys2/files/REPOS/MINGW/UCRT64/',
            'Server = https://ftp.osuosl.org/pub/msys2/repos/mingw/ucrt64/',
            'Server = https://mirror.umd.edu/msys2/repos/mingw/ucrt64/'
        )
        $origServers = $existingContent | Where-Object { $_ -match '^Server\s*=' }
        $allServers  = [System.Collections.Generic.List[string]]::new()
        foreach ($s in $preferredServers) { [void]$allServers.Add($s) }
        foreach ($s in $origServers) {
            $norm = $s.Trim()
            $dup  = $false
            foreach ($a in $allServers) { if ($a.Trim() -ieq $norm) { $dup = $true; break } }
            if (-not $dup) { [void]$allServers.Add($norm) }
        }
        $newContent = @('# Managed by StudentDevKit - preferred mirrors first') + $allServers
        Set-Content $mlPath -Value $newContent -Encoding UTF8
        Write-Host  [OK] Updated mirrorlist.ucrt64 with $($allServers.Count) mirrors
    } else {
        Write-Host '  [OK] Mirrorlist already up to date.'
    }
} else {
    Write-Host '  [SKIP] mirrorlist.ucrt64 not found (MSYS2 may be fresh install).'
}

# Force-refresh package DB from upstream (-yy ignores local cache)
Write-Host '[3/4] Syncing MSYS2 package database (force refresh)...'
& $bash -lc 'pacman -Syy --noconfirm 2>&1' | ForEach-Object { Write-Host  $_ }
if ($LASTEXITCODE -ne 0) {
    Write-Host [WARN] pacman -Syy exit $LASTEXITCODE - continuing anyway.
}

# Install GCC with retry
# -Suu: sync + upgrade + allow downgrade
# --disable-download-timeout: do not fail on slow connections
# If mirror has v15 but DB says v16: -uu lets pacman install v15 instead of 404
$maxRetries = 3
$installed  = $false

Write-Host '[4/4] Installing GCC + G++ (mingw-w64-ucrt-x86_64-gcc) with retry...'
for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
    if ($attempt -gt 1) {
        Write-Host [RETRY $attempt/$maxRetries] Waiting 8s then retrying...
        Start-Sleep -Seconds 8
        & $bash -lc 'pacman -Syy --noconfirm 2>&1' | ForEach-Object { Write-Host  $_ }
    }
    & $bash -lc 'pacman -Suu --needed --noconfirm --disable-download-timeout mingw-w64-ucrt-x86_64-gcc 2>&1' | ForEach-Object { Write-Host  $_ }
    if ($LASTEXITCODE -eq 0) { $installed = $true; break }
    Write-Host [WARN] Attempt $attempt failed (exit $LASTEXITCODE).
}

if (-not $installed) {
    Write-Host '[FALLBACK] Trying plain -Sy install...'
    & $bash -lc 'pacman -Sy --needed --noconfirm --disable-download-timeout mingw-w64-ucrt-x86_64-gcc 2>&1' | ForEach-Object { Write-Host  $_ }
    if ($LASTEXITCODE -ne 0) {
        throw GCC/G++ installation failed after $maxRetries retries. Kiem tra ket noi mang va thu lai sau.
    }
}

if (-not (Test-Path $gcc) -or -not (Test-Path $gxx)) {
    throw gcc.exe / g++.exe not found at '$ucrt64Bin' after installation.
}

Add-MachinePath $ucrt64Bin
Write-Host [OK] GCC + G++ installed at: $ucrt64Bin
