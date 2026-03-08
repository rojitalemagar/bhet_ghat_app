# Test API Script

Write-Host "Testing Backend API..."
Write-Host ""

# Test Signup
Write-Host "1. Testing Signup..."
$signupBody = @{
    name = "Test Developer"
    email = "dev@example.com"
    password = "dev123456"
} | ConvertTo-Json

try {
    $signupResponse = Invoke-WebRequest -Uri "http://localhost:3000/api/auth/signup" `
        -Method POST `
        -ContentType "application/json" `
        -Body $signupBody `
        -SkipHttpErrorCheck
    
    $signupData = $signupResponse.Content | ConvertFrom-Json
    Write-Host "Signup Response:" -ForegroundColor Green
    Write-Host ($signupData | ConvertTo-Json -Depth 5)
    Write-Host ""
    
    if ($signupData.token) {
        Write-Host "✅ Token received:" -ForegroundColor Green
        Write-Host $signupData.token
        Write-Host ""
    } else {
        Write-Host "❌ No token in response" -ForegroundColor Red
    }
} catch {
    Write-Host "Error during signup: $_" -ForegroundColor Red
}

# Test Login
Write-Host "2. Testing Login..."
$loginBody = @{
    email = "dev@example.com"
    password = "dev123456"
} | ConvertTo-Json

try {
    $loginResponse = Invoke-WebRequest -Uri "http://localhost:3000/api/auth/login" `
        -Method POST `
        -ContentType "application/json" `
        -Body $loginBody `
        -SkipHttpErrorCheck
    
    $loginData = $loginResponse.Content | ConvertFrom-Json
    Write-Host "Login Response:" -ForegroundColor Green
    Write-Host ($loginData | ConvertTo-Json -Depth 5)
    Write-Host ""
    
    if ($loginData.token) {
        Write-Host "✅ Token received:" -ForegroundColor Green
        Write-Host $loginData.token
    } else {
        Write-Host "❌ No token in response" -ForegroundColor Red
    }
} catch {
    Write-Host "Error during login: $_" -ForegroundColor Red
}
