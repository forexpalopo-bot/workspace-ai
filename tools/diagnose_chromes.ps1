Write-Host "=== 1. RUNNING CHROME MAIN PROCESSES ==="
Get-CimInstance Win32_Process -Filter "name = 'chrome.exe'" | Where-Object { $_.CommandLine -notlike "*--type=*" } | ForEach-Object {
    Write-Host "PID: $($_.ProcessId)"
    Write-Host "CMD: $($_.CommandLine)"
    Write-Host "---"
}

Write-Host "=== 2. LISTENING DEBUG PORTS ==="
Get-NetTCPConnection -State Listen | Where-Object { $_.LocalPort -in 9222, 9223, 9224, 9225, 9333 } | ForEach-Object {
    Write-Host "Port: $($_.LocalPort), PID: $($_.OwningProcess)"
}

Write-Host "=== 3. CHROME SHORTCUTS ON DESKTOP ==="
$wsh = New-Object -ComObject WScript.Shell
Get-ChildItem "C:\Users\DELL\Desktop" -Filter "*Chrome*.lnk" | ForEach-Object {
    $sc = $wsh.CreateShortcut($_.FullName)
    Write-Host "File: $($_.Name)"
    Write-Host "Target: $($sc.TargetPath)"
    Write-Host "Args: $($sc.Arguments)"
    Write-Host "---"
}
