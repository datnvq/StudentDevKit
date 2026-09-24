# scripts/preflight.ps1
# Pre-installation checks: running processes, winget availability, disk space.
# Returns a list of warnings/blockers. Does NOT kill any process.
# Compatible: PowerShell 5.1+

param(
    [switch]$Silent   # If set, suppresses Write-Host output; returns result object only
)

function Get-PreflightResult {
    $result = [PSCustomObject]@{
        OK       = $true
        Blockers = [System.Collections.Generic.List[string]]::new()
        Warnings = [System.Collections.Generic.List[string]]::new()
    }

    # ---- 1. Winget availability ----
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) {
        [void]$result.Blockers.Add('winget.exe not found. Install or update Microsoft App Installer from the Microsoft Store.')
        $result.OK = $false
    }

    # ---- 2. Detect running conflicting processes ----
    $conflictProcesses = @(
        @{ Name = 'winget';    Display = 'winget' },
        @{ Name = 'msiexec';   Display = 'Windows Installer (msiexec)' },
        @{ Name = 'WinStore.App'; Display = 'Microsoft Store' }
    )
    foreach ($p in $conflictProcesses) {
        $running = Get-Process -Name $p.Name -ErrorAction SilentlyContinue
        if ($running) {
            [void]$result.Warnings.Add("$($p.Display) is currently running. Wait for it to finish before installing.")
        }
    }

    # Detect pacman specifically (MSYS2 package manager)
    $pacman = Get-Process -Name 'pacman' -ErrorAction SilentlyContinue
    if ($pacman) {
        [void]$result.Blockers.Add('pacman (MSYS2) is already running. Wait for it to finish before installing C/C++ components.')
        $result.OK = $false
    }

    # ---- 3. Internet connectivity (lightweight HTTP check) ----
    try {
        $req = [System.Net.WebRequest]::Create('http://www.msftconnecttest.com/connecttest.txt')
        $req.Timeout = 2500
        $req.Method = 'HEAD'
        $resp = $req.GetResponse()
        $resp.Close()
    } catch {
        [void]$result.Warnings.Add('Kiem tra ket noi internet that bai. Cai dat co the khong hoat dong neu offline.')
    }

    # ---- 4. Disk space (C: drive, require at least 3 GB free) ----
    try {
        $drive = Get-PSDrive C -ErrorAction SilentlyContinue
        if ($drive -and $drive.Free -lt 3GB) {
            $freeGB = [Math]::Round($drive.Free / 1GB, 1)
            [void]$result.Warnings.Add("Low disk space on C: (${freeGB} GB free). At least 3 GB recommended for MSYS2 + tools.")
        }
    } catch {}

    # ---- 5. PowerShell version ----
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        [void]$result.Blockers.Add("PowerShell 5.1 or later is required. Current version: $($PSVersionTable.PSVersion).")
        $result.OK = $false
    }

    return $result
}

$preflightResult = Get-PreflightResult

if (-not $Silent) {
    if ($preflightResult.Blockers.Count -gt 0) {
        Write-Host ''
        Write-Host '  [PREFLIGHT] Blockers detected — installation cannot proceed:' -ForegroundColor Red
        foreach ($b in $preflightResult.Blockers) {
            Write-Host "    [X] $b" -ForegroundColor Red
        }
    }
    if ($preflightResult.Warnings.Count -gt 0) {
        Write-Host ''
        Write-Host '  [PREFLIGHT] Warnings:' -ForegroundColor Yellow
        foreach ($w in $preflightResult.Warnings) {
            Write-Host "    [!] $w" -ForegroundColor Yellow
        }
    }
    if ($preflightResult.OK -and $preflightResult.Warnings.Count -eq 0) {
        Write-Host '  [PREFLIGHT] All checks passed.' -ForegroundColor Green
    }
    Write-Host ''
}

return $preflightResult
