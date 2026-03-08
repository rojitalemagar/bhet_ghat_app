@echo off
REM Debug Console Setup Script
REM This script opens both backend server and Flutter app in separate terminals

echo.
echo ========================================
echo  Debug Console Setup
echo ========================================
echo.
echo Starting Backend Server in new window...
echo.

REM Open first terminal for backend server
start "Backend Server" cmd /k "cd /d C:\Users\offic\Desktop\app\bhet_ghat_app && node server.js"

echo Waiting 3 seconds before starting Flutter...
timeout /t 3 /nobreak

echo.
echo Starting Flutter App in new window...
echo.

REM Open second terminal for Flutter app
start "Flutter App - Debug Console" cmd /k "cd /d C:\Users\offic\Desktop\app\bhet_ghat_app && flutter run -v"

echo.
echo ========================================
echo  Both terminals are now running!
echo ========================================
echo.
echo Backend Server Terminal: Shows signup/login requests
echo Flutter App Terminal: Shows app debug output
echo.
echo When you create an account in the emulator,
echo you should see logs in BOTH terminals!
echo.
pause
