Write-Host "=== PYTHON PROCESSES ==="
Get-CimInstance Win32_Process -Filter "name = 'python.exe'" | ForEach-Object {
    Write-Host "PID: $($_.ProcessId)"
    Write-Host "Command: $($_.CommandLine)"
    Write-Host "---"
}

Write-Host "=== TERMINAL (MT4) PROCESSES ==="
Get-CimInstance Win32_Process -Filter "name = 'terminal.exe'" | ForEach-Object {
    Write-Host "PID: $($_.ProcessId)"
    Write-Host "Command: $($_.CommandLine)"
    Write-Host "---"
}

Write-Host "=== CHROME DEBUG PORT (9222) ==="
$portConn = Get-NetTCPConnection -LocalPort 9222 -State Listen -ErrorAction SilentlyContinue
if ($portConn) {
    Write-Host "Port 9222 is ACTIVE (Listening, OwningProcess: $($portConn.OwningProcess))"
} else {
    Write-Host "Port 9222 is NOT listening."
}
