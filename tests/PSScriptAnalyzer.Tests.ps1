#!/usr/bin/env pwsh
<#
.SYNOPSIS
    PSScriptAnalyzer tests for the GitHub Branch Protection Policy project

.DESCRIPTION
    Comprehensive code quality and best practices validation using PSScriptAnalyzer.
    Tests all PowerShell scripts in the project for compliance with PowerShell
    best practices, security guidelines, and coding standards.

.NOTES
    Author: Stratovate Solutions DevOps Team
    Requires: PSScriptAnalyzer 1.18+, Pester 5.0+
#>

BeforeAll {
    # Check if PSScriptAnalyzer is available
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
        throw "❌ Failed to load PSScriptAnalyzer module: $($_.Exception.Message)"
    }

    # Define project root and get all PowerShell files
    $script:ProjectRoot = Split-Path $PSScriptRoot -Parent
    $script:PowerShellFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Include "*.ps1", "*.psm1", "*.psd1" | 
        Where-Object { $_.FullName -notlike "*\.git\*" -and $_.FullName -notlike "*TestResults*" }
    
    # Use custom PSScriptAnalyzer settings if available
    $script:AnalyzerSettings = Join-Path $ProjectRoot "PSScriptAnalyzerSettings.psd1"
    if (-not (Test-Path $script:AnalyzerSettings)) {
        $script:AnalyzerSettings = $null
    }
}

