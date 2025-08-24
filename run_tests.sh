#!/bin/bash

# Ludo Game Test Runner Script
# This script runs all types of tests for the Ludo game

echo "🎮 Ludo Game Test Suite Runner"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "Flutter version:"
flutter --version

# Get dependencies
print_status "Getting dependencies..."
flutter pub get

if [ $? -ne 0 ]; then
    print_error "Failed to get dependencies"
    exit 1
fi

# Generate code if needed
print_status "Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run unit tests
print_status "Running unit tests..."
flutter test test/unit/ --coverage

if [ $? -eq 0 ]; then
    print_status "✅ Unit tests passed"
else
    print_error "❌ Unit tests failed"
    exit 1
fi

# Run widget tests
print_status "Running widget tests..."
flutter test test/widget/

if [ $? -eq 0 ]; then
    print_status "✅ Widget tests passed"
else
    print_error "❌ Widget tests failed"
    exit 1
fi

# Run integration tests (if available)
print_status "Running integration tests..."
if [ -d "test/integration" ] && [ "$(ls -A test/integration)" ]; then
    flutter test integration_test/
    
    if [ $? -eq 0 ]; then
        print_status "✅ Integration tests passed"
    else
        print_warning "⚠️ Integration tests failed (may require device/emulator)"
    fi
else
    print_warning "No integration tests found"
fi

# Generate coverage report
print_status "Generating coverage report..."
if command -v lcov &> /dev/null; then
    # Generate HTML coverage report
    genhtml coverage/lcov.info -o coverage/html
    print_status "Coverage report generated at coverage/html/index.html"
else
    print_warning "lcov not installed. Install with: brew install lcov (macOS) or apt-get install lcov (Linux)"
fi

# Run analysis
print_status "Running static analysis..."
flutter analyze

if [ $? -eq 0 ]; then
    print_status "✅ Static analysis passed"
else
    print_warning "⚠️ Static analysis found issues"
fi

# Run formatting check
print_status "Checking code formatting..."
flutter format --dry-run --set-exit-if-changed .

if [ $? -eq 0 ]; then
    print_status "✅ Code formatting is correct"
else
    print_warning "⚠️ Code formatting issues found. Run 'flutter format .' to fix"
fi

print_status "🎉 Test suite completed!"
print_status "📊 Check coverage/html/index.html for detailed coverage report"