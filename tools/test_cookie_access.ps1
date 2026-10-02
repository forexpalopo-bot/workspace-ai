$srcCookie = 'C:\Users\DELL\AppData\Local\Google\Chrome\User Data\Profile 1\Network\Cookies'
$srcLocalState = 'C:\Users\DELL\AppData\Local\Google\Chrome\User Data\Local State'

Write-Host "Checking Local State..."
if (Test-Path $srcLocalState) {
    $len = (Get-Item $srcLocalState).Length
    Write-Host "Local State accessible! Length: $len"
} else {
    Write-Host "Local State not found!"
}

Write-Host "Checking Cookies..."
try {
    $fs = [System.IO.File]::Open($srcCookie, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    Write-Host "Cookies accessible via FileShare.ReadWrite! Length: $($fs.Length)"
    $fs.Close()
} catch {
    Write-Host "Error opening Cookies: $($_.Exception.Message)"
}
