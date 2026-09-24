#requires -Version 5.1
# scripts/gui.ps1 — StudentDevKit WPF GUI (Dark Theme)
# Installer runs in a background PowerShell Runspace so the UI never freezes.
# Compatible: PowerShell 5.1+, .NET Framework 4.5+

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Root = if ($PSScriptRoot) { Split-Path -Parent $PSScriptRoot } else { (Get-Location).Path }
Set-Location $Root

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Drawing, System.Windows.Forms

# Load single-source detection module
. (Join-Path $PSScriptRoot 'detect.ps1')

$configPath = Join-Path $Root 'config\components.json'
$config     = Get-Content $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
$components = @($config.components)

$detectScriptPath = Join-Path $PSScriptRoot 'detect.ps1'

# ---- WPF HELPERS ----

function Get-Brush {
    param([string]$HexColor)
    [System.Windows.Media.BrushConverter]::new().ConvertFromString($HexColor)
}

function Test-IsAdmin {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ---- XAML ----
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="StudentDevKit v0.5.0 — Trình Cài Đặt Môi Trường Lập Trình"
        Height="800" Width="1080" MinHeight="640" MinWidth="900"
        WindowStartupLocation="CenterScreen"
        Background="#181825" Foreground="#cdd6f4"
        FontFamily="Segoe UI, Tahoma, Arial">

    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#313244"/>
            <Setter Property="Foreground" Value="#cdd6f4"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#45475a"/>
            <Setter Property="Padding" Value="14,8"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border"
                                Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                CornerRadius="6" SnapsToDevicePixels="True">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"
                                              Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="BorderBrush" Value="#89b4fa"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="border" Property="Opacity" Value="0.4"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="TabItem">
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Foreground" Value="#a6adc8"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Padding" Value="16,9"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border x:Name="tabBorder" Background="{TemplateBinding Background}"
                                BorderBrush="Transparent" BorderThickness="0,0,0,3"
                                Margin="0,0,8,0" Padding="{TemplateBinding Padding}">
                            <ContentPresenter ContentSource="Header"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="tabBorder" Property="BorderBrush" Value="#89b4fa"/>
                                <Setter Property="Foreground" Value="#89b4fa"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Foreground" Value="#ffffff"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="18,14,18,14">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>   <!-- Header -->
            <RowDefinition Height="Auto"/>   <!-- Toolbar -->
            <RowDefinition Height="*"/>      <!-- Tabs -->
            <RowDefinition Height="Auto"/>   <!-- Current step -->
            <RowDefinition Height="Auto"/>   <!-- Progress + Log -->
            <RowDefinition Height="Auto"/>   <!-- Footer -->
        </Grid.RowDefinitions>

        <!-- HEADER -->
        <Border Grid.Row="0" Background="#1e1e2e" CornerRadius="10" Padding="16,12"
                Margin="0,0,0,12" BorderBrush="#313244" BorderThickness="1">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
                        <TextBlock Text="StudentDevKit" FontSize="22" FontWeight="Bold" Foreground="#89b4fa" VerticalAlignment="Center"/>
                        <Border Background="#313244" CornerRadius="4" Padding="6,2" Margin="10,0,0,0" VerticalAlignment="Center">
                            <TextBlock Text="v0.5.0" FontSize="11" FontWeight="Bold" Foreground="#fab387"/>
                        </Border>
                        <Border Background="#233544" CornerRadius="4" Padding="6,2" Margin="8,0,0,0" VerticalAlignment="Center">
                            <TextBlock Text="MinGW-w64 UCRT64" FontSize="11" FontWeight="Bold" Foreground="#89dceb"/>
                        </Border>
                    </StackPanel>
                    <TextBlock Text="Bộ công cụ lập trình C/C++ chuẩn hóa cho Sinh viên — Installer chạy nền, giao diện không bị đóng băng"
                               FontSize="12" Foreground="#a6adc8" Margin="0,4,0,0"/>
                </StackPanel>
                <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                    <Border Name="badgeAdmin" Background="#1e3a2f" BorderBrush="#22c55e"
                            BorderThickness="1" CornerRadius="6" Padding="10,6">
                        <TextBlock Name="txtAdminStatus" Text="Quyền Administrator: HỢP LỆ"
                                   FontSize="12" FontWeight="Bold" Foreground="#a6e3a1"/>
                    </Border>
                </StackPanel>
            </Grid>
        </Border>

        <!-- TOOLBAR -->
        <Border Grid.Row="1" Background="#1e1e2e" CornerRadius="8" Padding="12,9"
                Margin="0,0,0,10" BorderBrush="#313244" BorderThickness="1">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0" Orientation="Horizontal">
                    <Button Name="btnSelectRecommended" Background="#89b4fa" Foreground="#11111b"
                            FontWeight="Bold" Margin="0,0,8,0">
                        <TextBlock Text="⭐ Chọn Đề Xuất"/>
                    </Button>
                    <Button Name="btnSelectAll" Margin="0,0,8,0">
                        <TextBlock Text="Chọn Tất Cả"/>
                    </Button>
                    <Button Name="btnClearAll" Margin="0,0,8,0">
                        <TextBlock Text="Bỏ Chọn Hết"/>
                    </Button>
                    <Button Name="btnRefreshStatus">
                        <TextBlock Text="🔄 Làm Mới"/>
                    </Button>
                </StackPanel>
                <StackPanel Grid.Column="2" Orientation="Horizontal" VerticalAlignment="Center">
                    <TextBlock Name="txtStatsSelected" Text="Đã chọn: 0/14"
                               FontSize="13" FontWeight="Bold" Foreground="#89b4fa"
                               VerticalAlignment="Center" Margin="0,0,16,0"/>
                    <TextBlock Name="txtStatsInstalled" Text="Đã có sẵn: 0"
                               FontSize="13" Foreground="#a6e3a1" VerticalAlignment="Center"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- TABS -->
        <TabControl Grid.Row="2" Background="Transparent" BorderThickness="0" Margin="0,0,0,10">
            <!-- TAB 1: Components -->
            <TabItem Header="Danh Sách Gói Cài Đặt">
                <Border Background="#1e1e2e" CornerRadius="8" BorderBrush="#313244"
                        BorderThickness="1" Margin="0,6,0,0" Padding="10">
                    <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                        <StackPanel Name="panelComponentsList"/>
                    </ScrollViewer>
                </Border>
            </TabItem>
            <!-- TAB 2: System Check -->
            <TabItem Header="Kiểm Tra Hệ Thống">
                <Border Background="#1e1e2e" CornerRadius="8" BorderBrush="#313244"
                        BorderThickness="1" Margin="0,6,0,0" Padding="14">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <StackPanel Name="panelSystemCheckList"/>
                    </ScrollViewer>
                </Border>
            </TabItem>
            <!-- TAB 3: Guide -->
            <TabItem Header="Hướng Dẫn Sinh Viên">
                <Border Background="#1e1e2e" CornerRadius="8" BorderBrush="#313244"
                        BorderThickness="1" Margin="0,6,0,0" Padding="18">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <StackPanel>
                            <TextBlock Text="BẮT ĐẦU VỚI STUDENT DEVKIT" FontSize="17" FontWeight="Bold" Foreground="#89b4fa" Margin="0,0,0,10"/>
                            <Border Background="#28283d" CornerRadius="6" Padding="12" Margin="0,0,0,10">
                                <StackPanel>
                                    <TextBlock Text="1. Gói Đề Xuất gồm những gì?" FontSize="13" FontWeight="Bold" Foreground="#f9e2af"/>
                                    <TextBlock FontSize="12" Foreground="#cdd6f4" TextWrapping="Wrap" Margin="0,5,0,0"
                                               Text="• VS Code + Extension C/C++, Code Runner&#x0a;• Git for Windows&#x0a;• GCC/G++ và GDB qua MSYS2 UCRT64&#x0a;• Cấu hình Settings.json + Snippets gõ nhanh&#x0a;• Thư mục Template C++ mẫu"/>
                                </StackPanel>
                            </Border>
                            <Border Background="#28283d" CornerRadius="6" Padding="12" Margin="0,0,0,10">
                                <StackPanel>
                                    <TextBlock Text="2. Chạy code C/C++ sau khi cài:" FontSize="13" FontWeight="Bold" Foreground="#f9e2af"/>
                                    <TextBlock FontSize="12" Foreground="#cdd6f4" TextWrapping="Wrap" Margin="0,5,0,0"
                                               Text="• Mở VS Code → File → Open Folder → chọn thư mục code&#x0a;• Mở file .cpp → nhấn Ctrl+Alt+N (Code Runner) để chạy&#x0a;• Nhấn F5 để debug từng bước với GDB"/>
                                </StackPanel>
                            </Border>
                            <Border Background="#28283d" CornerRadius="6" Padding="12">
                                <StackPanel>
                                    <TextBlock Text="3. Lưu ý:" FontSize="13" FontWeight="Bold" Foreground="#fab387"/>
                                    <TextBlock FontSize="12" Foreground="#cdd6f4" TextWrapping="Wrap" Margin="0,5,0,0"
                                               Text="• Installer chạy ở nền — giao diện không bị đóng băng khi cài MSYS2.&#x0a;• Nếu lệnh gcc chưa nhận trong VS Code terminal: restart VS Code để nạp PATH mới.&#x0a;• Log cài đặt lưu tại: %APPDATA%\StudentDevKit\logs\"/>
                                </StackPanel>
                            </Border>
                        </StackPanel>
                    </ScrollViewer>
                </Border>
            </TabItem>
        </TabControl>

        <!-- CURRENT STEP STATUS -->
        <Border Grid.Row="3" Background="#1e1e2e" CornerRadius="6" Padding="10,7"
                Margin="0,0,0,8" BorderBrush="#313244" BorderThickness="1">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0" Text="Bước: " FontSize="12" Foreground="#6c7086" VerticalAlignment="Center"/>
                <TextBlock Name="txtCurrentStep" Grid.Column="1" Text="Sẵn sàng."
                           FontSize="12" Foreground="#cdd6f4" VerticalAlignment="Center"/>
                <TextBlock Grid.Column="2" Name="txtCountOK"   Text="✔ 0" FontSize="12" FontWeight="Bold" Foreground="#a6e3a1" VerticalAlignment="Center" Margin="16,0,0,0"/>
                <TextBlock Grid.Column="3" Name="txtCountSkip" Text="○ 0" FontSize="12" FontWeight="Bold" Foreground="#6c7086" VerticalAlignment="Center" Margin="12,0,0,0"/>
                <TextBlock Grid.Column="4" Name="txtCountFail" Text="✖ 0" FontSize="12" FontWeight="Bold" Foreground="#f38ba8" VerticalAlignment="Center" Margin="12,0,0,0"/>
            </Grid>
        </Border>

        <!-- PROGRESS + LOG -->
        <Grid Grid.Row="4" Margin="0,0,0,10">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="120"/>
            </Grid.RowDefinitions>
            <Grid Grid.Row="0" Margin="0,0,0,6">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <ProgressBar Name="progBar" Height="9" Value="0" Maximum="100"
                             Background="#313244" Foreground="#89b4fa" BorderThickness="0"/>
                <TextBlock Name="txtProgressPct" Grid.Column="1" Text="0%"
                           FontSize="13" FontWeight="Bold" Foreground="#89b4fa"
                           VerticalAlignment="Center" Margin="10,0,0,0"/>
            </Grid>
            <Border Grid.Row="1" Background="#11111b" CornerRadius="6"
                    BorderBrush="#313244" BorderThickness="1" Padding="8,6">
                <TextBox Name="txtLiveLog" Background="Transparent" Foreground="#a6e3a1"
                         FontFamily="Consolas, Courier New" FontSize="11"
                         BorderThickness="0" IsReadOnly="True" TextWrapping="Wrap"
                         VerticalScrollBarVisibility="Auto"/>
            </Border>
        </Grid>

        <!-- FOOTER -->
        <Border Grid.Row="5" Background="#1e1e2e" CornerRadius="8" Padding="12,9"
                BorderBrush="#313244" BorderThickness="1">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0" Text="Dành cho sinh viên ngành CNTT và Kỹ thuật phần mềm"
                           FontSize="11" Foreground="#6c7086" VerticalAlignment="Center"/>
                <StackPanel Grid.Column="1" Orientation="Horizontal">
                    <Button Name="btnStartInstall" Background="#22c55e" Foreground="#ffffff"
                            FontWeight="Bold" FontSize="14" Padding="22,10" Margin="0,0,10,0">
                        <TextBlock Text="BẮT ĐẦU CÀI ĐẶT"/>
                    </Button>
                    <Button Name="btnExit" Background="#313244" Foreground="#cdd6f4" Padding="16,10">
                        <TextBlock Text="Thoát"/>
                    </Button>
                </StackPanel>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# ---- MAP NAMED ELEMENTS ----
$panelComponentsList  = $window.FindName('panelComponentsList')
$panelSystemCheckList = $window.FindName('panelSystemCheckList')
$btnSelectRecommended = $window.FindName('btnSelectRecommended')
$btnSelectAll         = $window.FindName('btnSelectAll')
$btnClearAll          = $window.FindName('btnClearAll')
$btnRefreshStatus     = $window.FindName('btnRefreshStatus')
$btnStartInstall      = $window.FindName('btnStartInstall')
$btnExit              = $window.FindName('btnExit')
$txtStatsSelected     = $window.FindName('txtStatsSelected')
$txtStatsInstalled    = $window.FindName('txtStatsInstalled')
$txtCurrentStep       = $window.FindName('txtCurrentStep')
$txtCountOK           = $window.FindName('txtCountOK')
$txtCountSkip         = $window.FindName('txtCountSkip')
$txtCountFail         = $window.FindName('txtCountFail')
$progBar              = $window.FindName('progBar')
$txtProgressPct       = $window.FindName('txtProgressPct')
$txtLiveLog           = $window.FindName('txtLiveLog')
$txtAdminStatus       = $window.FindName('txtAdminStatus')
$badgeAdmin           = $window.FindName('badgeAdmin')

# Admin badge
if (-not (Test-IsAdmin)) {
    $txtAdminStatus.Text       = 'Cảnh báo: Cần quyền Administrator để cài đặt đầy đủ!'
    $txtAdminStatus.Foreground = Get-Brush '#fab387'
    $badgeAdmin.Background     = Get-Brush '#3a2a1e'
    $badgeAdmin.BorderBrush    = Get-Brush '#fab387'
}

# ---- COMPONENT STATE ----
$checkboxMap    = @{}    # id -> CheckBox
$statusBadgeMap = @{}    # id -> TextBlock

function Write-GuiLog {
    param([string]$Message)
    $window.Dispatcher.Invoke([Action]{
        $ts = (Get-Date).ToString('HH:mm:ss')
        $txtLiveLog.AppendText("[$ts] $Message`r`n")
        $txtLiveLog.ScrollToEnd()
    }, [System.Windows.Threading.DispatcherPriority]::Background)
}

function Update-SelectionStats {
    $selCount  = ($checkboxMap.Values | Where-Object { $_.IsChecked -eq $true }).Count
    $instCount = ($components | Where-Object { Test-ComponentInstalled ([string]$_.id) }).Count
    $txtStatsSelected.Text  = "Đã chọn: $selCount/$($components.Count)"
    $txtStatsInstalled.Text = "Đã có sẵn: $instCount"
}

function Set-ButtonsEnabled {
    param([bool]$Enabled)
    $btnStartInstall.IsEnabled      = $Enabled
    $btnSelectRecommended.IsEnabled = $Enabled
    $btnSelectAll.IsEnabled         = $Enabled
    $btnClearAll.IsEnabled          = $Enabled
    $btnRefreshStatus.IsEnabled     = $Enabled
}

# ---- RENDER COMPONENT CARDS ----

function Render-ComponentCards {
    $panelComponentsList.Children.Clear()
    $script:checkboxMap.Clear()
    $script:statusBadgeMap.Clear()

    $catGroups = $components | Group-Object category

    $catColors = @{
        'Editor'   = '#89b4fa'
        'Core'     = '#fab387'
        'C/C++'    = '#a6e3a1'
        'Build'    = '#f9e2af'
        'Language' = '#cba6f7'
        'VS Code'  = '#89dceb'
        'Project'  = '#f38ba8'
    }

    foreach ($group in $catGroups) {
        $catKey   = [string]$group.Name
        $catColor = if ($catColors.ContainsKey($catKey)) { $catColors[$catKey] } else { '#a6adc8' }

        # Category header
        $hdrBorder = New-Object System.Windows.Controls.Border
        $hdrBorder.Background   = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#28283d')
        $hdrBorder.CornerRadius = [System.Windows.CornerRadius]::new(6)
        $hdrBorder.Padding      = [System.Windows.Thickness]::new(12, 6, 12, 6)
        $hdrBorder.Margin       = [System.Windows.Thickness]::new(0, 6, 0, 4)

        $hdrTxt = New-Object System.Windows.Controls.TextBlock
        $hdrTxt.Text       = $catKey.ToUpper()
        $hdrTxt.FontSize   = 11
        $hdrTxt.FontWeight = [System.Windows.FontWeights]::Bold
        $hdrTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($catColor)
        $hdrBorder.Child   = $hdrTxt
        [void]$panelComponentsList.Children.Add($hdrBorder)

        foreach ($comp in @($group.Group)) {
            $id          = [string]$comp.id
            $isInstalled = Test-ComponentInstalled $id

            # Card border
            $card = New-Object System.Windows.Controls.Border
            $card.Background     = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#252536')
            $card.CornerRadius   = [System.Windows.CornerRadius]::new(6)
            $card.Padding        = [System.Windows.Thickness]::new(12, 8, 12, 8)
            $card.Margin         = [System.Windows.Thickness]::new(0, 0, 0, 4)
            $card.BorderThickness= [System.Windows.Thickness]::new(1)
            $card.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#313244')

            $row = New-Object System.Windows.Controls.Grid
            $col1 = New-Object System.Windows.Controls.ColumnDefinition; $col1.Width = [System.Windows.GridLength]::Auto
            $col2 = New-Object System.Windows.Controls.ColumnDefinition; $col2.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
            $col3 = New-Object System.Windows.Controls.ColumnDefinition; $col3.Width = [System.Windows.GridLength]::Auto
            [void]$row.ColumnDefinitions.Add($col1)
            [void]$row.ColumnDefinitions.Add($col2)
            [void]$row.ColumnDefinitions.Add($col3)

            # Checkbox
            $chk = New-Object System.Windows.Controls.CheckBox
            $chk.IsChecked         = ($comp.recommended -and -not $isInstalled)
            $chk.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $chk.Margin            = [System.Windows.Thickness]::new(0, 0, 10, 0)
            $chk.Add_Checked({   Update-SelectionStats })
            $chk.Add_Unchecked({ Update-SelectionStats })
            [System.Windows.Controls.Grid]::SetColumn($chk, 0)
            [void]$row.Children.Add($chk)
            $script:checkboxMap[$id] = $chk

            # Name + Description
            $info = New-Object System.Windows.Controls.StackPanel
            $nameBlock = New-Object System.Windows.Controls.TextBlock
            $nameBlock.Text       = $comp.name
            $nameBlock.FontSize   = 13
            $nameBlock.FontWeight = [System.Windows.FontWeights]::SemiBold
            $nameBlock.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#cdd6f4')
            if ($comp.recommended) {
                $star = New-Object System.Windows.Documents.Run
                $star.Text       = '  ★'
                $star.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#f9e2af')
                $nameBlock.Inlines.Add($star)
            }
            [void]$info.Children.Add($nameBlock)

            if ($comp.description) {
                $descBlock = New-Object System.Windows.Controls.TextBlock
                $descBlock.Text        = [string]$comp.description
                $descBlock.FontSize    = 11
                $descBlock.Foreground  = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#6c7086')
                $descBlock.TextWrapping= [System.Windows.TextWrapping]::Wrap
                $descBlock.Margin      = [System.Windows.Thickness]::new(0, 2, 0, 0)
                [void]$info.Children.Add($descBlock)
            }
            [System.Windows.Controls.Grid]::SetColumn($info, 1)
            [void]$row.Children.Add($info)

            # Status badge
            $badge = New-Object System.Windows.Controls.Border
            $badge.CornerRadius = [System.Windows.CornerRadius]::new(4)
            $badge.Padding      = [System.Windows.Thickness]::new(8, 3, 8, 3)
            $badgeTxt = New-Object System.Windows.Controls.TextBlock
            $badgeTxt.FontSize   = 11
            $badgeTxt.FontWeight = [System.Windows.FontWeights]::Bold
            if ($isInstalled) {
                $badge.Background     = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#1e3a2f')
                $badge.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#22c55e')
                $badge.BorderThickness= [System.Windows.Thickness]::new(1)
                $badgeTxt.Text        = 'Installed'
                $badgeTxt.Foreground  = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#a6e3a1')
            } else {
                $badge.Background     = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#313244')
                $badge.BorderBrush    = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#45475a')
                $badge.BorderThickness= [System.Windows.Thickness]::new(1)
                $badgeTxt.Text        = 'Missing'
                $badgeTxt.Foreground  = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#6c7086')
            }
            $badge.Child = $badgeTxt
            $badge.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
            $badge.Margin = [System.Windows.Thickness]::new(12, 0, 0, 0)
            [System.Windows.Controls.Grid]::SetColumn($badge, 2)
            [void]$row.Children.Add($badge)
            $script:statusBadgeMap[$id] = $badge

            $card.Child = $row
            [void]$panelComponentsList.Children.Add($card)
        }
    }

    Update-SelectionStats
}

# ---- RENDER SYSTEM CHECK ----

function Render-SystemCheck {
    $panelSystemCheckList.Children.Clear()

    $msys2Root = Get-Msys2Root

    $checks = @(
        @{ Label = 'VS Code (code)';         Installed = (Test-ComponentInstalled 'vscode')  },
        @{ Label = 'Git (git)';              Installed = (Test-ComponentInstalled 'git')     },
        @{ Label = 'GCC + G++ (UCRT64)';    Installed = (Test-ComponentInstalled 'cpp-gcc') },
        @{ Label = 'GDB Debugger (UCRT64)'; Installed = (Test-ComponentInstalled 'cpp-gdb') },
        @{ Label = 'CMake';                  Installed = (Test-ComponentInstalled 'cmake')   },
        @{ Label = 'Ninja Build';            Installed = (Test-ComponentInstalled 'ninja')   },
        @{ Label = 'LLVM / Clang';           Installed = (Test-ComponentInstalled 'clang')   },
        @{ Label = 'Cppcheck';               Installed = (Test-ComponentInstalled 'cppcheck') },
        @{ Label = 'Python';                 Installed = (Test-ComponentInstalled 'python')  },
        @{ Label = 'Node.js';                Installed = (Test-ComponentInstalled 'node')    },
        @{ Label = 'VS Code Extensions';     Installed = (Test-ComponentInstalled 'vscode-ext') },
        @{ Label = 'VS Code Settings';       Installed = (Test-ComponentInstalled 'settings')},
        @{ Label = 'C++ Snippets';           Installed = (Test-ComponentInstalled 'snippets') },
        @{ Label = 'C++ Template';           Installed = (Test-ComponentInstalled 'template') }
    )

    $titleTxt = New-Object System.Windows.Controls.TextBlock
    $titleTxt.Text       = "MSYS2 root: $msys2Root"
    $titleTxt.FontSize   = 11
    $titleTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#89dceb')
    $titleTxt.Margin     = [System.Windows.Thickness]::new(0, 0, 0, 8)
    [void]$panelSystemCheckList.Children.Add($titleTxt)

    foreach ($chk in $checks) {
        $row = New-Object System.Windows.Controls.Grid
        $c1 = New-Object System.Windows.Controls.ColumnDefinition; $c1.Width = [System.Windows.GridLength]::new(20)
        $c2 = New-Object System.Windows.Controls.ColumnDefinition; $c2.Width = [System.Windows.GridLength]::new(1, [System.Windows.GridUnitType]::Star)
        [void]$row.ColumnDefinitions.Add($c1); [void]$row.ColumnDefinitions.Add($c2)
        $row.Margin = [System.Windows.Thickness]::new(0, 0, 0, 4)

        $iconTxt = New-Object System.Windows.Controls.TextBlock
        $iconTxt.FontSize   = 14
        $iconTxt.FontWeight = [System.Windows.FontWeights]::Bold
        $iconTxt.VerticalAlignment = [System.Windows.VerticalAlignment]::Center
        if ($chk.Installed) {
            $iconTxt.Text       = '✔'
            $iconTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#a6e3a1')
        } else {
            $iconTxt.Text       = '○'
            $iconTxt.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString('#45475a')
        }
        [System.Windows.Controls.Grid]::SetColumn($iconTxt, 0)
        [void]$row.Children.Add($iconTxt)

        $labelTxt = New-Object System.Windows.Controls.TextBlock
        $labelTxt.Text             = $chk.Label
        $labelTxt.FontSize         = 13
        $labelTxt.VerticalAlignment= [System.Windows.VerticalAlignment]::Center
        $labelTxt.Foreground       = if ($chk.Installed) {
            [System.Windows.Media.BrushConverter]::new().ConvertFromString('#cdd6f4')
        } else {
            [System.Windows.Media.BrushConverter]::new().ConvertFromString('#585b70')
        }
        [System.Windows.Controls.Grid]::SetColumn($labelTxt, 1)
        [void]$row.Children.Add($labelTxt)

        [void]$panelSystemCheckList.Children.Add($row)
    }
}

# ---- BUTTON EVENTS ----

$btnSelectRecommended.Add_Click({
    foreach ($kv in $script:checkboxMap.GetEnumerator()) {
        $id = $kv.Key
        $isInstalled = Test-ComponentInstalled $id
        $comp = $components | Where-Object { [string]$_.id -eq $id } | Select-Object -First 1
        $kv.Value.IsChecked = ($comp -and $comp.recommended -and (-not $isInstalled))
    }
    Update-SelectionStats
    Write-GuiLog 'Đã chọn các gói Đề Xuất chưa cài.'
})

$btnSelectAll.Add_Click({
    foreach ($chk in $script:checkboxMap.Values) { $chk.IsChecked = $true }
    Update-SelectionStats
    Write-GuiLog 'Đã chọn toàn bộ gói.'
})

$btnClearAll.Add_Click({
    foreach ($chk in $script:checkboxMap.Values) { $chk.IsChecked = $false }
    Update-SelectionStats
    Write-GuiLog 'Đã bỏ chọn toàn bộ.'
})

$btnRefreshStatus.Add_Click({
    Render-ComponentCards
    Render-SystemCheck
    Write-GuiLog 'Đã làm mới trạng thái.'
})

$btnExit.Add_Click({ $window.Close() })

# ---- INSTALL BUTTON: BACKGROUND RUNSPACE ----

$btnStartInstall.Add_Click({

    # Collect selected IDs
    $selectedIds = New-Object System.Collections.Generic.List[string]
    foreach ($kv in $script:checkboxMap.GetEnumerator()) {
        if ($kv.Value.IsChecked -eq $true) { [void]$selectedIds.Add($kv.Key) }
    }

    if ($selectedIds.Count -eq 0) {
        [System.Windows.MessageBox]::Show(
            "Bạn chưa chọn thành phần nào!`r`nNhấn 'Chọn Đề Xuất' để chọn nhanh.",
            'Thông Báo', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning
        )
        return
    }

    # Build plan array (plain PSCustomObject — serializable across runspace boundary)
    $planArray = @()
    foreach ($id in $selectedIds) {
        $comp = $components | Where-Object { [string]$_.id -eq $id } | Select-Object -First 1
        if ($comp) {
            $planArray += [PSCustomObject]@{
                id     = [string]$comp.id
                name   = [string]$comp.name
                script = [string]$comp.script
            }
        }
    }

    # Confirmation
    $confirmMsg = "Xác nhận cài đặt $($planArray.Count) gói?`r`n`r`n"
    foreach ($p in $planArray) {
        $already = Test-ComponentInstalled $p.id
        $note    = if ($already) { '(đã cài — sẽ bỏ qua)' } else { '(cài mới)' }
        $confirmMsg += " • $($p.name)  $note`r`n"
    }
    $res = [System.Windows.MessageBox]::Show(
        $confirmMsg, 'Xác Nhận Cài Đặt',
        [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question
    )
    if ($res -ne [System.Windows.MessageBoxResult]::Yes) { return }

    # Lock UI
    Set-ButtonsEnabled $false
    $progBar.Value = 0
    $txtProgressPct.Text = '0%'
    $txtCurrentStep.Text = 'Đang chuẩn bị...'
    $txtCountOK.Text     = '✔ 0'
    $txtCountSkip.Text   = '○ 0'
    $txtCountFail.Text   = '✖ 0'

    # Shared state (synchronized hashtable)
    $syncHash = [System.Collections.Hashtable]::Synchronized(@{
        Done         = $false
        Progress     = 0
        CurrentItem  = 'Đang chuẩn bị...'
        CurrentIndex = 0
        TotalItems   = $planArray.Count
        OKCount      = 0
        SkipCount    = 0
        FailCount    = 0
        # ConcurrentQueue for log lines
        LogQueue     = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
        LogFile      = ''
        Summary      = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    })

    # Capture closure variables for runspace
    $capturedRoot       = $Root
    $capturedDetect     = $detectScriptPath
    $capturedPlan       = $planArray

    # Create Runspace
    $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $runspace.ApartmentState = 'MTA'
    $runspace.ThreadOptions  = 'ReuseThread'
    $runspace.Open()

    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $runspace

    [void]$ps.AddScript({
        param($syncHash, $planItems, $Root, $detectScript)

        $ErrorActionPreference = 'Stop'

        # Load detect.ps1 into this runspace
        . $detectScript
        # Also load common.ps1 for installer scripts to dot-source properly
        # (they dot-source it themselves; we just need detect.ps1 for detection + path refresh)

        $total = $planItems.Count
        $syncHash.TotalItems = $total

        # Create log file
        $logDir = Join-Path $env:APPDATA 'StudentDevKit\logs'
        $null = New-Item $logDir -ItemType Directory -Force -ErrorAction SilentlyContinue
        $logFile = Join-Path $logDir ("install-{0}.log" -f (Get-Date -Format 'yyyyMMdd-HHmmss'))
        $syncHash.LogFile = $logFile
        $syncHash.LogQueue.Enqueue("[LOG] $logFile")

        function Append-Log([string]$msg) {
            $syncHash.LogQueue.Enqueue($msg)
            $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            Add-Content -Path $logFile -Value "[$ts] $msg" -Encoding UTF8 -ErrorAction SilentlyContinue
        }

        Append-Log "========== Installation Start =========="
        Append-Log "Plan: $($planItems | ForEach-Object { $_.id } | ForEach-Object { $_ } | Out-String)"

        $index = 0
        foreach ($comp in $planItems) {
            $index++
            $id         = [string]$comp.id
            $name       = [string]$comp.name
            $scriptPath = Join-Path $Root (Join-Path 'scripts' ([string]$comp.script))

            $syncHash.CurrentIndex = $index
            $syncHash.CurrentItem  = "[$index/$total] $name"
            $syncHash.Progress     = [int](($index - 1) * 100 / [Math]::Max(1, $total))

            Append-Log "[$index/$total] Processing: $name ($id)"

            if (Test-ComponentInstalled $id) {
                Append-Log "  [SKIP] Already installed."
                $syncHash.SkipCount++
                $syncHash.Summary.Enqueue("SKIP|$name")
                continue
            }

            if (-not (Test-Path $scriptPath)) {
                Append-Log "  [ERROR] Script not found: $scriptPath"
                $syncHash.FailCount++
                $syncHash.Summary.Enqueue("FAIL|$name|Script not found")
                continue
            }

            try {
                Append-Log "  -> Running: $($comp.script)"
                & $scriptPath *>&1 | ForEach-Object {
                    $line = $_.ToString().Trim()
                    if ($line) { Append-Log "     $line" }
                }

                # Refresh PATH so next Test-ComponentInstalled is reliable
                Update-SessionPath

                if ($LASTEXITCODE -ne 0) {
                    Append-Log "  [ERROR] Script exited $LASTEXITCODE"
                    $syncHash.FailCount++
                    $syncHash.Summary.Enqueue("FAIL|$name|Exit code $LASTEXITCODE")
                } elseif (Test-ComponentInstalled $id) {
                    Append-Log "  [OK] Installed and verified."
                    $syncHash.OKCount++
                    $syncHash.Summary.Enqueue("OK|$name")
                } else {
                    Append-Log "  [WARN] Script finished but not yet detectable. PATH refresh may need new terminal."
                    $syncHash.FailCount++
                    $syncHash.Summary.Enqueue("WARN|$name|Not detectable post-install")
                }
            } catch {
                Append-Log "  [EXCEPTION] $($_.Exception.Message)"
                $syncHash.FailCount++
                $syncHash.Summary.Enqueue("FAIL|$name|$($_.Exception.Message)")
            }
        }

        $syncHash.Progress    = 100
        $syncHash.CurrentItem = "Hoàn tất!"
        Append-Log "========== Installation Complete: OK=$($syncHash.OKCount) SKIP=$($syncHash.SkipCount) FAIL=$($syncHash.FailCount) =========="
        $syncHash.Done = $true

    }).AddArgument($syncHash).AddArgument($capturedPlan).AddArgument($capturedRoot).AddArgument($capturedDetect)

    $handle = $ps.BeginInvoke()

    Write-GuiLog '=========================================='
    Write-GuiLog "CÀI ĐẶT BẮT ĐẦU — $($planArray.Count) thành phần"
    Write-GuiLog 'Installer chạy ở nền — giao diện vẫn phản hồi bình thường.'
    Write-GuiLog '=========================================='

    # DispatcherTimer polls the shared queue every 150ms from UI thread
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(150)

    $timer.Add_Tick({
        # Drain log queue → TextBox
        $line = $null
        while ($syncHash.LogQueue.TryDequeue([ref]$line)) {
            $ts = (Get-Date).ToString('HH:mm:ss')
            $txtLiveLog.AppendText("[$ts] $line`r`n")
            $txtLiveLog.ScrollToEnd()
        }

        # Update progress
        $progBar.Value       = $syncHash.Progress
        $txtProgressPct.Text = "$($syncHash.Progress)%"
        $txtCurrentStep.Text = $syncHash.CurrentItem
        $txtCountOK.Text     = "✔ $($syncHash.OKCount)"
        $txtCountSkip.Text   = "○ $($syncHash.SkipCount)"
        $txtCountFail.Text   = "✖ $($syncHash.FailCount)"

        if ($syncHash.Done) {
            $timer.Stop()
            $progBar.Value       = 100
            $txtProgressPct.Text = '100%'

            # Flush remaining log
            $line = $null
            while ($syncHash.LogQueue.TryDequeue([ref]$line)) {
                $ts = (Get-Date).ToString('HH:mm:ss')
                $txtLiveLog.AppendText("[$ts] $line`r`n")
                $txtLiveLog.ScrollToEnd()
            }

            # Cleanup runspace
            try { [void]$ps.EndInvoke($handle) } catch {}
            $ps.Dispose()
            $runspace.Close()
            $runspace.Dispose()

            # Refresh component cards
            Render-ComponentCards
            Render-SystemCheck

            # Re-enable UI
            Set-ButtonsEnabled $true

            # Summary message
            $ok   = $syncHash.OKCount
            $skip = $syncHash.SkipCount
            $fail = $syncHash.FailCount
            $logF = $syncHash.LogFile

            $summaryLines = [System.Collections.Generic.List[string]]::new()
            $entry = $null
            while ($syncHash.Summary.TryDequeue([ref]$entry)) { [void]$summaryLines.Add($entry) }

            $msg  = "Cài đặt hoàn tất!`r`n`r`n"
            $msg += " ✔ Thành công:    $ok gói`r`n"
            $msg += " ○ Đã có sẵn:     $skip gói`r`n"
            $msg += " ✖ Lỗi/Chưa xong: $fail gói`r`n"
            if ($logF) { $msg += "`r`nLog: $logF" }
            $msg += "`r`n`r`nKhuyến nghị: Restart VS Code hoặc mở terminal mới để nạp PATH mới."

            $icon = if ($fail -eq 0) { [System.Windows.MessageBoxImage]::Information } `
                    else              { [System.Windows.MessageBoxImage]::Warning }
            [System.Windows.MessageBox]::Show($msg, 'Kết Quả Cài Đặt',
                [System.Windows.MessageBoxButton]::OK, $icon)
        }
    })
    $timer.Start()
})

# ---- INIT ----
Render-ComponentCards
Render-SystemCheck
Write-GuiLog "StudentDevKit GUI v0.5.0 sẵn sàng. MSYS2 root: $(Get-Msys2Root)"

$window.ShowDialog() | Out-Null
