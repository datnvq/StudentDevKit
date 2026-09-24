# scripts/verify.ps1
# Verification table: shows status of all tools + post-install C/C++ compile test.
# Uses detect.ps1 for consistent detection logic.
# Compatible: PowerShell 5.1+

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
try { chcp 65001 | Out-Null } catch {}

$scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
. (Join-Path $scriptDir 'detect.ps1')

$msys2Root = Get-Msys2Root

# ---- TABLE HEADER ----
Write-Host ''
Write-Host '  Bang Kiem Tra Cong Cu Lap Trinh - StudentDevKit v0.5.0' -ForegroundColor Cyan
Write-Host ''
Write-Host '  +------------------------+----------------+------------------------------------------------+' -ForegroundColor DarkCyan
Write-Host '  | CONG CU / LENH         | TRANG THAI     | CHI TIET                                       |' -ForegroundColor Cyan
Write-Host '  +------------------------+----------------+------------------------------------------------+' -ForegroundColor DarkCyan

function Write-TableRow {
    param([string]$Label, [string]$Status, [string]$StatusColor, [string]$Detail)
    $lPad = $Label.PadRight(22)
    $sPad = $Status.PadRight(14)
    $detail = $Detail
    if ($detail.Length -gt 46) { $detail = '...' + $detail.Substring($detail.Length - 43) }
    $dPad = $detail.PadRight(46)
    Write-Host '  | ' -NoNewline -ForegroundColor DarkCyan
    Write-Host $lPad -NoNewline -ForegroundColor White
    Write-Host ' | ' -NoNewline -ForegroundColor DarkCyan
    Write-Host $sPad -NoNewline -ForegroundColor $StatusColor
    Write-Host ' | ' -NoNewline -ForegroundColor DarkCyan
    Write-Host $dPad -NoNewline -ForegroundColor Gray
    Write-Host ' |' -ForegroundColor DarkCyan
}

$items = @(
    @{ Label = 'VS Code (code)';    Cmd = 'code';      Note = 'Trinh soan thao' },
    @{ Label = 'Git (git)';         Cmd = 'git';       Note = 'Quan ly phien ban' },
    @{ Label = 'GCC (gcc)';         Cmd = 'gcc';       Note = 'Bien dich C' },
    @{ Label = 'G++ (g++)';         Cmd = 'g++';       Note = 'Bien dich C++' },
    @{ Label = 'GDB (gdb)';         Cmd = 'gdb';       Note = 'Go loi C/C++' },
    @{ Label = 'CMake';             Cmd = 'cmake';     Note = 'He thong build' },
    @{ Label = 'Ninja';             Cmd = 'ninja';     Note = 'Build tool' },
    @{ Label = 'Clang';             Cmd = 'clang';     Note = 'LLVM Clang' },
    @{ Label = 'Cppcheck';          Cmd = 'cppcheck';  Note = 'Phan tich tinh C++' },
    @{ Label = 'Python';            Cmd = 'python';    Note = 'Python runtime' },
    @{ Label = 'Node.js (node)';    Cmd = 'node';      Note = 'JavaScript runtime' }
)

$installedCount = 0
foreach ($item in $items) {
    $cmd = Get-Command $item.Cmd -ErrorAction SilentlyContinue
    if ($cmd -and $item.Cmd -eq 'python' -and $cmd.Source -like '*\WindowsApps\python*') { $cmd = $null }
    if ($cmd) {
        $installedCount++
        Write-TableRow -Label $item.Label -Status '[OK] Da cai' -StatusColor Green -Detail $cmd.Source
    } else {
        Write-TableRow -Label $item.Label -Status '[--] Chua co' -StatusColor DarkGray -Detail "Chua co trong PATH ($($item.Note))"
    }
}

# MSYS2 specific file checks
Write-Host '  +------------------------+----------------+------------------------------------------------+' -ForegroundColor DarkCyan
$gccPath = Join-Path $msys2Root 'ucrt64\bin\gcc.exe'
$gdbPath = Join-Path $msys2Root 'ucrt64\bin\gdb.exe'
$msys2Label = "MSYS2 UCRT64 root"
Write-TableRow -Label $msys2Label -Status $(if (Test-Path "$msys2Root\usr\bin\bash.exe") { '[OK] San sang' } else { '[--] Chua co' }) `
    -StatusColor $(if (Test-Path "$msys2Root\usr\bin\bash.exe") { 'Green' } else { 'DarkGray' }) -Detail $msys2Root
Write-TableRow -Label 'gcc.exe (UCRT64)' `
    -Status $(if (Test-Path $gccPath) { '[OK] San sang' } else { '[--] Chua co' }) `
    -StatusColor $(if (Test-Path $gccPath) { 'Green' } else { 'DarkGray' }) `
    -Detail $gccPath