Describe "PSScriptAnalyzer - Code Quality Analysis" -Tag @('CodeQuality', 'Static') {
    
    Context "PowerShell Files Discovery" {
        It "Should find PowerShell files in the project" {
            $script:PowerShellFiles | Should -Not -BeNullOrEmpty
            $script:PowerShellFiles.Count | Should -BeGreaterThan 0
        }

        It "Should include the main BranchProtectionPolicy.ps1 script" {
            $mainScript = $script:PowerShellFiles | Where-Object { $_.Name -eq "BranchProtectionPolicy.ps1" }
            $mainScript | Should -Not -BeNullOrEmpty
        }

        It "Should include test files" {
            $testFiles = $script:PowerShellFiles | Where-Object { $_.Name -like "*.Tests.ps1" }
            $testFiles | Should -Not -BeNullOrEmpty
        }
    }

    Context "Standard Rules Compliance" {
        BeforeAll {
            $script:AllIssues = @()
            foreach ($file in $script:PowerShellFiles) {
                if ($script:AnalyzerSettings) {
                    $issues = Invoke-ScriptAnalyzer -Path $file.FullName -Settings $script:AnalyzerSettings
                } else {
                    $issues = Invoke-ScriptAnalyzer -Path $file.FullName -Severity @('Error', 'Warning')
                }
                if ($issues) {
                    $script:AllIssues += $issues
                }
            }
        }

        It "Should pass all critical PSScriptAnalyzer rules" {
            $criticalIssues = $script:AllIssues | Where-Object { $_.Severity -eq 'Error' }
            if ($criticalIssues) {
                $issueDetails = $criticalIssues | ForEach-Object {
                    "File: $($_.ScriptName), Line: $($_.Line), Rule: $($_.RuleName), Message: $($_.Message)"
                }
                $criticalIssues | Should -BeNullOrEmpty -Because "Critical issues found:`n$($issueDetails -join "`n")"
            }
        }

        It "Should have acceptable warning-level issues" {
            $warningIssues = $script:AllIssues | Where-Object { $_.Severity -eq 'Warning' }
            if ($warningIssues -and $warningIssues.Count -gt 20) {
                $issueDetails = $warningIssues | Select-Object -First 10 | ForEach-Object {
                    "File: $($_.ScriptName), Line: $($_.Line), Rule: $($_.RuleName)"
                }
                Write-Warning "Found $($warningIssues.Count) warning-level issues (showing first 10):`n$($issueDetails -join "`n")"
            }
            # Allow up to 20 warnings for this project type
            if ($warningIssues) {
                $warningIssues.Count | Should -BeLessOrEqual 20 -Because "Too many warning-level issues found"
            }
        }

        It "Should have proper comment-based help in main scripts" {
            $helpIssues = $script:AllIssues | Where-Object { 
                $_.RuleName -eq 'PSProvideCommentHelp' -and 
                $_.ScriptName -like "*BranchProtectionPolicy.ps1" 
            }
            $helpIssues | Should -BeNullOrEmpty -Because "Main script should have proper help documentation"
        }
    }

    Context "Security Rules Compliance" {
        BeforeAll {
            $securityRules = @(
                'PSAvoidUsingConvertToSecureStringWithPlainText',
                'PSAvoidUsingPlainTextForPassword',
                'PSAvoidUsingUsernameAndPasswordParams',
                'PSAvoidUsingInvokeExpression',
                'PSAvoidUsingComputerNameHardcoded',
                'PSAvoidGlobalVars'
            )
            
            $script:SecurityIssues = @()
            foreach ($file in $script:PowerShellFiles) {
                $issues = Invoke-ScriptAnalyzer -Path $file.FullName -IncludeRule $securityRules
                if ($issues) {
                    $script:SecurityIssues += $issues
                }
            }
        }

        It "Should not have critical security violations" {
            $criticalSecurityIssues = $script:SecurityIssues | Where-Object { 
                $_.Severity -eq 'Error' -or 
                ($_.Severity -eq 'Warning' -and $_.RuleName -in @(
                    'PSAvoidUsingPlainTextForPassword',
                    'PSAvoidUsingConvertToSecureStringWithPlainText',
                    'PSAvoidUsingUsernameAndPasswordParams'
                ))
            }
            
            if ($criticalSecurityIssues) {
                $issueDetails = $criticalSecurityIssues | ForEach-Object {
                    "File: $($_.ScriptName), Line: $($_.Line), Rule: $($_.RuleName), Message: $($_.Message)"
                }
                $criticalSecurityIssues | Should -BeNullOrEmpty -Because "Critical security issues found:`n$($issueDetails -join "`n")"
            }
        }

        It "Should handle Invoke-Expression usage appropriately" {
            $invokeExpressionIssues = $script:SecurityIssues | Where-Object { 
                $_.RuleName -eq 'PSAvoidUsingInvokeExpression' 
            }
            # Allow some Invoke-Expression usage but warn about it
            if ($invokeExpressionIssues -and $invokeExpressionIssues.Count -gt 2) {
                $invokeExpressionIssues.Count | Should -BeLessOrEqual 2 -Because "Too many instances of Invoke-Expression usage"
            }
        }

        It "Should not use plain text passwords" {
            $passwordIssues = $script:SecurityIssues | Where-Object { 
                $_.RuleName -in @('PSAvoidUsingPlainTextForPassword', 'PSAvoidUsingConvertToSecureStringWithPlainText') 
            }
            $passwordIssues | Should -BeNullOrEmpty -Because "Plain text password usage detected"
        }

        It "Should not have hardcoded computer names" {
            $hardcodedComputerIssues = $script:SecurityIssues | Where-Object { 
                $_.RuleName -eq 'PSAvoidUsingComputerNameHardcoded' 
            }
            $hardcodedComputerIssues | Should -BeNullOrEmpty -Because "Hardcoded computer names detected"
        }
    }

    Context "Performance Rules Compliance" {
        BeforeAll {
            $performanceRules = @(
                'PSAvoidUsingWMICmdlet',
                'PSUseCmdletCorrectly',
                'PSUseCompatibleCmdlets',
                'PSUseDeclaredVarsMoreThanAssignments'
            )
            
            $script:PerformanceIssues = @()
            foreach ($file in $script:PowerShellFiles) {
                $issues = Invoke-ScriptAnalyzer -Path $file.FullName -IncludeRule $performanceRules
                if ($issues) {
                    $script:PerformanceIssues += $issues
                }
            }
        }

        It "Should follow performance best practices" {
            $criticalPerformanceIssues = $script:PerformanceIssues | Where-Object { $_.Severity -eq 'Error' }
            if ($criticalPerformanceIssues) {
                $issueDetails = $criticalPerformanceIssues | ForEach-Object {
                    "File: $($_.ScriptName), Line: $($_.Line), Rule: $($_.RuleName), Message: $($_.Message)"
                }
                $criticalPerformanceIssues | Should -BeNullOrEmpty -Because "Performance issues found:`n$($issueDetails -join "`n")"
            }
        }

        It "Should avoid deprecated WMI cmdlets" {
            $wmiIssues = $script:PerformanceIssues | Where-Object { 
                $_.RuleName -eq 'PSAvoidUsingWMICmdlet' 
            }
            $wmiIssues | Should -BeNullOrEmpty -Because "Deprecated WMI cmdlets should be replaced with CIM cmdlets"
        }
    }

    Context "Code Style and Formatting" {
        BeforeAll {
            $styleRules = @(
                'PSUseConsistentIndentation',
                'PSUseConsistentWhitespace', 
                'PSPlaceOpenBrace',
                'PSPlaceCloseBrace',
                'PSUseCorrectCasing'
            )
            
            $script:StyleIssues = @()
            foreach ($file in $script:PowerShellFiles) {
                $issues = Invoke-ScriptAnalyzer -Path $file.FullName -IncludeRule $styleRules
                if ($issues) {
                    $script:StyleIssues += $issues
                }
            }
        }

        It "Should follow consistent indentation" {
            $indentationIssues = $script:StyleIssues | Where-Object { 
                $_.RuleName -eq 'PSUseConsistentIndentation' 
            }
            # Allow some flexibility but flag excessive violations
            if ($indentationIssues -and $indentationIssues.Count -gt 15) {
                $indentationIssues.Count | Should -BeLessOrEqual 15 -Because "Too many indentation inconsistencies"
            }
        }

        It "Should follow consistent whitespace usage" {
            $whitespaceIssues = $script:StyleIssues | Where-Object { 
                $_.RuleName -eq 'PSUseConsistentWhitespace' 
            }
            # Allow some flexibility for legacy code
            if ($whitespaceIssues -and $whitespaceIssues.Count -gt 10) {
                $whitespaceIssues.Count | Should -BeLessOrEqual 10 -Because "Too many whitespace inconsistencies"
            }
        }

        It "Should follow PowerShell casing conventions" {
            $casingIssues = $script:StyleIssues | Where-Object { 
                $_.RuleName -eq 'PSUseCorrectCasing' 
            }
            $casingIssues | Should -BeNullOrEmpty -Because "Casing convention violations found"
        }
    }

    Context "Individual File Analysis" {
        It "Should analyze main script: BranchProtectionPolicy.ps1" {
            $mainScript = $script:PowerShellFiles | Where-Object { $_.Name -eq "BranchProtectionPolicy.ps1" }
            if ($mainScript) {
                $issues = Invoke-ScriptAnalyzer -Path $mainScript.FullName
                $errorIssues = $issues | Where-Object { $_.Severity -eq 'Error' }
                $errorIssues | Should -BeNullOrEmpty -Because "Main script should not have any errors"
            }
        }

        It "Should analyze test runner: Run-Tests.ps1" {
            $testRunner = $script:PowerShellFiles | Where-Object { $_.Name -eq "Run-Tests.ps1" }
            if ($testRunner) {
                $issues = Invoke-ScriptAnalyzer -Path $testRunner.FullName
                $errorIssues = $issues | Where-Object { $_.Severity -eq 'Error' }
                $errorIssues | Should -BeNullOrEmpty -Because "Test runner should not have any errors"
            }
        }

        It "Should analyze all test files" {
            $testFiles = $script:PowerShellFiles | Where-Object { $_.Name -like "*.Tests.ps1" }
            foreach ($testFile in $testFiles) {
                $issues = Invoke-ScriptAnalyzer -Path $testFile.FullName
                $errorIssues = $issues | Where-Object { $_.Severity -eq 'Error' }
                $errorIssues | Should -BeNullOrEmpty -Because "Test file $($testFile.Name) should not have any errors"
            }
        }
    }
}

