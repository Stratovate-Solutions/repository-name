#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Example usage patterns for the GitHub Branch Protection Policy script

.DESCRIPTION
    This file contains practical examples demonstrating various ways to use
    the BranchProtectionPolicy.ps1 script for different scenarios.
#>

# ============================================================================
# Basic Usage Examples
# ============================================================================

Write-Host "GitHub Branch Protection Policy - Usage Examples" -ForegroundColor Cyan
Write-Host "=" * 60

# Example 1: Basic usage with default settings
Write-Host "`n1. Basic Usage with Default Settings:" -ForegroundColor Yellow
$example1 = @'
# Apply default protection to all predefined repositories
.\BranchProtectionPolicy.ps1 -GithubPAT "ghp_your_token_here"
'@
Write-Host $example1 -ForegroundColor Gray

# Example 2: Protect specific repositories
Write-Host "`n2. Protect Specific Repositories:" -ForegroundColor Yellow
$example2 = @'
# Target specific repositories only
.\BranchProtectionPolicy.ps1 -GithubPAT "ghp_your_token_here" -Repos @(
    "Stratovate-Solutions/TeamsSurveyConfig",
    "Stratovate-Solutions/TeamsVoiceDiscovery"
)
'@
Write-Host $example2 -ForegroundColor Gray

# Example 3: Protect different branch
Write-Host "`n3. Protect Development Branch:" -ForegroundColor Yellow
$example3 = @'
# Protect develop branch instead of main
.\BranchProtectionPolicy.ps1 -GithubPAT "ghp_your_token_here" -Branch "develop"
'@
Write-Host $example3 -ForegroundColor Gray

# Example 4: Enhanced security with multiple reviewers
Write-Host "`n4. Enhanced Security (Multiple Reviewers):" -ForegroundColor Yellow
$example4 = @'
# Require 2 reviewers for high-security repositories
.\BranchProtectionPolicy.ps1 -GithubPAT "ghp_your_token_here" -RequiredReviewers 2
'@
Write-Host $example4 -ForegroundColor Gray

# Example 5: WhatIf mode for testing
Write-Host "`n5. Preview Mode (WhatIf):" -ForegroundColor Yellow
$example5 = @'
# Test what would be applied without making changes
.\BranchProtectionPolicy.ps1 -GithubPAT "ghp_your_token_here" -WhatIf
'@
Write-Host $example5 -ForegroundColor Gray

# ============================================================================
# Advanced Usage Examples
# ============================================================================

Write-Host "`n" + "=" * 60
Write-Host "Advanced Usage Patterns" -ForegroundColor Cyan
Write-Host "=" * 60

# Example 6: Secure token handling
Write-Host "`n6. Secure Token Storage:" -ForegroundColor Yellow
$example6 = @'
# Store token securely (one-time setup)
$securePath = "$env:USERPROFILE\.github"
New-Item -ItemType Directory -Path $securePath -Force
$token = Read-Host "Enter GitHub PAT" -AsSecureString
$token | ConvertFrom-SecureString | Out-File "$securePath\github-pat.txt"

# Use stored token
$secureString = Get-Content "$env:USERPROFILE\.github\github-pat.txt" | ConvertTo-SecureString
$plainToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
)
.\BranchProtectionPolicy.ps1 -GithubPAT $plainToken
'@
Write-Host $example6 -ForegroundColor Gray

# Example 7: Batch processing with error handling
Write-Host "`n7. Batch Processing with Error Handling:" -ForegroundColor Yellow
$example7 = @'
# Process repositories in categories with error handling
$criticalRepos = @(
    "Stratovate-Solutions/Teams-Health-Toolkit",
    "Stratovate-Solutions/TeamsPhoneProvisioning"
)

$standardRepos = @(
    "Stratovate-Solutions/TeamsSurveyConfig",
    "Stratovate-Solutions/TeamsVoiceDiscovery"
)

# Apply strict protection to critical repos
try {
    .\BranchProtectionPolicy.ps1 -GithubPAT $token -Repos $criticalRepos -RequiredReviewers 2
    Write-Host "✅ Critical repositories protected" -ForegroundColor Green
}
catch {
    Write-Error "❌ Failed to protect critical repositories: $($_.Exception.Message)"
}

# Apply standard protection to other repos
try {
    .\BranchProtectionPolicy.ps1 -GithubPAT $token -Repos $standardRepos -RequiredReviewers 1
    Write-Host "✅ Standard repositories protected" -ForegroundColor Green
}
catch {
    Write-Error "❌ Failed to protect standard repositories: $($_.Exception.Message)"
}
'@
Write-Host $example7 -ForegroundColor Gray

# Example 8: Multi-branch protection
Write-Host "`n8. Multi-Branch Protection:" -ForegroundColor Yellow
$example8 = @'
# Protect multiple branches in each repository
$repos = @("owner/repo1", "owner/repo2")
$branches = @("main", "develop", "release")

foreach ($repo in $repos) {
    foreach ($branch in $branches) {
        Write-Host "Protecting $repo/$branch..." -ForegroundColor Blue
        .\BranchProtectionPolicy.ps1 -GithubPAT $token -Repos @($repo) -Branch $branch
        Start-Sleep -Seconds 1  # Rate limiting
    }
}
'@
Write-Host $example8 -ForegroundColor Gray

# ============================================================================
# Monitoring and Reporting Examples
# ============================================================================

Write-Host "`n" + "=" * 60
Write-Host "Monitoring and Reporting" -ForegroundColor Cyan
Write-Host "=" * 60

# Example 9: Log analysis
Write-Host "`n9. Analyzing Results:" -ForegroundColor Yellow
$example9 = @'
# Analyze protection results from CSV files
$resultsPath = Join-Path $PSScriptRoot "logs"
$latestResults = Get-ChildItem -Path $resultsPath -Filter "BranchProtection_Results_*.csv" | 
    Sort-Object LastWriteTime -Descending | 
    Select-Object -First 1

if ($latestResults) {
    $data = Import-Csv -Path $latestResults.FullName
    
    Write-Host "Protection Summary:" -ForegroundColor Green
    Write-Host "  Total Repositories: $($data.Count)"
    Write-Host "  Successful: $($data | Where-Object Status -eq 'Success' | Measure-Object | Select-Object -ExpandProperty Count)"
    Write-Host "  Failed: $($data | Where-Object Status -eq 'Failed' | Measure-Object | Select-Object -ExpandProperty Count)"
    
    # Show failures
    $failures = $data | Where-Object Status -eq 'Failed'
    if ($failures) {
        Write-Host "`nFailures:" -ForegroundColor Red
        $failures | ForEach-Object {
            Write-Host "  $($_.Repository): $($_.Error)" -ForegroundColor Red
        }
    }
}
'@
Write-Host $example9 -ForegroundColor Gray

# Example 10: Scheduled automation
Write-Host "`n10. Scheduled Automation:" -ForegroundColor Yellow
$example10 = @'
# Create a scheduled task for regular protection enforcement
$action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"$PSScriptRoot\BranchProtectionPolicy.ps1`" -GithubPAT `"$token`""
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At 2AM
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit (New-TimeSpan -Hours 1)

Register-ScheduledTask -TaskName "GitHub-BranchProtection-Weekly" -Action $action -Trigger $trigger -Settings $settings -Description "Weekly GitHub branch protection enforcement"
'@
Write-Host $example10 -ForegroundColor Gray

Write-Host "`n" + "=" * 60
Write-Host "For more information, see the README.md file" -ForegroundColor Green
Write-Host "=" * 60
