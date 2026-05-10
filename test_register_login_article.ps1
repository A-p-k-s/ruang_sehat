# Test complete flow: Register -> Login -> Get My Articles

$baseUrl = "https://api-kesehatan.rakryan.id"
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$username = "testuser$timestamp"

Write-Host "=== REGISTER ===" -ForegroundColor Cyan
Write-Host "Username: $username"
$registerBody = @{
    name = "Test User"
    username = $username
    password = "password123"
    appSource = "kesehatan"
} | ConvertTo-Json -Compress

try {
    $registerResponse = Invoke-RestMethod -Uri "$baseUrl/auth/register" -Method Post -ContentType "application/json" -Body $registerBody
    Write-Host "Register berhasil!" -ForegroundColor Green
    Write-Host ($registerResponse | ConvertTo-Json -Depth 3)
} catch {
    Write-Host "Register GAGAL!" -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        Write-Host "Body: $($reader.ReadToEnd())"
    }
}

# Login
Write-Host "`n=== LOGIN ===" -ForegroundColor Cyan
$loginBody = @{
    username = $username
    password = "password123"
    appSource = "kesehatan"
} | ConvertTo-Json -Compress

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -ContentType "application/json" -Body $loginBody
    Write-Host "Login berhasil!" -ForegroundColor Green
    Write-Host ($loginResponse | ConvertTo-Json -Depth 3)
    
    $token = $loginResponse.data.token
    Write-Host "`nToken: $token" -ForegroundColor Yellow
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # Get My Articles
    Write-Host "`n=== GET /article/user ===" -ForegroundColor Cyan
    try {
        $userArticles = Invoke-RestMethod -Uri "$baseUrl/article/user" -Method Get -Headers $headers
        Write-Host "Response:" -ForegroundColor Green
        Write-Host ($userArticles | ConvertTo-Json -Depth 5)
        
        $articleCount = if ($userArticles.data.articles) { $userArticles.data.articles.Count } else { 0 }
        Write-Host "`nJumlah artikel user: $articleCount" -ForegroundColor Magenta
        
        if ($articleCount -eq 0) {
            Write-Host "`n=== DATA KOSONG ===" -ForegroundColor Yellow
            Write-Host "User ini belum memiliki artikel. Ini BUKAN error API."
            Write-Host "Silakan buat artikel terlebih dahulu melalui aplikasi."
        }
        
    } catch {
        Write-Host "GAGAL!" -ForegroundColor Red
        Write-Host "Status: $($_.Exception.Response.StatusCode.value__)"
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            Write-Host "Body: $($reader.ReadToEnd())"
        }
    }
    
} catch {
    Write-Host "Login GAGAL!" -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        Write-Host "Body: $($reader.ReadToEnd())"
    }
}