Describe "PSScriptAnalyzer - Custom Rules and Settings" -Tag @('CodeQuality', 'Custom') {
    
    Context "Project-Specific Rules" {
        It "Should not contain TODO or FIXME comments in main scripts" {
            $mainFiles = $script:PowerShellFiles | Where-Object { 
                $_.Name -eq "BranchProtectionPolicy.ps1"  # Only check the main script
            }
            
            foreach ($file in $mainFiles) {
                $content = Get-Content -Path $file.FullName -Raw
                $todoMatches = [regex]::Matches($content, '\b(TODO|FIXME|HACK)\b', 'IgnoreCase')
                $todoMatches.Count | Should -Be 0 -Because "File $($file.Name) should not contain TODO/FIXME/HACK comments"
            }
        }

        It "Should have proper error handling in main scripts" {
            $mainFiles = $script:PowerShellFiles | Where-Object { 
                $_.Name -eq "BranchProtectionPolicy.ps1" 
            }
            
            foreach ($file in $mainFiles) {
                $content = Get-Content -Path $file.FullName -Raw
                # Check for try-catch blocks
                $hasTryCatch = $content -match '\btry\s*\{[\s\S]*?\}\s*catch\s*\{'
                $hasTryCatch | Should -Be $true -Because "Main script should have try-catch error handling"
            }
        }

        It "Should use proper parameter validation" {
            $mainScript = $script:PowerShellFiles | Where-Object { $_.Name -eq "BranchProtectionPolicy.ps1" }
            if ($mainScript) {
                $content = Get-Content -Path $mainScript.FullName -Raw
                # Check for parameter validation attributes
                $hasValidation = $content -match '\[ValidateSet\(|\[ValidatePattern\(|\[ValidateScript\('
                $hasValidation | Should -Be $true -Because "Main script should use parameter validation"
            }
        }
    }

    Context "Documentation Standards" {
        It "Should have .SYNOPSIS in all main scripts" {
            $mainFiles = $script:PowerShellFiles | Where-Object { 
                $_.Name -notlike "*.Tests.ps1" -and $_.Extension -eq ".ps1"
            }
            
            foreach ($file in $mainFiles) {
                $content = Get-Content -Path $file.FullName -Raw
                $hasSynopsis = $content -match '\.SYNOPSIS'
                $hasSynopsis | Should -Be $true -Because "File $($file.Name) should have .SYNOPSIS documentation"
            }
        }

        It "Should have .DESCRIPTION in main script" {
            $mainScript = $script:PowerShellFiles | Where-Object { $_.Name -eq "BranchProtectionPolicy.ps1" }
            if ($mainScript) {
                $content = Get-Content -Path $mainScript.FullName -Raw
                $hasDescription = $content -match '\.DESCRIPTION'
                $hasDescription | Should -Be $true -Because "Main script should have .DESCRIPTION documentation"
            }
        }

        It "Should have .EXAMPLE in main script" {
            $mainScript = $script:PowerShellFiles | Where-Object { $_.Name -eq "BranchProtectionPolicy.ps1" }
            if ($mainScript) {
                $content = Get-Content -Path $mainScript.FullName -Raw
                $hasExample = $content -match '\.EXAMPLE'
                $hasExample | Should -Be $true -Because "Main script should have .EXAMPLE documentation"
            }
        }
    }
}

