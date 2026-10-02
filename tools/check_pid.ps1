$p = Get-CimInstance Win32_Process -Filter "ProcessId = 14944"
Write-Host "PID 14944 Command: $($p.CommandLine)"
