$shortcut = "C:\Users\DELL\Desktop\Google Chrome (Debug 9222).lnk"
Start-Process "explorer.exe" -ArgumentList "`"$shortcut`""
Start-Sleep -Seconds 4

$procs = Get-Process chrome -ErrorAction SilentlyContinue
Write-Host "Chrome process count: $($procs.Count)"

$conn = Get-NetTCPConnection -LocalPort 9222 -State Listen -ErrorAction SilentlyContinue
if ($conn) {
    Write-Host "Port 9222 is ACTIVE on PID $($conn.OwningProcess)!"
} else {
    Write-Host "Port 9222 is NOT listening."
}
