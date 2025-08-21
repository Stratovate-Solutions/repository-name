#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Fix common YAML linting issues in .github org repository
.DESCRIPTION
    This script fixes common yamllint issues like line endings, trailing spaces, and missing newlines
.EXAMPLE
    .\fix-yaml-issues.ps1
#>

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Colors for output
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = $Reset
    )
    Write-Host "${Color}${Message}${Reset}"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✓ $Message" $Green
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠ $Message" $Yellow
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "✗ $Message" $Red
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "ℹ $Message" $Blue
}

function Fix-YamlFile {
    param(
        [string]$FilePath,
        [switch]$DryRun
    )
    
    Write-Info "Processing: $FilePath"
    
    # Read file content
    $content = Get-Content -Path $FilePath -Raw
    $originalContent = $content
    $changes = @()
    
    # Fix line endings (Windows CRLF to Unix LF)
    if ($content -match "`r`n") {
        $content = $content -replace "`r`n", "`n"
        $changes += "Fixed line endings (CRLF -> LF)"
    }
    
    # Fix trailing spaces
    $lines = $content -split "`n"
    $fixedLines = @()
    $trailingSpaceCount = 0
    
    foreach ($line in $lines) {
        $originalLine = $line
        $trimmedLine = $line -replace '\s+$', ''
        if ($originalLine -ne $trimmedLine) {
            $trailingSpaceCount++
        }
        $fixedLines += $trimmedLine
    }
    
    if ($trailingSpaceCount -gt 0) {
        $content = $fixedLines -join "`n"
        $changes += "Removed trailing spaces from $trailingSpaceCount lines"
    }
    
    # Ensure file ends with newline
    if (-not $content.EndsWith("`n")) {
        $content += "`n"
        $changes += "Added newline at end of file"
    }
    
    # Fix long lines by breaking them at logical points (basic implementation)
    $lines = $content -split "`n"
    $fixedLines = @()
    $longLineCount = 0
    
    foreach ($line in $lines) {
        if ($line.Length -gt 120) {
            $longLineCount++
            # For now, just report long lines - manual fixing might be needed
            Write-Warning "  Line too long ($(($line.Length)) chars): $($line.Substring(0, [Math]::Min(50, $line.Length)))..."
        }
        $fixedLines += $line
    }
    
    if ($longLineCount -gt 0) {
        Write-Warning "  Found $longLineCount lines longer than 120 characters (manual review needed)"
    }
    
    # Write changes
    if ($changes.Count -gt 0) {
        if ($DryRun) {
            Write-Info "  Would make changes:"
            foreach ($change in $changes) {
                Write-Info "    - $change"
            }
        } else {
            # Write file with UTF-8 encoding and Unix line endings
            [System.IO.File]::WriteAllText($FilePath, $content, [System.Text.UTF8Encoding]::new($false))
            Write-Success "  Fixed:"
            foreach ($change in $changes) {
                Write-Success "    - $change"
            }
        }
    } else {
        Write-Success "  No issues found"
    }
    
    return $changes.Count
}

# Main execution
if ($DryRun) {
    Write-Info "Running in DRY RUN mode - no files will be modified"
}

Write-Info "Fixing YAML linting issues..."

# Find all YAML files
$yamlFiles = @()
$yamlFiles += Get-ChildItem -Path ".github" -Filter "*.yml" -Recurse
$yamlFiles += Get-ChildItem -Path ".github" -Filter "*.yaml" -Recurse
$yamlFiles += Get-ChildItem -Path "." -Filter "*.yml" | Where-Object { $_.FullName -notmatch "\.github\\workflows" }
$yamlFiles += Get-ChildItem -Path "." -Filter "*.yaml" | Where-Object { $_.FullName -notmatch "\.github\\workflows" }

if ($yamlFiles.Count -eq 0) {
    Write-Warning "No YAML files found"
    exit 0
}

Write-Info "Found $($yamlFiles.Count) YAML files to process"

$totalChanges = 0
$processedFiles = 0

foreach ($file in $yamlFiles) {
    $changes = Fix-YamlFile -FilePath $file.FullName -DryRun:$DryRun
    $totalChanges += $changes
    $processedFiles++
}

Write-Info "Processing completed"
Write-Info "Files processed: $processedFiles"

if ($DryRun) {
    Write-Info "Total changes that would be made: $totalChanges"
    Write-Info "Run without -DryRun to apply changes"
} else {
    Write-Success "Total changes made: $totalChanges"
    
    if ($totalChanges -gt 0) {
        Write-Info "Run the validation script again to check for remaining issues:"
        Write-Info "  .\validate-github-config.ps1"
    }
}
