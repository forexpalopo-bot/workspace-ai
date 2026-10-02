Write-Host "Closing existing Chrome processes..."
Stop-Process -Name chrome -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "Launching Chrome with remote debugging on port 9222..."
$chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$userData = "C:\Users\DELL\AppData\Local\Google\Chrome\User Data"
$cmdLine = "`"$chromePath`" --remote-debugging-port=9222 --user-data-dir=`"$userData`" --profile-directory=`"Profile 1`" --remote-allow-origins=* https://claude.ai/chat/b87a9d83-732b-424b-80ff-d27c8fc2ecc3"


$result = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $cmdLine }
Write-Host "Launch return code: $($result.ReturnValue), ProcessId: $($result.ProcessId)"

Write-Host "Waiting for port 9222 to listen..."
$maxWait = 15
$connected = $false
for ($i = 0; $i -lt $maxWait; $i++) {
    Start-Sleep -Seconds 1
    $conn = Get-NetTCPConnection -LocalPort 9222 -State Listen -ErrorAction SilentlyContinue
    if ($conn) {
        $connected = $true
        Write-Host "Port 9222 is ACTIVE on PID $($conn.OwningProcess)!"
        break
    }
}

if (-not $connected) {
    Write-Warning "Port 9222 did not respond within $maxWait seconds."
}
