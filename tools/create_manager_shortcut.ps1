$wsh = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktop "Multi-Akun Claude Manager.lnk"
$shortcut = $wsh.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "C:\Penelitian_EA\BioOnePro\repo\tools\manage_claude_accounts.bat"
$shortcut.WorkingDirectory = "C:\Penelitian_EA\BioOnePro\repo\tools"
$shortcut.IconLocation = "C:\Program Files\Google\Chrome\Application\chrome.exe,0"
$shortcut.Description = "Buka dan kelola banyak akun Claude dalam 1 jendela ChromeDebug"
$shortcut.Save()
Write-Host "Created shortcut: $shortcutPath"
