$wsh = New-Object -ComObject WScript.Shell
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktop "Tambah Tab Claude Baru.lnk"
$shortcut = $wsh.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "C:\Penelitian_EA\BioOnePro\repo\tools\open_new_account_tab.bat"
$shortcut.WorkingDirectory = "C:\Penelitian_EA\BioOnePro\repo\tools"
$shortcut.IconLocation = "C:\Program Files\Google\Chrome\Application\chrome.exe,0"
$shortcut.Description = "Buka tab baru untuk login akun Claude berbeda di ChromeDebug"
$shortcut.Save()
Write-Host "Created shortcut: $shortcutPath"
