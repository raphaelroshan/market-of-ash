param(
    [Parameter(Mandatory = $true)]
    [string]$Executable,
    [Parameter(Mandatory = $true)]
    [string]$Screenshot,
    [Parameter(Mandatory = $true)]
    [string]$Metadata
)

$ErrorActionPreference = "Stop"
$executablePath = (Resolve-Path $Executable).Path
$screenshotPath = [System.IO.Path]::GetFullPath($Screenshot)
$metadataPath = [System.IO.Path]::GetFullPath($Metadata)
[System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($screenshotPath)) | Out-Null
[System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($metadataPath)) | Out-Null

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class MarketOfAshWindowCapture {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    [StructLayout(LayoutKind.Sequential)]
    public struct POINT { public int X; public int Y; }
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr handle, out RECT rectangle);
    [DllImport("user32.dll")]
    public static extern bool GetClientRect(IntPtr handle, out RECT rectangle);
    [DllImport("user32.dll")]
    public static extern bool ClientToScreen(IntPtr handle, ref POINT point);
    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr handle, IntPtr insertAfter, int x, int y, int width, int height, uint flags);
    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int x, int y);
}
"@
Add-Type -AssemblyName System.Drawing

$version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($executablePath)
$process = $null
try {
    $process = Start-Process -FilePath $executablePath -WorkingDirectory ([System.IO.Path]::GetDirectoryName($executablePath)) -ArgumentList @("--resolution", "960x540", "--position", "0,0", "--", "--capture-window=960x540") -PassThru
    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    $handle = [IntPtr]::Zero
    while ([DateTime]::UtcNow -lt $deadline) {
        Start-Sleep -Milliseconds 250
        $process.Refresh()
        if ($process.HasExited) {
            throw "Packaged game exited before presenting a window (exit code $($process.ExitCode))."
        }
        $handle = $process.MainWindowHandle
        if ($handle -ne [IntPtr]::Zero) {
            break
        }
    }
    if ($handle -eq [IntPtr]::Zero) {
        throw "Packaged game did not present a window within 30 seconds."
    }
    $noSizeNoOrderShow = 0x0001 -bor 0x0004 -bor 0x0040
    if (-not [MarketOfAshWindowCapture]::SetWindowPos($handle, [IntPtr]::Zero, 24, 24, 0, 0, $noSizeNoOrderShow)) {
        throw "Could not move the packaged game window onto the capture desktop."
    }
    if (-not [MarketOfAshWindowCapture]::SetCursorPos(1, 1)) {
        throw "Could not move the pointer outside the packaged game window."
    }
    Start-Sleep -Seconds 2
    $process.Refresh()
    $rectangle = [MarketOfAshWindowCapture+RECT]::new()
    if (-not [MarketOfAshWindowCapture]::GetWindowRect($process.MainWindowHandle, [ref]$rectangle)) {
        throw "Could not read the packaged game window bounds."
    }
    $width = $rectangle.Right - $rectangle.Left
    $height = $rectangle.Bottom - $rectangle.Top
    if ($width -le 0 -or $height -le 0) {
        throw "Packaged game reported invalid window bounds ${width}x${height}."
    }
    $clientRectangle = [MarketOfAshWindowCapture+RECT]::new()
    if (-not [MarketOfAshWindowCapture]::GetClientRect($process.MainWindowHandle, [ref]$clientRectangle)) {
        throw "Could not read the packaged game client bounds."
    }
    $clientOrigin = [MarketOfAshWindowCapture+POINT]::new()
    if (-not [MarketOfAshWindowCapture]::ClientToScreen($process.MainWindowHandle, [ref]$clientOrigin)) {
        throw "Could not locate the packaged game client area on screen."
    }
    $captureWidth = $clientRectangle.Right - $clientRectangle.Left
    $captureHeight = $clientRectangle.Bottom - $clientRectangle.Top
    if ($captureWidth -le 0 -or $captureHeight -le 0 -or $clientOrigin.X -lt 0 -or $clientOrigin.Y -lt 0) {
        throw "Packaged game reported invalid client capture bounds ${captureWidth}x${captureHeight} at $($clientOrigin.X),$($clientOrigin.Y)."
    }
    $bitmap = [System.Drawing.Bitmap]::new($captureWidth, $captureHeight)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
        $graphics.CopyFromScreen($clientOrigin.X, $clientOrigin.Y, 0, 0, $bitmap.Size)
        $bitmap.Save($screenshotPath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $graphics.Dispose()
        $bitmap.Dispose()
    }
    @{
        executable = $executablePath
        process_name = $process.ProcessName
        window_title = $process.MainWindowTitle
        window = @{ x = $rectangle.Left; y = $rectangle.Top; width = $width; height = $height }
        capture = @{ x = $clientOrigin.X; y = $clientOrigin.Y; width = $captureWidth; height = $captureHeight }
        product_name = $version.ProductName
        file_version = $version.FileVersion
        product_version = $version.ProductVersion
    } | ConvertTo-Json -Depth 3 | Set-Content -Path $metadataPath -Encoding UTF8
}
finally {
    if ($null -ne $process -and -not $process.HasExited) {
        $process.CloseMainWindow() | Out-Null
        if (-not $process.WaitForExit(3000)) {
            Stop-Process -Id $process.Id -Force
        }
    }
}
