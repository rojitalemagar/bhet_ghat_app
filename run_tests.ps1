# Test Runner Script for BhetGhat App (PowerShell)

Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║        BhetGhat App - Test Runner                         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Check if we're in the right directory
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "❌ Error: pubspec.yaml not found!" -ForegroundColor Red
    Write-Host "Please run this script from the project root directory." -ForegroundColor Red
    exit 1
}

Write-Host "📱 Flutter Project Detected`n" -ForegroundColor Green

function Show-Menu {
    Write-Host "`nSelect test option:" -ForegroundColor Yellow
    Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host "1. Run ALL tests" -ForegroundColor White
    Write-Host "2. Run UNIT tests only" -ForegroundColor White
    Write-Host "3. Run WIDGET tests only" -ForegroundColor White
    Write-Host "4. Run tests (VERBOSE mode)" -ForegroundColor White
    Write-Host "5. Run tests (COVERAGE mode)" -ForegroundColor White
    Write-Host "6. Exit" -ForegroundColor White
    Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor Gray
}

function Run-AllTests {
    Write-Host "`n🧪 Running ALL Tests...`n" -ForegroundColor Yellow
    Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor Gray
    flutter test
    Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor Gray
}

function Run-UnitTests {
    Write-Host "`n📊 Running Unit Tests...`n" -ForegroundColor Yellow
    Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor Gray
    flutter test test/unit_tests.dart
    Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor Gray
}

function Run-WidgetTests {
    Write-Host "`n🎨 Running Widget Tests...`n" -ForegroundColor Yellow
    Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor Gray
    flutter test test/widget_tests.dart
    Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor Gray
}

function Run-VerboseTests {
    Write-Host "`n📝 Running Tests (Verbose Mode)...`n" -ForegroundColor Yellow
    Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor Gray
    flutter test --verbose
    Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor Gray
}

function Run-CoverageTests {
    Write-Host "`n📈 Running Tests with Coverage...`n" -ForegroundColor Yellow
    Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor Gray
    flutter test --coverage
    Write-Host "──────────────────────────────────────────────────────────" -ForegroundColor Gray
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Enter your choice (1-6)"
    
    switch ($choice) {
        "1" { Run-AllTests }
        "2" { Run-UnitTests }
        "3" { Run-WidgetTests }
        "4" { Run-VerboseTests }
        "5" { Run-CoverageTests }
        "6" {
            Write-Host "`n👋 Goodbye!`n" -ForegroundColor Green
            exit 0
        }
        default {
            Write-Host "`n❌ Invalid choice. Please select 1-6.`n" -ForegroundColor Red
        }
    }
} while ($true)
