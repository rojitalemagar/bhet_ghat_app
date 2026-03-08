#!/usr/bin/env powershell
# API Connection Testing Script
# This script helps verify your API and Flutter app are properly connected

Write-Host "BhetGhat App API Connection Tester" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check if Node.js is installed
Write-Host "Test 1: Checking Node.js..." -ForegroundColor Yellow
try {
    $nodeVersion = node --version
    Write-Host "Node.js installed: $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "Node.js not found. Please install from https://nodejs.org/" -ForegroundColor Red
    Exit 1
}

Write-Host ""

# Test 2: Check if npm is installed
Write-Host "Test 2: Checking npm..." -ForegroundColor Yellow
try {
    $npmVersion = npm --version
    Write-Host "npm installed: $npmVersion" -ForegroundColor Green
} catch {
    Write-Host "npm not found" -ForegroundColor Red
    Exit 1
}

Write-Host ""

# Test 3: Check if required npm packages exist
Write-Host "Test 3: Checking npm dependencies..." -ForegroundColor Yellow
if ((Test-Path "node_modules") -and (Test-Path "node_modules/express")) {
    Write-Host "Express.js already installed" -ForegroundColor Green
} else {
    Write-Host "Express.js not found. Will be installed when server starts." -ForegroundColor Yellow
}

Write-Host ""

# Test 4: Check if Flutter is installed
Write-Host "Test 4: Checking Flutter..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-Host "Flutter installed" -ForegroundColor Green
} catch {
    Write-Host "Flutter not found. Please install from https://flutter.dev/" -ForegroundColor Red
}

Write-Host ""

# Test 5: Check project files
Write-Host "Test 5: Checking project structure..." -ForegroundColor Yellow
$requiredFiles = @(
    "server.js",
    "lib/core/constants/api_constants.dart",
    "lib/presentation/screens/login_screen.dart",
    "lib/data/remote_data_sources/auth_remote_data_source.dart"
)

$allFilesExist = $true
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "  $file" -ForegroundColor Green
    } else {
        Write-Host "  $file (MISSING)" -ForegroundColor Red
        $allFilesExist = $false
    }
}

Write-Host ""

if ($allFilesExist) {
    Write-Host "All required files found!" -ForegroundColor Green
} else {
    Write-Host "Some required files are missing" -ForegroundColor Red
}

Write-Host ""

# Summary
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "NEXT STEPS:" -ForegroundColor Green
Write-Host "1. Start backend server:" -ForegroundColor White
Write-Host "   node server.js" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. Test API in Postman:" -ForegroundColor White
Write-Host "   POST http://localhost:3000/api/auth/signup" -ForegroundColor Yellow
Write-Host "   POST http://localhost:3000/api/auth/login" -ForegroundColor Yellow
Write-Host ""
Write-Host "3. Run Flutter app:" -ForegroundColor White
Write-Host "   flutter run" -ForegroundColor Yellow
Write-Host ""
Write-Host "4. Test login/register in app" -ForegroundColor White
Write-Host ""
Write-Host "Documentation:" -ForegroundColor Cyan
Write-Host "   - See FLUTTER_API_CONNECTION.md for detailed guide" -ForegroundColor Gray
Write-Host "   - See POSTMAN_LOGIN_SETUP.md for API testing guide" -ForegroundColor Gray
