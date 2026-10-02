Add-Type @"
using System;
using System.Runtime.InteropServices;

public class WinAPI {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
}
"@

$procs = Get-Process chrome | Where-Object { $_.MainWindowHandle -ne 0 }
Write-Host "Chrome processes with MainWindowHandle count: $($procs.Count)"

foreach ($p in $procs) {
    Write-Host "PID: $($p.Id), Title: '$($p.MainWindowTitle)', Handle: $($p.MainWindowHandle)"
    $rect = New-Object WinAPI+RECT
    [WinAPI]::GetWindowRect($p.MainWindowHandle, [ref]$rect) | Out-Null
    $vis = [WinAPI]::IsWindowVisible($p.MainWindowHandle)
    Write-Host "Visible: $vis, Coordinates: Left=$($rect.Left), Top=$($rect.Top), Right=$($rect.Right), Bottom=$($rect.Bottom)"
}

if ($procs.Count -eq 0) {
    Write-Host "NO Chrome process has a MainWindowHandle!"
    Write-Host "Listing all Chrome processes and their handles:"
    Get-Process chrome | Select-Object Id, ProcessName, SessionId, MainWindowTitle, MainWindowHandle
}
