$shortcut = "C:\Users\DELL\Desktop\Chrome Debug (Claude).lnk"
Start-Process "explorer.exe" -ArgumentList "`"$shortcut`""
Write-Host "Launched shortcut via Explorer. Waiting for port 9222..."

$maxWait = 10
$found = $false
for ($i = 0; $i -lt $maxWait; $i++) {
    Start-Sleep -Seconds 1
    $conn = Get-NetTCPConnection -LocalPort 9222 -State Listen -ErrorAction SilentlyContinue
    if ($conn) {
        $found = $true
        Write-Host "SUCCESS: Port 9222 is ACTIVE on PID $($conn.OwningProcess)!"
        break
    }
}

if (-not $found) {
    Write-Warning "Port 9222 is not yet listening."
}