Write-TableRow -Label 'gdb.exe (UCRT64)' `
    -Status $(if (Test-Path $gdbPath) { '[OK] San sang' } else { '[--] Chua co' }) `
    -StatusColor $(if (Test-Path $gdbPath) { 'Green' } else { 'DarkGray' }) `
    -Detail $gdbPath

Write-Host '  +------------------------+----------------+------------------------------------------------+' -ForegroundColor DarkCyan
Write-Host ''
Write-Host "  Cong cu trong PATH: $installedCount / $($items.Count) san sang." -ForegroundColor Cyan

# ---- C/C++ COMPILE TEST ----
Write-Host ''
Write-Host '  -- Kiem tra bien dich C/C++ thuc te (hello.c) -----------------------------------' -ForegroundColor DarkGray

$gccCmd = Get-Command 'gcc' -ErrorAction SilentlyContinue
if (-not $gccCmd -and (Test-Path $gccPath)) {
    $gccCmd = [PSCustomObject]@{ Source = $gccPath }
}

if ($gccCmd) {
    $tmpDir = Join-Path $env:TEMP 'devkit_verify'
    New-Item $tmpDir -ItemType Directory -Force | Out-Null
    $tmpSrc = Join-Path $tmpDir 'hello.c'
    $tmpExe = Join-Path $tmpDir 'hello.exe'

    Set-Content $tmpSrc -Value @'
#include <stdio.h>
int main(void) { printf("DevKit-verify-OK\n"); return 0; }
'@ -Encoding ASCII

    try {
        & $gccCmd.Source $tmpSrc -o $tmpExe 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0 -and (Test-Path $tmpExe)) {
            $output = & $tmpExe 2>&1
            if ("$output" -match 'DevKit-verify-OK') {
                Write-Host '  [PASS] gcc compile + run test thanh cong.' -ForegroundColor Green
            } else {
                Write-Host "  [WARN] Bien dich thanh cong nhung output bat thuong: $output" -ForegroundColor Yellow
            }
        } else {
            Write-Host '  [FAIL] gcc compile that bai.' -ForegroundColor Red
        }
    } catch {
        Write-Host "  [FAIL] Loi khi chay compile test: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
} else {
    Write-Host '  [SKIP] gcc chua co trong he thong - bo qua compile test.' -ForegroundColor DarkGray
}

# ---- VERSION CHECKS ----
Write-Host ''
Write-Host '  -- Phien ban cong cu ------------------------------------------------------------' -ForegroundColor DarkGray

$versionCmds = @(
    @{ Cmd = 'gcc';   Args = '--version' },
    @{ Cmd = 'g++';   Args = '--version' },
    @{ Cmd = 'gdb';   Args = '--version' },
    @{ Cmd = 'git';   Args = '--version' },
    @{ Cmd = 'code';  Args = '--version' }
)
foreach ($v in $versionCmds) {
    $exe = Get-Command $v.Cmd -ErrorAction SilentlyContinue
    if ($exe) {
        try {
            $ver = & $exe $v.Args 2>&1 | Select-Object -First 1
            Write-Host "  $($v.Cmd.PadRight(8)) $ver" -ForegroundColor DarkCyan
        } catch {}
    }
}

# ---- VS CODE EXTENSIONS ----
Write-Host ''
Write-Host '  -- VS Code Extensions -----------------------------------------------------------' -ForegroundColor DarkGray
$codeExe = Get-Command 'code' -ErrorAction SilentlyContinue
if ($codeExe) {
    $configPath = Join-Path (Split-Path $scriptDir -Parent) 'config\components.json'
    if (Test-Path $configPath) {
        $cfg = Get-Content $configPath -Raw | ConvertFrom-Json
        $extList = @(& $codeExe.Source --list-extensions 2>$null)
        foreach ($ext in @($cfg.vscodeExtensions)) {
            if ($extList -contains $ext) {
                Write-Host "  [OK] $ext" -ForegroundColor Green
            } else {
                Write-Host "  [--] $ext  (chua cai)" -ForegroundColor DarkGray
            }
        }
    }
} else {
    Write-Host '  [SKIP] VS Code chua co trong PATH - bo qua kiem tra extension.' -ForegroundColor DarkGray
}

# ---- DEVKIT FILES ----
Write-Host ''
Write-Host '  -- Tep cau hinh StudentDevKit ---------------------------------------------------' -ForegroundColor DarkGray
$settingsFile = Join-Path $env:APPDATA 'Code\User\settings.json'
$snippetFile  = Join-Path $env:APPDATA 'Code\User\snippets\studentdevkit-cpp.code-snippets'
$templateDir  = Join-Path ([System.Environment]::GetFolderPath('MyDocuments')) 'StudentDevKit\cpp-template'
$logDir       = Get-DevKitLogDir

Write-Host "  Settings : $(if (Test-Path $settingsFile) { '[OK] ' + $settingsFile } else { '[--] Chua tao' })" -ForegroundColor $(if (Test-Path $settingsFile) { 'Green' } else { 'DarkGray' })
Write-Host "  Snippets : $(if (Test-Path $snippetFile)  { '[OK] ' + $snippetFile  } else { '[--] Chua tao' })" -ForegroundColor $(if (Test-Path $snippetFile) { 'Green' } else { 'DarkGray' })
Write-Host "  Template : $(if (Test-Path $templateDir)  { '[OK] ' + $templateDir  } else { '[--] Chua deploy' })" -ForegroundColor $(if (Test-Path $templateDir) { 'Green' } else { 'DarkGray' })
Write-Host "  Logs     : $(if (Test-Path $logDir)       { '[OK] ' + $logDir       } else { '[--] Chua co log' })" -ForegroundColor $(if (Test-Path $logDir) { 'Green' } else { 'DarkGray' })

Write-Host ''
