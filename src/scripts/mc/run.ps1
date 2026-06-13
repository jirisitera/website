$ErrorActionPreference = "Stop"
function Write-LauncherStatus {
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host -ForegroundColor Cyan $Message
}
function Write-LauncherError {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [switch]$Exit
    )
    Write-Error $Message
    if ($Exit) {
        throw "Execution aborted."
    }
}
$rootDir = (Get-Location).Path
$opencraftDir = Join-Path $rootDir "Opencraft"
$downloadDir = Join-Path $opencraftDir "client"
$zipPath = Join-Path $downloadDir "pmc-latest.zip"
$extractDir = Join-Path $downloadDir ".extracted"
$exePath = Join-Path $extractDir "portablemc.exe"
if (-not (Test-Path -LiteralPath $opencraftDir -PathType Container)) {
    New-Item -ItemType Directory -Path $opencraftDir -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $downloadDir)) {
    New-Item -ItemType Directory -Path $downloadDir | Out-Null
}
if (-not (Test-Path -LiteralPath $exePath)) {
    try {
        Write-LauncherStatus "Resolving latest PortableMC Windows build..."
        $repo = "theorzr/portablemc"
        $url = "https://api.github.com/repos/$repo/releases/latest"
        $release = Invoke-RestMethod -Uri $url -Headers @{ "User-Agent" = "pmc-bootstrap" }
        $asset = $release.assets | Where-Object { $_.name -like "portablemc-*-windows-x86_64-msvc.zip" } | Select-Object -First 1
        if (-not $asset) {
            Write-LauncherError -Message "No Windows x86_64 asset found in latest release." -Exit
        }
        $assetUrl = $asset.browser_download_url
        Write-LauncherStatus "Downloading from: $assetUrl"
        Invoke-WebRequest -Uri $assetUrl -OutFile $zipPath
        if (Test-Path -LiteralPath $extractDir) {
            Remove-Item -LiteralPath $extractDir -Recurse -Force
        }
        New-Item -ItemType Directory -Path $extractDir | Out-Null
        Write-LauncherStatus "Extracting archive..."
        Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
        if (-not (Test-Path -LiteralPath $exePath)) {
            Write-LauncherError -Message "portablemc.exe was not found after extraction." -Exit
        }
        Write-LauncherStatus "Download successful!"
    } catch {
        Write-LauncherError -Message $_.Exception.Message -Exit
    }
}
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName System.Xaml
[xml]$xaml = @(
    '<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Minecraft Launcher" Width="480" Height="320" WindowStartupLocation="CenterScreen" ResizeMode="NoResize" Background="Transparent" Foreground="#1C1C1C" WindowStyle="None" AllowsTransparency="True" Opacity="1" UseLayoutRounding="True" SnapsToDevicePixels="True">'
    '    <Window.Resources>'
    '        <Style x:Key="ModernButton" TargetType="Button">'
    '            <Setter Property="Background" Value="#0078D4"/>'
    '            <Setter Property="Foreground" Value="White"/>'
    '            <Setter Property="FontWeight" Value="500"/>'
    '            <Setter Property="FontSize" Value="14"/>'
    '            <Setter Property="BorderThickness" Value="0"/>'
    '            <Setter Property="Cursor" Value="Hand"/>'
    '            <Setter Property="Padding" Value="16,8"/>'
    '            <Setter Property="Template">'
    '                <Setter.Value>'
    '                    <ControlTemplate TargetType="Button">'
    '                        <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">'
    '                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>'
    '                        </Border>'
    '                        <ControlTemplate.Triggers>'
    '                            <Trigger Property="IsMouseOver" Value="True">'
    '                                <Setter TargetName="border" Property="Background" Value="#1084D7"/>'
    '                            </Trigger>'
    '                            <Trigger Property="IsPressed" Value="True">'
    '                                <Setter TargetName="border" Property="Background" Value="#005A9E"/>'
    '                            </Trigger>'
    '                        </ControlTemplate.Triggers>'
    '                    </ControlTemplate>'
    '                </Setter.Value>'
    '            </Setter>'
    '        </Style>'
    '        <Style x:Key="SecondaryButton" TargetType="Button" BasedOn="{StaticResource ModernButton}">'
    '            <Setter Property="Background" Value="#fafafa"/>'
    '            <Setter Property="Foreground" Value="#1C1C1C"/>'
    '            <Setter Property="Template">'
    '                <Setter.Value>'
    '                    <ControlTemplate TargetType="Button">'
    '                        <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">'
    '                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>'
    '                        </Border>'
    '                        <ControlTemplate.Triggers>'
    '                            <Trigger Property="IsMouseOver" Value="True">'
    '                                <Setter TargetName="border" Property="Background" Value="#ffffff"/>'
    '                            </Trigger>'
    '                            <Trigger Property="IsPressed" Value="True">'
    '                                <Setter TargetName="border" Property="Background" Value="#ffffff"/>'
    '                            </Trigger>'
    '                        </ControlTemplate.Triggers>'
    '                    </ControlTemplate>'
    '                </Setter.Value>'
    '            </Setter>'
    '        </Style>'
    '        <Style x:Key="ModernTextBox" TargetType="TextBox">'
    '            <Setter Property="Background" Value="White"/>'
    '            <Setter Property="Foreground" Value="#1C1C1C"/>'
    '            <Setter Property="CaretBrush" Value="#0078D4"/>'
    '            <Setter Property="BorderThickness" Value="1"/>'
    '            <Setter Property="BorderBrush" Value="#D1D1D1"/>'
    '            <Setter Property="Padding" Value="14,12"/>'
    '            <Setter Property="FontSize" Value="16"/>'
    '            <Setter Property="VerticalContentAlignment" Value="Center"/>'
    '            <Setter Property="Template">'
    '                <Setter.Value>'
    '                    <ControlTemplate TargetType="TextBox">'
    '                        <Border x:Name="border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6" Padding="{TemplateBinding Padding}">'
    '                            <ScrollViewer x:Name="PART_ContentHost" VerticalAlignment="Center"/>'
    '                        </Border>'
    '                        <ControlTemplate.Triggers>'
    '                            <Trigger Property="IsFocused" Value="True">'
    '                                <Setter TargetName="border" Property="BorderBrush" Value="#0078D4"/>'
    '                                <Setter TargetName="border" Property="BorderThickness" Value="2"/>'
    '                            </Trigger>'
    '                        </ControlTemplate.Triggers>'
    '                    </ControlTemplate>'
    '                </Setter.Value>'
    '            </Setter>'
    '        </Style>'
    '    </Window.Resources>'
    '    <Border x:Name="RootShell" CornerRadius="28" ClipToBounds="True" Background="Transparent">'
    '        <Grid>'
    '            <Grid.Background>'
    '                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">'
    '                    <GradientStop Color="#FFBFD3E6" Offset="0"/>'
    '                    <GradientStop Color="#FFD8E7F4" Offset="0.55"/>'
    '                    <GradientStop Color="#FFC6DCEB" Offset="1"/>'
    '                </LinearGradientBrush>'
    '            </Grid.Background>'
    '            <Ellipse Width="220" Height="220" HorizontalAlignment="Left" VerticalAlignment="Top" Margin="-60,-85,0,0" Fill="#4DA6E3FF" IsHitTestVisible="False">'
    '                <Ellipse.Effect>'
    '                    <BlurEffect Radius="36"/>'
    '                </Ellipse.Effect>'
    '            </Ellipse>'
    '            <Ellipse Width="200" Height="200" HorizontalAlignment="Right" VerticalAlignment="Bottom" Margin="0,0,-45,-70" Fill="#4DB8FFD2" IsHitTestVisible="False">'
    '                <Ellipse.Effect>'
    '                    <BlurEffect Radius="34"/>'
    '                </Ellipse.Effect>'
    '            </Ellipse>'
    '            <Border HorizontalAlignment="Stretch" VerticalAlignment="Stretch" Margin="18" CornerRadius="18" BorderThickness="1" BorderBrush="#AAFFFFFF" Background="#80FFFFFF" Padding="16">'
    '                <Border.Effect>'
    '                    <DropShadowEffect BlurRadius="20" ShadowDepth="4" Opacity="0.18" Color="#334155"/>'
    '                </Border.Effect>'
    '                <Grid>'
    '                    <StackPanel VerticalAlignment="Center" HorizontalAlignment="Stretch" Margin="12,0,12,0">'
    '                        <TextBlock Text="Minecraft Launcher" FontSize="30" FontWeight="SemiBold" Foreground="#0F4C81" Margin="0,0,0,8"/>'
    '                        <TextBlock Text="Please enter your username:" FontSize="14" FontWeight="Normal" Margin="0,0,0,20" Foreground="#3F4A59"/>'
    '                        <TextBox x:Name="UsernameBox" Style="{StaticResource ModernTextBox}" Margin="0,0,0,18" MaxLength="16"/>'
    '                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">'
    '                            <Button x:Name="OkButton" Content="Launch" Width="118" Height="40" Style="{StaticResource ModernButton}" Margin="0,0,12,0"/>'
    '                            <Button x:Name="CancelButton" Content="Cancel" Width="118" Height="40" Style="{StaticResource SecondaryButton}" Margin="0"/>'
    '                        </StackPanel>'
    '                    </StackPanel>'
    '                </Grid>'
    '            </Border>'
    '        </Grid>'
    '    </Border>'
    '</Window>'
) -join [Environment]::NewLine
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)
$rootShell = $window.FindName("RootShell")
$usernameBox = $window.FindName("UsernameBox")
$okButton = $window.FindName("OkButton")
$cancelButton = $window.FindName("CancelButton")
$usernameBox.Add_PreviewTextInput({
    param($s, $e)
    if ($e.Text -notmatch "^[A-Za-z]+$") {
        $e.Handled = $true
    }
})
[System.Windows.DataObject]::AddPastingHandler($usernameBox, {
    param($s, $e)
    if ($e.DataObject.GetDataPresent([System.Windows.DataFormats]::Text)) {
        $pasteText = $e.DataObject.GetData([System.Windows.DataFormats]::Text)
        if ($pasteText -notmatch "^[A-Za-z]+$") {
            $e.CancelCommand()
        }
    } else {
        $e.CancelCommand()
    }
})
function Set-RoundedShellClip {
    param(
        [Parameter(Mandatory = $true)]$Shell,
        [double]$Radius = 28
    )
    $rect = New-Object System.Windows.Rect(0, 0, $Shell.ActualWidth, $Shell.ActualHeight)
    $Shell.Clip = New-Object System.Windows.Media.RectangleGeometry($rect, $Radius, $Radius)
}
$window.Add_SizeChanged({ Set-RoundedShellClip -Shell $rootShell })
$window.Add_ContentRendered({
    Set-RoundedShellClip -Shell $rootShell
    $window.Topmost = $true
    [void]$window.Activate()
    $window.Topmost = $false
    [void]$usernameBox.Focus()
    [void][System.Windows.Input.Keyboard]::Focus($usernameBox)
})
$state = @{ Ok = $false }
$okButton.Add_Click({
    $state.Ok = $true
    $window.Close()
})
$cancelButton.Add_Click({
    $state.Ok = $false
    $window.Close()
})
$usernameBox.Add_KeyDown({
    if ($_.Key -eq "Return") {
        $state.Ok = $true
        $window.Close()
    }
})
$window.ShowDialog() | Out-Null
if (-not $state.Ok) {
    Write-LauncherStatus "Name selection cancelled. Exiting launch sequence."
    return
}
$pmcUser = $usernameBox.Text
if ([string]::IsNullOrWhiteSpace($pmcUser)) {
    Write-LauncherStatus "No username specified, using randomly generated name instead..."
    $pmcUser = "player$((Get-Random -Minimum 100 -Maximum 999))"
}
if ($pmcUser.Length -lt 3 -or $pmcUser.Length -gt 16 -or $pmcUser -notmatch "^[A-Za-z]+$") {
    Write-LauncherError -Message "Invalid username. Use 3 to 16 letters from the basic English alphabet only." -Exit
}
Write-LauncherStatus "Booting up Minecraft as user '$pmcUser'..."
$mcDir = Join-Path $opencraftDir "game"
if (-not (Test-Path -LiteralPath $mcDir -PathType Container)) {
    New-Item -ItemType Directory -Path $mcDir -Force | Out-Null
}
$portableMcArguments = @(
    "start"
    "--mc-dir"
    $mcDir
    "--disable-chat"
    "--username"
    $pmcUser
)
& $exePath @portableMcArguments
$exitCode = $LASTEXITCODE
if ($null -ne $exitCode -and $exitCode -ne 0) {
    throw "Minecraft exited with code $exitCode"
}
