# Test /auth/login with body capture
$url = "https://api-kesehatan.rakryan.id/auth/login"
try {
    $r = Invoke-WebRequest -Uri $url -Method POST -Headers @{"Content-Type"="application/json"} -Body '{"username":"test","password":"test"}' -UseBasicParsing -ErrorAction Stop
    Write-Host "auth/login -> $($r.StatusCode)"
    Write-Host "Body: $($r.Content)"
} catch {
    $status = $_.Exception.Response.StatusCode.value__
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $body = $reader.ReadToEnd()
    Write-Host "auth/login -> $status"
    Write-Host "Body: $body"
}

# Test /article GET with body capture  
$url2 = "https://api-kesehatan.rakryan.id/article"
try {
    $r2 = Invoke-WebRequest -Uri $url2 -Method GET -UseBasicParsing -ErrorAction Stop
    Write-Host "article GET -> $($r2.StatusCode)"
    Write-Host "Body: $($r2.Content)"
} catch {
    $status2 = $_.Exception.Response.StatusCode.value__
    $reader2 = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $reader2.BaseStream.Position = 0
    $reader2.DiscardBufferedData()
    $body2 = $reader2.ReadToEnd()
    Write-Host "article GET -> $status2"
    Write-Host "Body: $body2"
}
