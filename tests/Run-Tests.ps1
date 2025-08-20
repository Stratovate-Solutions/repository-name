#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Test runner for the GitHub Branch Protection Policy project

.DESCRIPTION
    Runs comprehensive Pester tests for the BranchProtectionPolicy script
    and generates test reports for CI/CD integration.

.PARAMETER TestType
    Type of tests to run:
    - Unit: Basic functionality and parameter validation tests
    - Integration: End-to-end workflow tests  
    - Security: Security-focused validation tests
    - CodeQuality: PSScriptAnalyzer static code analysis
    - All: Run all test types (default)

.PARAMETER OutputFormat
    Output format for test results (Console, NUnitXml, JUnitXml)

.PARAMETER GenerateReport
    Generate HTML test report

.EXAMPLE
    .\Run-Tests.ps1

.EXAMPLE
    .\Run-Tests.ps1 -TestType Unit -OutputFormat NUnitXml -GenerateReport

.EXAMPLE
    .\Run-Tests.ps1 -TestType CodeQuality

.EXAMPLE  
    .\Run-Tests.ps1 -TestType All -GenerateReport
#>

[CmdletBinding()]
param(
    [ValidateSet('Unit', 'Integration', 'Security', 'CodeQuality', 'All')]
    [string]$TestType = 'All',
    
    [ValidateSet('Console', 'NUnitXml', 'JUnitXml')]
    [string]$OutputFormat = 'Console',
    
    [switch]$GenerateReport
)

# ============================================================================
# Test Configuration
# ============================================================================

$TestsDirectory = $PSScriptRoot
$ProjectRoot = Split-Path $TestsDirectory -Parent
$OutputDirectory = Join-Path $ProjectRoot "TestResults"

# Ensure output directory exists
if (-not (Test-Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
}

# ============================================================================
# Prerequisites Check
# ============================================================================

Write-Host "GitHub Branch Protection Policy - Test Runner" -ForegroundColor Cyan
Write-Host "=" * 60

# Check Pester installation
try {
    $pesterModule = Get-Module -Name Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $pesterModule -or $pesterModule.Version.Major -lt 5) {
        Write-Host "Installing Pester 5.0+..." -ForegroundColor Yellow
        Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
    }
    Import-Module -Name Pester -Force
    Write-Host "✅ Pester module loaded: $($pesterModule.Version)" -ForegroundColor Green
}
catch {
    Write-Error "❌ Failed to load Pester module: $($_.Exception.Message)"
    exit 1
}

# Check PSScriptAnalyzer installation for CodeQuality tests
if ($TestType -eq 'CodeQuality' -or $TestType -eq 'All') {
    try {
        $psAnalyzerModule = Get-Module -Name PSScriptAnalyzer -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
        if (-not $psAnalyzerModule) {
            Write-Host "Installing PSScriptAnalyzer..." -ForegroundColor Yellow
            Install-Module -Name PSScriptAnalyzer -Force -SkipPublisherCheck -Scope CurrentUser
        }
        Import-Module -Name PSScriptAnalyzer -Force
        Write-Host "✅ PSScriptAnalyzer module loaded: $($psAnalyzerModule.Version)" -ForegroundColor Green
    }
    catch {
        Write-Warning "⚠️ PSScriptAnalyzer not available. Code quality tests will be skipped."
    }
}

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "⚠️ PowerShell 7.0+ recommended. Current version: $($PSVersionTable.PSVersion)"
}

# ============================================================================
# Test Execution
# ============================================================================

Write-Host "`nRunning tests..." -ForegroundColor Blue
Write-Host "Test Type: $TestType" -ForegroundColor Gray
Write-Host "Output Format: $OutputFormat" -ForegroundColor Gray

# Configure Pester
$PesterConfiguration = New-PesterConfiguration
$PesterConfiguration.Run.Path = $TestsDirectory
$PesterConfiguration.TestResult.Enabled = $true
$PesterConfiguration.Output.Verbosity = 'Detailed'

