# Test script untuk memverifikasi /article/user dengan token valid

$baseUrl = "https://api-kesehatan.rakryan.id"

# Step 1: Login dengan user yang sudah ada
Write-Host "=== LOGIN ===" -ForegroundColor Cyan
$loginBody = @{
    username = "testuser123"
    password = "password123"
    appSource = "kesehatan"
} | ConvertTo-Json -Compress

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/auth/login" -Method Post -ContentType "application/json" -Body $loginBody
    Write-Host "Login berhasil!" -ForegroundColor Green
    $token = $loginResponse.data.token
    Write-Host "Token: $token" -ForegroundColor Yellow
    
    $headers = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    
    # Step 2: Test /article/user
    Write-Host "`n=== GET /article/user ===" -ForegroundColor Cyan
    try {
        $userArticles = Invoke-RestMethod -Uri "$baseUrl/article/user" -Method Get -Headers $headers
        Write-Host "Response:" -ForegroundColor Green
        Write-Host ($userArticles | ConvertTo-Json -Depth 5)
        
        $articleCount = if ($userArticles.data.articles) { $userArticles.data.articles.Count } else { 0 }
        Write-Host "`nJumlah artikel user: $articleCount" -ForegroundColor Magenta
        
    } catch {
        Write-Host "GAGAL!" -ForegroundColor Red
        Write-Host "Status: $($_.Exception.Response.StatusCode.value__)"
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            Write-Host "Body: $($reader.ReadToEnd())"
        } else {
            Write-Host "Error: $_"
        }
    }
    
    # Step 3: Test /article (all articles)
    Write-Host "`n=== GET /article (all) ===" -ForegroundColor Cyan
    try {
        $allArticles = Invoke-RestMethod -Uri "$baseUrl/article" -Method Get -Headers $headers
        Write-Host "Response:" -ForegroundColor Green
        Write-Host ($allArticles | ConvertTo-Json -Depth 5)
        
        $allCount = if ($allArticles.data.articles) { $allArticles.data.articles.Count } else { 0 }
        Write-Host "`nJumlah semua artikel: $allCount" -ForegroundColor Magenta
        
    } catch {
        Write-Host "GAGAL!" -ForegroundColor Red
        Write-Host "Status: $($_.Exception.Response.StatusCode.value__)"
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            Write-Host "Body: $($reader.ReadToEnd())"
        } else {
            Write-Host "Error: $_"
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
    } else {
        Write-Host "Error: $_"
    }
}
