#requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$Gui,
    [switch]$SkipElevation,
    [switch]$SelfTest
)

$ErrorActionPreference = 'Stop'

# Cấu hình UTF-8 toàn diện
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
try { chcp 65001 | Out-Null } catch {}

try {
    $host.UI.RawUI.WindowTitle = "StudentDevKit v0.5.0 - Bo Cong Cu Lap Trinh Sinh Vien"
} catch {}

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

# Load single-source detection module
. (Join-Path $Root 'scripts\detect.ps1')

function Test-IsAdmin {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ---- ELEVATION ----
if (-not $SkipElevation -and -not (Test-IsAdmin)) {
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    if ($Gui)      { $argList += ' -Gui' }
    if ($SelfTest) { $argList += ' -SelfTest' }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $argList
    exit
}

# ---- GUI MODE (Tuy chon phu) ----
if ($Gui) {
    $guiScript = Join-Path $Root 'scripts\gui.ps1'
    if (Test-Path $guiScript) {
        try {
            & $guiScript
        } catch {
            Add-Type -AssemblyName System.Windows.Forms
            [System.Windows.Forms.MessageBox]::Show(
                "Loi khoi dong giao dien:`n$($_.Exception.Message)",
                "StudentDevKit - Loi",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        }
        exit
    }
    Write-Host '[ERROR] scripts\gui.ps1 not found.' -ForegroundColor Red
    exit 1
}

# ---- CONFIG ----
$config     = Get-Content (Join-Path $Root 'config\components.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$components = @($config.components)

# ---- TERMINAL UI HELPERS (FONT-SAFE ASCII & UTF8) ----

function Show-Header {
    param([string]$SubTitle = '')
    Clear-Host
    Write-Host ''
    Write-Host '  ========================================================================' -ForegroundColor Cyan
    Write-Host '                       STUDENT DEV KIT  v0.5.0                            ' -ForegroundColor White
    Write-Host '            Bo Cong Cu Lap Trinh Chuan Hoa Danh Cho Sinh Vien             ' -ForegroundColor DarkCyan
    Write-Host '  ========================================================================' -ForegroundColor Cyan

    $adminOk    = Test-IsAdmin
    $adminText  = if ($adminOk)  { 'Administrator [HOP LE]' } else { 'Chua co quyen Administrator' }
    $adminColor = if ($adminOk)  { 'Green' } else { 'Yellow' }

    $msys2 = Find-Msys2Root
    $msys2Text  = if ($msys2) { "MSYS2 UCRT64: $msys2" } else { 'MSYS2: Chua tim thay' }
    $msys2Color = if ($msys2) { 'DarkCyan' } else { 'DarkGray' }

    Write-Host "  Thu muc  : $Root" -ForegroundColor DarkGray
    Write-Host "  Quyen han: " -NoNewline -ForegroundColor DarkGray
    Write-Host $adminText -ForegroundColor $adminColor
    Write-Host "  Bo dich  : $msys2Text" -ForegroundColor $msys2Color
    if ($SubTitle) {
        Write-Host "  -> Muc hien tai: " -NoNewline -ForegroundColor DarkGray
        Write-Host $SubTitle -ForegroundColor Yellow
    }
    Write-Host '  ------------------------------------------------------------------------' -ForegroundColor DarkGray
    Write-Host ''
}

function Wait-Menu {
    Write-Host ''
    Write-Host '  -> Nhan phim Enter de tiep tuc...' -ForegroundColor DarkCyan
    [void](Read-Host)
}

function Draw-ProgressBar {
    param([int]$Current, [int]$Total, [string]$ItemName = '')
    $pct          = [int]($Current * 100 / [Math]::Max(1, $Total))
    $barLength    = 30
    $filled       = [int]($pct * $barLength / 100)
    $filledStr    = [string]::new([char]'#', $filled)
    $emptyStr     = [string]::new([char]'-', $barLength - $filled)

    Write-Host '  Tien trinh: [' -NoNewline -ForegroundColor DarkCyan
    Write-Host $filledStr -NoNewline -ForegroundColor Green
    Write-Host $emptyStr  -NoNewline -ForegroundColor DarkGray
    Write-Host ('] {0,3}%  ({1}/{2})' -f $pct, $Current, $Total) -ForegroundColor Cyan
    if ($ItemName) {
        Write-Host "  Dang xu ly: $ItemName" -ForegroundColor Yellow
    }
}

# ---- COMPONENT SELECTION UI ----

function Get-SelectedComponents {
    param([ValidateSet('custom','recommended','all')][string]$Mode = 'custom')

    $selected = New-Object 'System.Collections.Generic.List[string]'

    if ($Mode -eq 'all') {
        foreach ($c in $components) { [void]$selected.Add([string]$c.id) }
    } elseif ($Mode -eq 'recommended') {
        foreach ($c in $components) {
            if ($c.recommended -and -not (Test-ComponentInstalled ([string]$c.id))) {
                [void]$selected.Add([string]$c.id)
            }
        }
        if ($selected.Count -eq 0) {
            Show-Header -SubTitle 'Thong Bao'
            Write-Host '  [THONG TIN] Tat ca cac goi de xuat chuan cho sinh vien:' -ForegroundColor Green
            Write-Host '              - Visual Studio Code' -ForegroundColor White
            Write-Host '              - Git for Windows' -ForegroundColor White
            Write-Host '              - MinGW-w64 GCC & G++ (UCRT64)' -ForegroundColor White
            Write-Host '              - GDB Debugger' -ForegroundColor White
            Write-Host '              - VS Code Extensions & Settings' -ForegroundColor White
            Write-Host '              - C++ Snippets & Template Mau' -ForegroundColor White
            Write-Host ''
            Write-Host '  => Tat ca DA DUOC CAI DAT DAY DU tren may cua ban!' -ForegroundColor Green
            Write-Host '     Ban khong can phai cai lai. Hay nhan [4] de kiem tra hoac [5] de xem huong dan.' -ForegroundColor Cyan
            Wait-Menu
            return $null
        }
    }

    $catLabels = @{
        'Editor'   = 'TRINH SOAN THAO (EDITOR)'
        'Core'     = 'CONG CU COT LOI (CORE)'
        'C/C++'    = 'LAP TRINH C / C++'
        'Build'    = 'HE THONG BUILD & BIEN DICH'
        'Language' = 'NGON NGU KHAC'
        'VS Code'  = 'CAU HINH VS CODE'
        'Project'  = 'DU AN MAU'
    }

    while ($true) {
        Show-Header -SubTitle 'Tuy Chon Thanh Phan Cai Dat'

        $groups = @($components | Group-Object category)
        $number = 1
        $lookup = @{}

        foreach ($group in $groups) {
            $catKey  = [string]$group.Name
            $catHead = if ($catLabels.ContainsKey($catKey)) { $catLabels[$catKey] } else { $catKey }
            Write-Host "  +-- [ $catHead ] ----------------------------------------------------+" -ForegroundColor DarkCyan

            foreach ($comp in @($group.Group)) {
                $id          = [string]$comp.id
                $isSelected  = $selected.Contains($id)
                $isInstalled = Test-ComponentInstalled $id

                $numStr   = '[{0,2}]' -f $number
                $markStr  = if ($isSelected)  { ' [X] DA CHON ' } else { ' [ ] BO CHON ' }
                $markColor= if ($isSelected)  { 'Cyan'         } else { 'DarkGray' }
                $stateStr = if ($isInstalled) { 'OK DA CO ' } else { '  CHUA CO' }
                $stateColor=if ($isInstalled) { 'Green'     } else { 'DarkGray' }

                Write-Host "  | $numStr" -NoNewline -ForegroundColor White
                Write-Host $markStr -NoNewline -ForegroundColor $markColor
                Write-Host " [$stateStr] " -NoNewline -ForegroundColor $stateColor
                Write-Host ('{0,-28}' -f $comp.name) -NoNewline -ForegroundColor White
                if ($comp.recommended) { Write-Host ' [* De xuat]' -NoNewline -ForegroundColor Yellow }
                Write-Host ''

                $lookup[[string]$number] = $id
                $number++
            }
            Write-Host '  +------------------------------------------------------------------------+' -ForegroundColor DarkCyan
            Write-Host ''
        }

        Write-Host '  --------------------------------------------------------------------------' -ForegroundColor DarkGray
        Write-Host '  [A] Chon Tat Ca       [N] Bo Chon Het       [R] Chon Goi De Xuat Con Thieu' -ForegroundColor Cyan
        Write-Host '  [S] BAT DAU CAI DAT   [B] Quay Lai Menu Chinh' -ForegroundColor Green
        Write-Host '  --------------------------------------------------------------------------' -ForegroundColor DarkGray
        Write-Host '  (Nhap so thu tu [1-14] de Bat/Tat chon, hoac go phim tat A / N / R / S / B)' -ForegroundColor DarkGray
        Write-Host ''

        $choice = (Read-Host '  -> Nhap lua chon cua ban').Trim().ToUpperInvariant()

        switch ($choice) {
            'B' { return $null }
            'A' {
                $selected.Clear()
                foreach ($c in $components) { [void]$selected.Add([string]$c.id) }
            }
            'N' { $selected.Clear() }
            'R' {
                $selected.Clear()
                foreach ($c in $components) {
                    if ($c.recommended -and -not (Test-ComponentInstalled ([string]$c.id))) {
                        [void]$selected.Add([string]$c.id)
                    }
                }
            }
            'S' { return @($selected) }
            default {
                $key = $choice.TrimStart('0')
                if ($lookup.ContainsKey($key)) {
                    $id = [string]$lookup[$key]
                    if ($selected.Contains($id)) { [void]$selected.Remove($id) }
                    else { [void]$selected.Add($id) }
                } elseif ($lookup.ContainsKey($choice)) {
                    $id = [string]$lookup[$choice]
                    if ($selected.Contains($id)) { [void]$selected.Remove($id) }
                    else { [void]$selected.Add($id) }
                } else {
                    Write-Host "  [X] Lua chon khong hop le: $choice" -ForegroundColor Red
                    Start-Sleep -Milliseconds 500
                }
            }
        }
    }
}

# ---- INSTALL PLAN ----

function Invoke-InstallPlan {
    param([string[]]$Ids)

    if (-not $Ids -or $Ids.Count -eq 0) {
        Show-Header -SubTitle 'Thong Bao'
        Write-Host '  [THONG BAO] Chua co thanh phan nao duoc chon de cai dat.' -ForegroundColor Yellow
        Wait-Menu
        return
    }

    # Run preflight
    $preflightScript = Join-Path $Root 'scripts\preflight.ps1'
    if (Test-Path $preflightScript) {
        $pre = & $preflightScript -Silent
        if (-not $pre.OK) {
            Show-Header -SubTitle 'Kiem Tra Truoc Khi Cai Dat'
            Write-Host '  [CHAN] Khong the tien hanh cai dat do cac nguyen nhan sau:' -ForegroundColor Red
            Write-Host ''
            foreach ($b in $pre.Blockers) { Write-Host "    [X] $b" -ForegroundColor Red }
            if ($pre.Warnings.Count -gt 0) {
                Write-Host ''
                foreach ($w in $pre.Warnings) { Write-Host "    [!] $w" -ForegroundColor Yellow }
            }
            Wait-Menu
            return
        }
        if ($pre.Warnings.Count -gt 0) {
            Show-Header -SubTitle 'Canh Bao Kiem Tra Truoc'
            foreach ($w in $pre.Warnings) { Write-Host "    [!] $w" -ForegroundColor Yellow }
            Write-Host ''
            $cont = (Read-Host '  -> Tiep tuc du co canh bao? [Y/N]').Trim().ToUpperInvariant()
            if ($cont -ne 'Y') { return }
        }
    }

    # Build plan
    $plan = New-Object System.Collections.Generic.List[object]
    foreach ($id in $Ids) {
        $comp = @($components | Where-Object { [string]$_.id -eq [string]$id }) | Select-Object -First 1
        if ($null -ne $comp) { [void]$plan.Add($comp) }
    }

    # Confirmation table
    Show-Header -SubTitle 'Ke Hoach & Xac Nhan Cai Dat'
    Write-Host "  Danh sach $($plan.Count) goi da chon:" -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  +--------------------------------+-------------------------------+' -ForegroundColor DarkCyan
    Write-Host '  | TEN THANH PHAN                 | TRANG THAI DU KIEN            |' -ForegroundColor White
    Write-Host '  +--------------------------------+-------------------------------+' -ForegroundColor DarkCyan
    foreach ($comp in $plan) {
        $nPad = $comp.name.PadRight(30)
        $installed = Test-ComponentInstalled ([string]$comp.id)
        $sStr  = if ($installed) { '  BO QUA (Da co san)           ' } else { '-> CAI DAT MOI                 ' }
        $sCol  = if ($installed) { 'DarkGray' } else { 'Green' }
        Write-Host '  | ' -NoNewline -ForegroundColor DarkCyan
        Write-Host $nPad -NoNewline -ForegroundColor White
        Write-Host ' | ' -NoNewline -ForegroundColor DarkCyan
        Write-Host $sStr -NoNewline -ForegroundColor $sCol
        Write-Host '|' -ForegroundColor DarkCyan
    }
    Write-Host '  +--------------------------------+-------------------------------+' -ForegroundColor DarkCyan
    Write-Host ''

    $confirm = (Read-Host '  -> Ban co chac chan muon tien hanh cai dat? [Y/N]').Trim().ToUpperInvariant()
    if ($confirm -ne 'Y') { return }

    # Create log file
    $logFile = New-DevKitLogFile
    Write-DevKitLog "Installation started. Plan: $($plan | ForEach-Object { $_.id } | Join-String -Separator ', ')" -LogFile $logFile

    $total  = $plan.Count
    $index  = 0
    $ok     = 0
    $skip   = 0
    $fail   = 0

    Show-Header -SubTitle 'Tien Trinh Cai Dat Thoi Gian Thuc'

    foreach ($comp in $plan) {
        $index++
        $id         = [string]$comp.id
        $name       = [string]$comp.name
        $scriptName = [string]$comp.script
        $scriptPath = Join-Path $Root (Join-Path 'scripts' $scriptName)

        Write-Host ''
        Draw-ProgressBar -Current ($index - 1) -Total $total -ItemName $name
        Write-Host '  ------------------------------------------------------------------------' -ForegroundColor DarkGray
        Write-Host "  [$index/$total] Xu ly: $name" -ForegroundColor Cyan
        Write-DevKitLog "[$index/$total] Processing: $name ($id)" -LogFile $logFile

        if (Test-ComponentInstalled $id) {
            Write-Host '  -> [BO QUA] Thanh phan da duoc cai dat san.' -ForegroundColor DarkGray
            Write-DevKitLog "  [SKIP] Already installed." -LogFile $logFile
            $skip++
            continue
        }

        if (-not (Test-Path $scriptPath)) {
            Write-Host "  [LOI] Khong tim thay script cai dat: $scriptPath" -ForegroundColor Red
            Write-DevKitLog "  [ERROR] Script not found: $scriptPath" -LogFile $logFile
            $fail++
            continue
        }

        try {
            Write-Host "  -> Dang thuc thi: $scriptName..." -ForegroundColor DarkCyan
            $global:LASTEXITCODE = 0
            & $scriptPath

            # Refresh PATH so verification is reliable immediately
            Update-SessionPath

            if (Test-ComponentInstalled $id) {
                Write-Host "  [THANH CONG] Da cai dat va kiem tra hoan tat: $name" -ForegroundColor Green
                Write-DevKitLog "  [OK] $name installed and verified." -LogFile $logFile
                $ok++
            } else {
                Write-Host "  [CANH BAO] Script da chay xong nhung chua phat hien: $name" -ForegroundColor Yellow
                Write-Host '             (Khuyen nghi khoi dong lai terminal hoac VS Code de nhan PATH moi.)' -ForegroundColor DarkGray
                Write-DevKitLog "  [WARN] Script finished but not yet detectable." -LogFile $logFile
                $fail++
            }
        }
        catch {
            Write-Host "  [LOI] $($_.Exception.Message)" -ForegroundColor Red
            Write-DevKitLog "  [ERROR] $($_.Exception.Message)" -LogFile $logFile
            $fail++
        }
    }

    # Final progress = 100%
    Write-Host ''
    Draw-ProgressBar -Current $total -Total $total -ItemName 'Hoan thanh toan bo!'
    Write-Host ''
    Write-Host '  ========================================================================' -ForegroundColor Cyan
    Write-Host '                             KET QUA CAI DAT                              ' -ForegroundColor White
    Write-Host '  ========================================================================' -ForegroundColor DarkCyan
    Write-Host ("  * Da cai moi thanh cong:    {0,-40}" -f "$ok goi") -ForegroundColor Green
    Write-Host ("  * Bo qua (da co san):       {0,-40}" -f "$skip goi") -ForegroundColor DarkGray
    Write-Host ("  * Loi / Chua san sang:      {0,-40}" -f "$fail goi") -ForegroundColor $(if ($fail -eq 0) { 'DarkGray' } else { 'Red' })
    Write-Host "  * Nhat ky cai dat (Log):    $logFile" -ForegroundColor DarkGray
    Write-Host '  ========================================================================' -ForegroundColor Cyan

    $deployedDir = Join-Path ([System.Environment]::GetFolderPath('MyDocuments')) 'StudentDevKit\cpp-template'
    if (Test-Path $deployedDir) {
        Write-Host ''
        Write-Host "  Thu muc du an mau san sang tai: $deployedDir" -ForegroundColor Cyan
    }

    Wait-Menu
}

# ---- STUDENT GUIDE ----

function Show-StudentGuide {
    Show-Header -SubTitle 'Huong Dan Nhanh Danh Cho Sinh Vien'
    
    Write-Host '  +-- [ 1. CACH VIET VA CHAY MA C/C++ TRONG VS CODE ] --------------------+' -ForegroundColor DarkCyan
    Write-Host '  |                                                                        |' -ForegroundColor DarkCyan
    Write-Host '  |  * Buoc 1: Mo Visual Studio Code.                                      |' -ForegroundColor White
    Write-Host '  |  * Buoc 2: Vao File -> Open Folder -> Chon thu muc du an mau:          |' -ForegroundColor White
    Write-Host '  |            Documents\StudentDevKit\cpp-template                        |' -ForegroundColor Cyan
    Write-Host '  |  * Buoc 3: Mo file main.cpp hoac tao file .cpp moi.                    |' -ForegroundColor White
    Write-Host '  |  * Buoc 4: Nhan nut Run (hinh tam giac Play o goc phai tren)           |' -ForegroundColor White
    Write-Host '  |            hoac nhan to hop phim: Ctrl + Alt + N (Code Runner).        |' -ForegroundColor Yellow
    Write-Host '  |  * Buoc 5: Xem ket qua in ra ngay o tab Output / Terminal ben duoi.    |' -ForegroundColor White
    Write-Host '  |                                                                        |' -ForegroundColor DarkCyan
    Write-Host '  +------------------------------------------------------------------------+' -ForegroundColor DarkCyan
    Write-Host ''
    Write-Host '  +-- [ 2. CACH DEBUG TUNG DONG VOI GDB ] ---------------------------------+' -ForegroundColor DarkCyan
    Write-Host '  |                                                                        |' -ForegroundColor DarkCyan
    Write-Host '  |  * Dat Breakpoint bang cach click chuot vao mep trai dong code.        |' -ForegroundColor White
    Write-Host '  |  * Nhan phim F5 de bat dau Debug.                                      |' -ForegroundColor Yellow
    Write-Host '  |  * Dung F10 de buoc qua dong tiep theo, F11 de nhay vao trong ham.     |' -ForegroundColor White
    Write-Host '  |                                                                        |' -ForegroundColor DarkCyan
    Write-Host '  +------------------------------------------------------------------------+' -ForegroundColor DarkCyan
    Write-Host ''
    Write-Host '  +-- [ 3. LUU Y QUAN TRONG ] ---------------------------------------------+' -ForegroundColor Yellow
    Write-Host '  |                                                                        |' -ForegroundColor Yellow
    Write-Host '  |  * Neu ban da mo VS Code tu truoc, hay khoi dong lai VS Code           |' -ForegroundColor White
    Write-Host '  |    de nap day du bien moi truong PATH moi.                             |' -ForegroundColor White
    Write-Host '  |  * Khi go code C++, hay go chu "main" roi nhan Tab de tu dong          |' -ForegroundColor White
    Write-Host '  |    chen cau truc ham main chuan (C++ Snippet sinh vien).               |' -ForegroundColor White
    Write-Host '  |                                                                        |' -ForegroundColor Yellow
    Write-Host '  +------------------------------------------------------------------------+' -ForegroundColor Yellow

    Wait-Menu
}

# ---- SELF-TEST ----

function Test-ProjectIntegrity {
    $errors = New-Object System.Collections.Generic.List[string]

    foreach ($comp in $components) {
        $sp = Join-Path $Root (Join-Path 'scripts' ([string]$comp.script))
        if (-not (Test-Path $sp)) { [void]$errors.Add("Missing script: $($comp.script)") }
    }

    foreach ($prop in @($config.wingetPackages.PSObject.Properties)) {
        $val = [string]$prop.Value
        if ([string]::IsNullOrWhiteSpace($val)) {
            [void]$errors.Add("Blank winget package id for '$($prop.Name)'")
        }
        $blocked = @('install','uninstall','upgrade','list','show','search')
        if ($blocked -contains $val.Trim().ToLowerInvariant()) {
            [void]$errors.Add("Dangerous winget package id '$val' for '$($prop.Name)'")
        }
    }

    $commonPath = Join-Path $Root 'scripts\common.ps1'
    if (Test-Path $commonPath) {
        $common = Get-Content $commonPath -Raw
        if ($common -match 'winget\s+install\s+\$') {
            [void]$errors.Add('Unsafe legacy winget invocation pattern found in common.ps1')
        }
    }

    $detectPath = Join-Path $Root 'scripts\detect.ps1'
    if (-not (Test-Path $detectPath)) {
        [void]$errors.Add('Missing required module: scripts\detect.ps1')
    }

    if ($errors.Count -eq 0) {
        Write-Host ''
        Write-Host '  [OK] Tat ca kiem tra toan ven da vuot qua.' -ForegroundColor Green
        Write-Host '  * Tat ca script cai dat ton tai day du.' -ForegroundColor Green
        Write-Host '  * Danh muc Winget package ID an toan.' -ForegroundColor Green
        Write-Host '  * Module detect.ps1 hien dien.' -ForegroundColor Green
        Write-Host '  * Khong phat hien lenh winget nguy hiem.' -ForegroundColor Green
        Write-Host ''
        return $true
    }

    Write-Host ''
    foreach ($e in $errors) { Write-Host "  [X] $e" -ForegroundColor Red }
    Write-Host ''
    return $false
}

if ($SelfTest) {
    $ok = Test-ProjectIntegrity
    if ($ok) { exit 0 } else { exit 1 }
}

# ---- MAIN MENU LOOP ----

while ($true) {
    Show-Header -SubTitle 'Menu Chuc Nang'

    Write-Host '  +--- DANH MUC CHUC NANG -------------------------------------------------+' -ForegroundColor DarkCyan
    Write-Host '  |                                                                        |' -ForegroundColor DarkCyan
    Write-Host '  |  [1] * CAI DAT DE XUAT   - Goi chuan sinh vien (VS Code, C/C++...)     |' -ForegroundColor White
    Write-Host '  |  [2]   TUY CHON GOI      - Bat/Tat tung cong cu theo y muon            |' -ForegroundColor White
    Write-Host '  |  [3]   CAI DAT TAT CA    - Cai toan bo 14 cong cu lap trinh            |' -ForegroundColor White
    Write-Host '  |  [4]   KIEM TRA MAY      - Quet cong cu, bien dich thu C/C++ (hello.c) |' -ForegroundColor White
    Write-Host '  |  [5]   HUONG DAN DUNG    - Cach viet, chay & debug code trong VS Code  |' -ForegroundColor White
    Write-Host '  |  [6]   KIEM TRA BO CAI   - Self-Test kiem tra toan ven bo cai dat      |' -ForegroundColor White
    Write-Host '  |                                                                        |' -ForegroundColor DarkCyan
    Write-Host '  |  [Q]   THOAT             - Dong chuong trinh                           |' -ForegroundColor Red
    Write-Host '  |                                                                        |' -ForegroundColor DarkCyan
    Write-Host '  +------------------------------------------------------------------------+' -ForegroundColor DarkCyan
    Write-Host ''

    $choice = (Read-Host '  -> Nhap lua chon cua ban').Trim().ToUpperInvariant()

    switch ($choice) {
        '1' { $ids = Get-SelectedComponents -Mode recommended; if ($null -ne $ids) { Invoke-InstallPlan -Ids $ids } }
        '2' { $ids = Get-SelectedComponents -Mode custom;      if ($null -ne $ids) { Invoke-InstallPlan -Ids $ids } }
        '3' { $ids = Get-SelectedComponents -Mode all;         if ($null -ne $ids) { Invoke-InstallPlan -Ids $ids } }
        '4' {
            Show-Header -SubTitle 'Kiem Tra He Thong & Compile Test'
            & (Join-Path $Root 'scripts\verify.ps1')
            Wait-Menu
        }
        '5' {
            Show-StudentGuide
        }
        '6' {
            Show-Header -SubTitle 'Self-Test: Kiem Tra Toan Ven Bo Cai Dat'
            [void](Test-ProjectIntegrity)
            Wait-Menu
        }
        'Q' {
            Write-Host ''
            Write-Host '  Cam on ban da su dung StudentDevKit! Chuc ban hoc tap tot.' -ForegroundColor Green
            Write-Host ''
            exit 0
        }
        default {
            Write-Host "  [X] Khong nhan ra lua chon: $choice" -ForegroundColor Red
            Start-Sleep -Milliseconds 500
        }
    }
}
