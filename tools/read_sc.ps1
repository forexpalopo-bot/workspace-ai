$wsh = New-Object -ComObject WScript.Shell
$sc = $wsh.CreateShortcut("C:\Users\DELL\Desktop\Google Chrome (Debug 9222).lnk")
Write-Host "Target: $($sc.TargetPath)"
Write-Host "Arguments: $($sc.Arguments)"
