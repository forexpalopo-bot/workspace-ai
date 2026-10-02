$me = "C:\Program Files (x86)\MetaTrader 4 IC Markets Global\metaeditor.exe"
$src = "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5\MQL4\Experts\BioOnePro_v94_FailClosed.mq4"
$log = "C:\Users\DELL\AppData\Roaming\MetaQuotes\Terminal\5D49F47D1EA1ECFC0DDC965B6D100AC5\MQL4\Experts\compile_v94.log"

Copy-Item "C:\Penelitian_EA\BioOnePro\repo\ea\BioOnePro_v94_FailClosed.mq4" $src -Force

Start-Process -FilePath $me -ArgumentList "/compile:`"$src`"", "/log:`"$log`"" -Wait

if (Test-Path $log) {
    Get-Content $log
} else {
    Write-Host "Log file not generated, checking ex4..."
}

$ex4 = $src.Replace(".mq4", ".ex4")
if (Test-Path $ex4) {
    Get-Item $ex4 | Select-Object LastWriteTime, Length
}
