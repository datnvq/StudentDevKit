# scripts/common.ps1
# Shared installation utilities. Dot-sourced by all installer scripts.
# Compatible: PowerShell 5.1+

function Test-CommandExists {
    param([Parameter(Mandatory=$true)][string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Add-MachinePath {
    <#
    .SYNOPSIS
        Appends a directory to the Machine-level PATH in the registry if not already present.
        Also updates the current session's $env:Path.
    .NOTES
        Uses exact per-segment comparison (not substring), fixing the original bug where
        C:\msys64\ucrt64\bin could be matched by C:\extra\msys64\ucrt64\bin.
    #>
    param([Parameter(Mandatory=$true)][string]$PathToAdd)

    $pathToAddNorm = $PathToAdd.TrimEnd('\')
    $machinePath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)

    $segments = @()
    if ($machinePath) {
        $segments = $machinePath -split ';' | Where-Object { $_ -and $_.Trim() }
    }

    $alreadyPresent = $false
    foreach ($seg in $segments) {
        # Exact comparison after normalizing trailing backslash
        if ($seg.TrimEnd('\') -ieq $pathToAddNorm) {
            $alreadyPresent = $true
            break
        }
    }

    if (-not $alreadyPresent) {
        $newPath = (($segments + $pathToAddNorm) -join ';').TrimEnd(';')
        [System.Environment]::SetEnvironmentVariable('Path', $newPath, [System.EnvironmentVariableTarget]::Machine)
        Write-Host "[OK] Added to Machine PATH: $pathToAddNorm"
    } else {
        Write-Host "[OK] Already in Machine PATH: $pathToAddNorm"
    }

    # Also update current session so subsequent commands in this script find the tools
    $sessionSegments = $env:Path -split ';' | Where-Object { $_ -and $_.Trim() }
    $inSession = $sessionSegments | Where-Object { $_.TrimEnd('\') -ieq $pathToAddNorm }
    if (-not $inSession) {
        $env:Path = "$pathToAddNorm;$env:Path"
    }
}

function Install-WingetPackage {
    <#
    .SYNOPSIS
        Installs a package via winget with strict safety checks.
        - Resolves winget via Get-Command (never builds the string 'winget').
        - Validates PackageId: not blank, not 'install', no shell-injection chars.
        - Uses --id and --exact to prevent ambiguous package matching.
        - Throws on winget not found or non-zero exit.
    #>
    param([Parameter(Mandatory=$true)][string]$PackageId)

    # Validation: catch the classic 'winget install install' bug and related variants
    if ([string]::IsNullOrWhiteSpace($PackageId)) {
        throw "PackageId must not be blank."
    }
    # Reject any value that could become a winget subcommand or inject shell chars
    $blocked = @('install','uninstall','upgrade','list','show','source','search','import','export','settings','features','hash','validate','complete')
    if ($blocked -contains $PackageId.Trim().ToLowerInvariant()) {
        throw "Invalid PackageId '$PackageId' — value matches a winget subcommand name."
    }
    if ($PackageId -match '[;&|`"<>]') {
        throw "PackageId '$PackageId' contains disallowed characters."
    }

    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $winget) {
        throw 'winget.exe not found. Please update Microsoft App Installer (from the Microsoft Store) and try again.'
    }

    Write-Host "  -> winget install --id $PackageId --exact"
    & $winget.Source install --id $PackageId --exact --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) {
        # -1978335189 (0x8A150011) = APPINSTALLER_CLI_ERROR_PACKAGE_ALREADY_INSTALLED
        # winget returns this when package is already installed; treat as success.
        throw "winget exited with code $LASTEXITCODE for package '$PackageId'."
    }
}

function Test-ProcessRunning {
    <#
    .SYNOPSIS
        Returns $true if a process with the given name is currently running.
        Used by preflight checks to detect running installers.
    #>
    param([Parameter(Mandatory=$true)][string]$ProcessName)
    $procs = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    return ($null -ne $procs -and @($procs).Count -gt 0)
}

function Get-Config {
    param([Parameter(Mandatory=$true)][string]$Path)
    return Get-Content $Path -Raw -Encoding UTF8 | ConvertFrom-Json
}
