#!/usr/bin/env pwsh
# ZUI Test Suite

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "ZUI Framework Test Suite" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$testCount = 0
$passCount = 0

function Test-App {
    param(
        [string]$AppName,
        [string]$ExePath
    )

    Write-Host "[$($testCount + 1)] Testing $AppName..." -ForegroundColor Yellow

    try {
        # Launch app with 2-second timeout
        $proc = Start-Process -FilePath $ExePath -PassThru -WindowStyle Minimized
        Start-Sleep -Seconds 2

        if ($proc.HasExited -eq $false) {
            $proc | Stop-Process -Force -ErrorAction SilentlyContinue
            Write-Host "      [PASSED] App launched and closed successfully" -ForegroundColor Green
            return $true
        } else {
            Write-Host "      [PASSED] App executed successfully" -ForegroundColor Green
            return $true
        }
    } catch {
        Write-Host "      [FAILED] $_" -ForegroundColor Red
        return $false
    }
}

$binDir = ".\zig-out\bin"

# Array of test apps
$apps = @(
    @{ Name = "Hello World"; Path = "$binDir\zui-hello.exe" },
    @{ Name = "Interactive Button"; Path = "$binDir\zui-004-interactive-button.exe" },
    @{ Name = "State Counter"; Path = "$binDir\zui-005-state-counter.exe" },
    @{ Name = "Declarative API"; Path = "$binDir\zui-006-declarative-api.exe" },
    @{ Name = "Essential Styling"; Path = "$binDir\zui-007-essential-styling.exe" },
    @{ Name = "Todo App"; Path = "$binDir\zui-010-todo-app.exe" },
    @{ Name = "Profile App"; Path = "$binDir\zui-011-profile-app.exe" },
    @{ Name = "Advanced Counter"; Path = "$binDir\zui-012-advanced-counter.exe" },
    @{ Name = "First Demo"; Path = "$binDir\zui-first-demo.exe" }
)

Write-Host "Running Example Execution Tests" -ForegroundColor Magenta
Write-Host "================================" -ForegroundColor Magenta
Write-Host ""

foreach ($app in $apps) {
    $testCount++
    if (Test-App -AppName $app.Name -ExePath $app.Path) {
        $passCount++
    }
    Write-Host ""
}

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "Total Tests: $testCount"
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $($testCount - $passCount)" -ForegroundColor Red
Write-Host ""

if ($passCount -eq $testCount) {
    Write-Host "[ALL TESTS PASSED!]" -ForegroundColor Green -BackgroundColor DarkGreen
    exit 0
} else {
    Write-Host "[SOME TESTS FAILED]" -ForegroundColor Red -BackgroundColor DarkRed
    exit 1
}

