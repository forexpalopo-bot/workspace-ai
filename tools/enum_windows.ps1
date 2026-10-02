Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  using System.Text;

  public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
  }
"@

$list = New-Object System.Collections.Generic.List[PSCustomObject]

[Win32]::EnumWindows({
    param($hWnd, $lParam)
    if ([Win32]::IsWindowVisible($hWnd)) {
        $sb = New-Object System.Text.StringBuilder 1024
        [Win32]::GetWindowText($hWnd, $sb, 1024) | Out-Null
        $title = $sb.ToString()
        if ($title.Length -gt 0) {
            $pid = 0
            [Win32]::GetWindowThreadProcessId($hWnd, [ref]$pid) | Out-Null
            $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
            $list.Add([PSCustomObject]@{
                Handle = $hWnd
                PID = $pid
                Process = if ($proc) { $proc.ProcessName } else { "Unknown" }
                Title = $title
            })
        }
    }
    return $true
}, [IntPtr]::Zero) | Out-Null

$list | Select-Object -First 30 | Format-Table -AutoSize

