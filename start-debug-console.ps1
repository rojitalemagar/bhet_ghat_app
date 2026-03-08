# Debug Console Setup Script (PowerShell)
# This script opens both backend server and Flutter app in separate terminals

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Debug Console Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Starting Backend Server in new window..." -ForegroundColor Green
Write-Host ""

# Open first terminal for backend server
Start-Process -FilePath "powershell" `
  -ArgumentList "-NoExit -Command `"cd 'C:\Users\offic\Desktop\app\bhet_ghat_app'; node server.js`"" `
  -WindowStyle Normal

Write-Host "Waiting 3 seconds before starting Flutter..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

Write-Host "`nStarting Flutter App in new window..." -ForegroundColor Green
Write-Host ""

# Open second terminal for Flutter app
Start-Process -FilePath "powershell" `
  -ArgumentList "-NoExit -Command `"cd 'C:\Users\offic\Desktop\app\bhet_ghat_app'; flutter run -v`"" `
  -WindowStyle Normal

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Both terminals are now running!" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Backend Server Terminal: Shows signup/login requests" -ForegroundColor Yellow
Write-Host "Flutter App Terminal: Shows app debug output" -ForegroundColor Yellow

Write-Host "`nWhen you create an account in the emulator," -ForegroundColor Magenta
Write-Host "you should see logs in BOTH terminals!" -ForegroundColor Magenta
Write-Host ""
