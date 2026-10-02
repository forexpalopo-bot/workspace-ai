$prof = 'C:\Users\DELL\AppData\Local\Google\Chrome\User Data\Profile 1'
$files = Get-ChildItem -Recurse $prof | Where-Object { 
    $_.FullName -notlike "*Cache*" -and 
    $_.FullName -notlike "*Media Cache*" -and
    $_.FullName -notlike "*Service Worker*"
}
$size = ($files | Measure-Object -Property Length -Sum).Sum
Write-Host "Essential profile files count: $($files.Count), Total size: $([math]::Round($size/1MB, 2)) MB"
