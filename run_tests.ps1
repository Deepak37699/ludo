# Ludo Game Test Runner Script for Windows PowerShell
# This script runs all types of tests for the Ludo game

Write-Host "🎮 Ludo Game Test Suite Runner" -ForegroundColor Cyan
Write-Host "===============================" -ForegroundColor Cyan

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if Flutter is installed
try {
    $flutterVersion = flutter --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter not found"
    }
    Write-Status "Flutter is installed"
    Write-Host $flutterVersion
} catch {
    Write-Error "Flutter is not installed or not in PATH"
    exit 1
}

# Get dependencies
Write-Status "Getting dependencies..."
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to get dependencies"
    exit 1
}

# Generate code if needed
Write-Status "Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run unit tests
Write-Status "Running unit tests..."
flutter test test/unit/ --coverage

if ($LASTEXITCODE -eq 0) {
    Write-Status "✅ Unit tests passed"
} else {
    Write-Error "❌ Unit tests failed"
    exit 1
}

# Run widget tests
Write-Status "Running widget tests..."
flutter test test/widget/

if ($LASTEXITCODE -eq 0) {
    Write-Status "✅ Widget tests passed"
} else {
    Write-Error "❌ Widget tests failed"
    exit 1
}

# Run integration tests (if available)
Write-Status "Running integration tests..."
if (Test-Path "test/integration" -PathType Container) {
    $integrationFiles = Get-ChildItem "test/integration" -Recurse -Include "*.dart"
    if ($integrationFiles.Count -gt 0) {
        flutter test integration_test/
        
        if ($LASTEXITCODE -eq 0) {
            Write-Status "✅ Integration tests passed"
        } else {
            Write-Warning "⚠️ Integration tests failed (may require device/emulator)"
        }
    } else {
        Write-Warning "No integration test files found"
    }
} else {
    Write-Warning "No integration tests directory found"
}

# Generate coverage report
Write-Status "Generating coverage report..."
if (Get-Command "lcov" -ErrorAction SilentlyContinue) {
    # Generate HTML coverage report
    genhtml coverage/lcov.info -o coverage/html
    Write-Status "Coverage report generated at coverage/html/index.html"
} else {
    Write-Warning "lcov not installed. Coverage report in lcov.info format available"
}

# Run analysis
Write-Status "Running static analysis..."
flutter analyze

if ($LASTEXITCODE -eq 0) {
    Write-Status "✅ Static analysis passed"
} else {
    Write-Warning "⚠️ Static analysis found issues"
}

# Run formatting check
Write-Status "Checking code formatting..."
flutter format --dry-run --set-exit-if-changed .

if ($LASTEXITCODE -eq 0) {
    Write-Status "✅ Code formatting is correct"
} else {
    Write-Warning "⚠️ Code formatting issues found. Run 'flutter format .' to fix"
}

Write-Status "🎉 Test suite completed!"
Write-Status "📊 Check coverage/ directory for coverage reports"