# Set output file based on format
switch ($OutputFormat) {
    'NUnitXml' {
        $outputFile = Join-Path $OutputDirectory "TestResults.xml"
        $PesterConfiguration.TestResult.OutputFormat = 'NUnitXml'
        $PesterConfiguration.TestResult.OutputPath = $outputFile
    }
    'JUnitXml' {
        $outputFile = Join-Path $OutputDirectory "TestResults.xml"
        $PesterConfiguration.TestResult.OutputFormat = 'JUnitXml'
        $PesterConfiguration.TestResult.OutputPath = $outputFile
    }
    default {
        $PesterConfiguration.TestResult.Enabled = $false
    }
}

# Filter tests by type
switch ($TestType) {
    'Unit' {
        $PesterConfiguration.Filter.Tag = @('Unit')
    }
    'Integration' {
        $PesterConfiguration.Filter.Tag = @('Integration')
    }
    'Security' {
        $PesterConfiguration.Filter.Tag = @('Security')
    }
    'CodeQuality' {
        $PesterConfiguration.Filter.Tag = @('CodeQuality')
    }
    'All' {
        # Run all tests - no filter needed
    }
}

# Run tests
try {
    $testResult = Invoke-Pester -Configuration $PesterConfiguration
    
    # Display summary
    Write-Host "`n" + "=" * 60
    Write-Host "Test Summary" -ForegroundColor Cyan
    Write-Host "=" * 60
    Write-Host "Total Tests: $($testResult.TotalCount)" -ForegroundColor White
    Write-Host "Passed: $($testResult.PassedCount)" -ForegroundColor Green
    Write-Host "Failed: $($testResult.FailedCount)" -ForegroundColor $(if ($testResult.FailedCount -gt 0) { 'Red' } else { 'Green' })
    Write-Host "Skipped: $($testResult.SkippedCount)" -ForegroundColor Yellow
    Write-Host "Duration: $($testResult.Duration)" -ForegroundColor Gray
    
    # Generate HTML report if requested
    if ($GenerateReport) {
        $htmlReport = Join-Path $OutputDirectory "TestReport.html"
        Write-Host "`nGenerating HTML report..." -ForegroundColor Blue
        
        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>GitHub Branch Protection Policy - Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f8f9fa; padding: 20px; border-radius: 5px; }
        .summary { margin: 20px 0; }
        .passed { color: green; }
        .failed { color: red; }
        .skipped { color: orange; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>GitHub Branch Protection Policy - Test Report</h1>
        <p>Generated: $(Get-Date)</p>
        <p>Test Type: $TestType</p>
    </div>
    
    <div class="summary">
        <h2>Summary</h2>
        <table>
            <tr><th>Metric</th><th>Value</th></tr>
            <tr><td>Total Tests</td><td>$($testResult.TotalCount)</td></tr>
            <tr><td>Passed</td><td class="passed">$($testResult.PassedCount)</td></tr>
            <tr><td>Failed</td><td class="failed">$($testResult.FailedCount)</td></tr>
            <tr><td>Skipped</td><td class="skipped">$($testResult.SkippedCount)</td></tr>
            <tr><td>Duration</td><td>$($testResult.Duration)</td></tr>
        </table>
    </div>
    
    <div class="details">
        <h2>Test Details</h2>
        <p>For detailed test results, see the XML output file.</p>
    </div>
</body>
</html>
"@
        
        $htmlContent | Out-File -FilePath $htmlReport -Encoding UTF8
        Write-Host "✅ HTML report generated: $htmlReport" -ForegroundColor Green
    }
    
    # Output file information
    if ($OutputFormat -ne 'Console' -and $outputFile) {
        Write-Host "✅ Test results saved: $outputFile" -ForegroundColor Green
    }
    
    # Exit with appropriate code
    if ($testResult.FailedCount -gt 0) {
        Write-Host "`n❌ Some tests failed!" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "`n✅ All tests passed!" -ForegroundColor Green
        exit 0
    }
}
catch {
    Write-Error "❌ Test execution failed: $($_.Exception.Message)"
    exit 1
}
