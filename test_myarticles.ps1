# Test script untuk endpoint /article/user
# Login dulu, lalu ambil token dan test /article/user

$baseUrl = "https://api-kesehatan.rakryan.id"

Write-Host "=== TEST LOGIN ===" -ForegroundColor Cyan
$loginBody = @{
    username = "raka123"
    password = "password123"
    appSource = "kesehatan"
} | ConvertTo-Json -Compress

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -ContentType "application/json" -Body $loginBody
    Write-Host "Login Success!" -ForegroundColor Green
    Write-Host ($loginResponse | ConvertTo-Json -Depth 3)
    
    $token = $loginResponse.data.token
    Write-Host "`nToken: $token" -ForegroundColor Yellow
    
    # Test /article/user
    Write-Host "`n=== TEST /article/user ===" -ForegroundColor Cyan
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    try {
        $articlesResponse = Invoke-RestMethod -Uri "$baseUrl/article/user" -Method Get -Headers $headers
        Write-Host "/article/user Success!" -ForegroundColor Green
        Write-Host ($articlesResponse | ConvertTo-Json -Depth 5)
    } catch {
        Write-Host "/article/user FAILED!" -ForegroundColor Red
        Write-Host "Status: $($_.Exception.Response.StatusCode.value__)"
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Host "Body: $responseBody"
    }
    
    # Test /article (all articles)
    Write-Host "`n=== TEST /article (all) ===" -ForegroundColor Cyan
    try {
        $allArticlesResponse = Invoke-RestMethod -Uri "$baseUrl/article" -Method Get -Headers $headers
        Write-Host "/article Success!" -ForegroundColor Green
        Write-Host ($allArticlesResponse | ConvertTo-Json -Depth 5)
    } catch {
        Write-Host "/article FAILED!" -ForegroundColor Red
        Write-Host "Status: $($_.Exception.Response.StatusCode.value__)"
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd()
        Write-Host "Body: $responseBody"
    }
    
} catch {
    Write-Host "Login FAILED!" -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)"
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd()
    Write-Host "Body: $responseBody"
}
