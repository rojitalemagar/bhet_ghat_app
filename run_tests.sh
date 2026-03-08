#!/bin/bash
# Test Runner Script for BhetGhat App

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        BhetGhat App - Test Runner                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found!"
    echo "Please run this script from the project root directory."
    exit 1
fi

echo "📱 Flutter Project Detected"
echo ""

# Function to run all tests
run_all_tests() {
    echo "🧪 Running ALL Tests..."
    echo "──────────────────────────────────────────────────────────"
    flutter test
}

# Function to run unit tests
run_unit_tests() {
    echo "📊 Running Unit Tests..."
    echo "──────────────────────────────────────────────────────────"
    flutter test test/unit_tests.dart
}

# Function to run widget tests
run_widget_tests() {
    echo "🎨 Running Widget Tests..."
    echo "──────────────────────────────────────────────────────────"
    flutter test test/widget_tests.dart
}

# Function to run tests with verbose output
run_verbose_tests() {
    echo "📝 Running Tests (Verbose Mode)..."
    echo "──────────────────────────────────────────────────────────"
    flutter test --verbose
}

# Function to run tests with coverage
run_coverage_tests() {
    echo "📈 Running Tests with Coverage..."
    echo "──────────────────────────────────────────────────────────"
    flutter test --coverage
}

# Show menu
show_menu() {
    echo ""
    echo "Select test option:"
    echo "──────────────────────────────────────────────────────────"
    echo "1. Run ALL tests"
    echo "2. Run UNIT tests only"
    echo "3. Run WIDGET tests only"
    echo "4. Run tests (VERBOSE mode)"
    echo "5. Run tests (COVERAGE mode)"
    echo "6. Exit"
    echo "──────────────────────────────────────────────────────────"
}

# Main script logic
while true; do
    show_menu
    read -p "Enter your choice (1-6): " choice
    
    case $choice in
        1)
            run_all_tests
            ;;
        2)
            run_unit_tests
            ;;
        3)
            run_widget_tests
            ;;
        4)
            run_verbose_tests
            ;;
        5)
            run_coverage_tests
            ;;
        6)
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid choice. Please select 1-6."
            ;;
    esac
    
    echo ""
done
