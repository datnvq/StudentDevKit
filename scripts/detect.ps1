# scripts/detect.ps1
# Single source of truth for component detection.
# Dot-sourced by: setup.ps1, gui.ps1, verify.ps1, and gcc/gdb installer scripts.
# Must NOT import common.ps1 (no circular deps). Self-contained.
# Compatible: PowerShell 5.1+

# --- MSYS2 DETECTION ---

function Find-Msys2Root {
    <#
    .SYNOPSIS
        Probes for an existing MSYS2 installation. Returns root path or $null.
    .NOTES
        Checks: common paths, PATH env hints, registry uninstall entries.
        Does NOT assume C:\msys64.
    #>

    $candidates = [System.Collections.Generic.List[string]]::new()

    # 1. Hints from current PATH — look for ucrt64\bin or usr\bin in any segment
    foreach ($segment in ($env:Path -split ';')) {
        $seg = $segment.Trim().TrimEnd('\')
        if ($seg -match '(?i)(msys\d*|msys2)[\\]') {
            # Try to walk up to MSYS2 root
            $current = $seg
            for ($i = 0; $i -lt 4; $i++) {
                if (Test-Path (Join-Path $current 'usr\bin\bash.exe')) {
                    [void]$candidates.Add($current)
                    break
                }
                $parent = Split-Path $current -Parent
                if (-not $parent -or $parent -eq $current) { break }
                $current = $parent
            }
        }
    }

    # 2. Registry scan (both 32-bit and 64-bit views, HKLM + HKCU)
    $regBases = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
    )
    foreach ($base in $regBases) {
        if (-not (Test-Path $base)) { continue }
        $keys = Get-ChildItem $base -ErrorAction SilentlyContinue
        foreach ($key in $keys) {
            try {
                $displayName = $key.GetValue('DisplayName')
                if ($displayName -and $displayName -like 'MSYS2*') {
                    $loc = $key.GetValue('InstallLocation')
                    if ($loc -and (Test-Path (Join-Path $loc 'usr\bin\bash.exe'))) {
                        [void]$candidates.Add($loc.TrimEnd('\'))
                    }
                }
            } catch {}
        }
    }

    # 3. Common well-known paths (checked last, lower priority)
    $wellKnown = @(
        'C:\msys64',
        'C:\msys2',
        'D:\msys64',
        'D:\msys2',
        (Join-Path $env:SystemDrive 'msys64'),
        (Join-Path $env:SystemDrive 'msys2'),
        (Join-Path $env:ProgramFiles 'MSYS2'),
        (Join-Path ${env:ProgramFiles(x86)} 'MSYS2')
    )
    foreach ($p in $wellKnown) {
        if ($p -and (Test-Path (Join-Path $p 'usr\bin\bash.exe'))) {
            [void]$candidates.Add($p.TrimEnd('\'))
        }
    }

    # Return first valid candidate (unique check)
    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($c in $candidates) {
        if ([string]::IsNullOrWhiteSpace($c)) { continue }
        if ($seen.Add($c) -and (Test-Path (Join-Path $c 'usr\bin\bash.exe'))) {
            return $c
        }
    }
    return $null
}

function Get-Msys2Root {
    <#
    .SYNOPSIS
        Returns MSYS2 root to use. Prefers existing installation; falls back to C:\msys64.
    #>
    $found = Find-Msys2Root
    if ($found) { return $found }
    return 'C:\msys64'
}

# --- PATH REFRESH ---

function Update-SessionPath {
    <#
    .SYNOPSIS
        Reloads Machine + User PATH from registry into $env:Path for the current session.
        Call this immediately after winget/pacman installs to make new tools visible
        without opening a new terminal.
    #>
    try {
        $machinePath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)
        $userPath    = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::User)
        $parts = @()
        if ($machinePath) { $parts += $machinePath.TrimEnd(';') }
        if ($userPath)    { $parts += $userPath.TrimEnd(';') }
        if ($parts.Count -gt 0) {
            $env:Path = ($parts -join ';')
        }
    } catch {
        # Non-fatal. If registry read fails, leave existing $env:Path intact.
    }
}

# --- LOG DIRECTORY ---

function Get-DevKitLogDir {
    return Join-Path $env:APPDATA 'StudentDevKit\logs'
}

function Write-DevKitLog {
    param([string]$Message, [string]$LogFile = '')
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$timestamp] $Message"
    if ($LogFile -and (Test-Path (Split-Path $LogFile -Parent))) {
        Add-Content -Path $LogFile -Value $line -Encoding UTF8 -ErrorAction SilentlyContinue
    }
}

function New-DevKitLogFile {
    $dir = Get-DevKitLogDir
    New-Item $dir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    $stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
    return Join-Path $dir "install-$stamp.log"
}

# --- COMPONENT DETECTION ---
# Single authoritative implementation. Used by setup.ps1, gui.ps1, verify.ps1.
# Returns $true if component is installed and usable, $false otherwise.
# Note: For tools newly installed via winget, call Update-SessionPath BEFORE calling
# this function to ensure PATH is current.

function Test-ComponentInstalled {
    param([string]$Id)

    # Private helper: does this command exist in current PATH?
    $inPath = { param($n) $null -ne (Get-Command $n -ErrorAction SilentlyContinue) }

    $msys2Root = Get-Msys2Root

    switch ($Id) {

        'vscode' {
            # 1. In PATH (normal case)
            if (& $inPath 'code') { return $true }
            # 2. Common install locations (PATH not yet refreshed)
            $locs = @(
                (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'),
                (Join-Path $env:ProgramFiles 'Microsoft VS Code\bin\code.cmd')
            )
            foreach ($l in $locs) { if ($l -and (Test-Path $l)) { return $true } }
            return $false
        }

        'git' {
            if (& $inPath 'git') { return $true }
            $locs = @(
                'C:\Program Files\Git\cmd\git.exe',
                'C:\Program Files (x86)\Git\cmd\git.exe'
            )
            foreach ($l in $locs) { if (Test-Path $l) { return $true } }
            return $false
        }

        'cpp-gcc' {
            $gcc = Join-Path $msys2Root 'ucrt64\bin\gcc.exe'
            $gxx = Join-Path $msys2Root 'ucrt64\bin\g++.exe'
            return ((Test-Path $gcc) -and (Test-Path $gxx))
        }

        'cpp-gdb' {
            $gdb = Join-Path $msys2Root 'ucrt64\bin\gdb.exe'
            return (Test-Path $gdb)
        }

        'cmake' {
            if (& $inPath 'cmake') { return $true }
            # winget installs cmake to Program Files
            $loc = Join-Path $env:ProgramFiles 'CMake\bin\cmake.exe'
            return (Test-Path $loc)
        }

        'ninja' {
            return (& $inPath 'ninja')
        }

        'clang' {
            if (& $inPath 'clang') { return $true }
            $loc = Join-Path $env:ProgramFiles 'LLVM\bin\clang.exe'
            return (Test-Path $loc)
        }

        'cppcheck' {
            if (& $inPath 'cppcheck') { return $true }
            $loc = Join-Path $env:ProgramFiles 'Cppcheck\cppcheck.exe'
            return (Test-Path $loc)
        }

        'python' {
            $cmd = Get-Command 'python' -ErrorAction SilentlyContinue
            if (-not $cmd) { return $false }
            if ($cmd.Source -like '*\WindowsApps\python*') { return $false }
            return $true
        }
        'python312' {
            $cmd = Get-Command 'python' -ErrorAction SilentlyContinue
            if (-not $cmd) { return $false }
            if ($cmd.Source -like '*\WindowsApps\python*') { return $false }
            return $true
        }

        'node' { return (& $inPath 'node') }
        'node-current' { return (& $inPath 'node') }

        'java' {
            if (& $inPath 'java') { return $true }
            if (& $inPath 'javac') { return $true }
            $locs = @(
                (Join-Path $env:ProgramFiles 'Eclipse Adoptium\jdk-*\bin\java.exe'),
                (Join-Path $env:ProgramFiles 'Microsoft\jdk-*\bin\java.exe')
            )
            foreach ($l in $locs) {
                if (Get-ChildItem -Path $l -ErrorAction SilentlyContinue) { return $true }
            }
            return $false
        }
        'java17' {
            if (& $inPath 'java') { return $true }
            if (& $inPath 'javac') { return $true }
            $locs = @(
                (Join-Path $env:ProgramFiles 'Eclipse Adoptium\jdk-*\bin\java.exe'),
                (Join-Path $env:ProgramFiles 'Microsoft\jdk-*\bin\java.exe')
            )
            foreach ($l in $locs) {
                if (Get-ChildItem -Path $l -ErrorAction SilentlyContinue) { return $true }
            }
            return $false
        }

        'csharp' {
            if (& $inPath 'dotnet') { return $true }
            $loc = Join-Path $env:ProgramFiles 'dotnet\dotnet.exe'
            return (Test-Path $loc)
        }
        'csharp9' {
            if (& $inPath 'dotnet') { return $true }
            $loc = Join-Path $env:ProgramFiles 'dotnet\dotnet.exe'
            return (Test-Path $loc)
        }

        'vscode-ext' {
            return $false
        }

        'settings' {
            # Check that at least one DevKit-owned key exists in user settings
            $settingsFile = Join-Path $env:APPDATA 'Code\User\settings.json'
            if (-not (Test-Path $settingsFile)) { return $false }
            try {
                $s = Get-Content $settingsFile -Raw | ConvertFrom-Json
                # DevKit-owned key: C_Cpp.default.compilerPath
                return ($null -ne $s.'C_Cpp.default.compilerPath')
            } catch {
                return $false
            }
        }

        'snippets' {
            $snippetFile = Join-Path $env:APPDATA 'Code\User\snippets\studentdevkit-cpp.code-snippets'
            return (Test-Path $snippetFile)
        }

        'template' {
            # Template is "installed" only when deployed to user's Documents
            $deployDir = Join-Path ([System.Environment]::GetFolderPath('MyDocuments')) 'StudentDevKit\cpp-template'
            return (Test-Path (Join-Path $deployDir 'main.cpp'))
        }

        default { return $false }
    }
}

# DevKit-owned VS Code setting keys.
# Only these keys will be overwritten when re-running configure-vscode-settings.
# All other user settings are left untouched.
$script:DevKitOwnedSettingKeys = @(
    'C_Cpp.default.compilerPath',
    'C_Cpp.default.cppStandard'
)

function Get-DevKitOwnedSettingKeys { return $script:DevKitOwnedSettingKeys }