Describe "PSScriptAnalyzer - Reporting and Metrics" -Tag @('CodeQuality', 'Metrics') {
    
    Context "Overall Quality Metrics" {
        BeforeAll {
            $script:AllAnalysisIssues = @()
            foreach ($file in $script:PowerShellFiles) {
                if ($script:AnalyzerSettings) {
                    $issues = Invoke-ScriptAnalyzer -Path $file.FullName -Settings $script:AnalyzerSettings
                } else {
                    $issues = Invoke-ScriptAnalyzer -Path $file.FullName -Severity @('Error', 'Warning')
                }
                if ($issues) {
                    $script:AllAnalysisIssues += $issues
                }
            }
        }

        It "Should have acceptable overall issue count" {
            $totalIssues = $script:AllAnalysisIssues.Count
            $errorCount = ($script:AllAnalysisIssues | Where-Object { $_.Severity -eq 'Error' }).Count
            $warningCount = ($script:AllAnalysisIssues | Where-Object { $_.Severity -eq 'Warning' }).Count
            
            Write-Host "PSScriptAnalyzer Summary:" -ForegroundColor Cyan
            Write-Host "  Total Issues: $totalIssues" -ForegroundColor White
            Write-Host "  Errors: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { 'Red' } else { 'Green' })
            Write-Host "  Warnings: $warningCount" -ForegroundColor $(if ($warningCount -gt 10) { 'Yellow' } else { 'Green' })
            Write-Host "  Files Analyzed: $($script:PowerShellFiles.Count)" -ForegroundColor White
            
            # Fail on any errors
            $errorCount | Should -Be 0 -Because "No errors should be present in the codebase"
        }

        It "Should generate detailed issue report" {
            if ($script:AllAnalysisIssues) {
                $reportPath = Join-Path $PSScriptRoot ".." "TestResults" "PSScriptAnalyzer-Report.txt"
                $reportDir = Split-Path $reportPath -Parent
                if (-not (Test-Path $reportDir)) {
                    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
                }
                
                $reportContent = @"
PSScriptAnalyzer Analysis Report
Generated: $(Get-Date)
======================================

Summary:
  Total Files Analyzed: $($script:PowerShellFiles.Count)
  Total Issues: $($script:AllAnalysisIssues.Count)
  Errors: $(($script:AllAnalysisIssues | Where-Object { $_.Severity -eq 'Error' }).Count)
  Warnings: $(($script:AllAnalysisIssues | Where-Object { $_.Severity -eq 'Warning' }).Count)
  Information: $(($script:AllAnalysisIssues | Where-Object { $_.Severity -eq 'Information' }).Count)

Detailed Issues:
================

"@
                
                foreach ($issue in ($script:AllAnalysisIssues | Sort-Object Severity, ScriptName, Line)) {
                    $reportContent += @"
File: $($issue.ScriptName)
Line: $($issue.Line), Column: $($issue.Column)
Severity: $($issue.Severity)
Rule: $($issue.RuleName)
Message: $($issue.Message)
---

"@
                }
                
                $reportContent | Out-File -FilePath $reportPath -Encoding UTF8
                Write-Host "✅ PSScriptAnalyzer report saved: $reportPath" -ForegroundColor Green
            }
            
            # Test always passes - this is just for reporting
            $true | Should -Be $true
        }
    }
}
