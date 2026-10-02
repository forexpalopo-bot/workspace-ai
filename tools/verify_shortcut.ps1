$wsh = New-Object -ComObject WScript.Shell
$sc = $wsh.CreateShortcut("C:\Users\DELL\Desktop\Chrome Debug (Claude).lnk")
Write-Host "Target: $($sc.TargetPath)"
Write-Host "Arguments: $($sc.Arguments)"
Write-Host "WorkingDir: $($sc.WorkingDirectory)"
