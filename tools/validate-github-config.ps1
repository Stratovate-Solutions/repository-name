#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Local validation script for .github organization configuration
.DESCRIPTION
    This script runs the same linting and validation checks locally that are performed in CI/CD
.PARAMETER SkipInstall
    Skip installation of required tools
.PARAMETER Verbose
    Show detailed output
.EXAMPLE
    .\validate-github-config.ps1
.EXAMPLE
    .\validate-github-config.ps1 -SkipInstall -Verbose
#>

param(
    [switch]$SkipInstall,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Colors for output
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

<#
.SYNOPSIS
    Writes colored output to the console.
.DESCRIPTION
    Helper function to write colored text output to the console using ANSI escape codes.
.PARAMETER Message
    The message to display.
.PARAMETER Color
    The ANSI color code to use. Defaults to reset.
#>
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = $Reset
    )
    Write-Host "${Color}${Message}${Reset}"
}

<#
.SYNOPSIS
    Writes a success message with green color and checkmark.
.DESCRIPTION
    Helper function to write success messages in a consistent format.
.PARAMETER Message
    The success message to display.
#>
function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✓ $Message" $Green
}

<#
.SYNOPSIS
    Writes a warning message with yellow color and warning symbol.
.DESCRIPTION
    Helper function to write warning messages in a consistent format.
.PARAMETER Message
    The warning message to display.
#>
function Write-WarningMessage {
    param([string]$Message)
    Write-ColorOutput "⚠ $Message" $Yellow
}

<#
.SYNOPSIS
    Writes an error message with red color and error symbol.
.DESCRIPTION
    Helper function to write error messages in a consistent format.
.PARAMETER Message
    The error message to display.
#>
function Write-ErrorMessage {
    param([string]$Message)
    Write-ColorOutput "✗ $Message" $Red
}

<#
.SYNOPSIS
    Writes an informational message with blue color and info symbol.
.DESCRIPTION
    Helper function to write informational messages in a consistent format.
.PARAMETER Message
    The informational message to display.
#>
function Write-Info {
    param([string]$Message)
    Write-ColorOutput "ℹ $Message" $Blue
}

<#
.SYNOPSIS
    Tests if a command exists in the current session.
.DESCRIPTION
    Helper function to check if a command is available before attempting to use it.
.PARAMETER Command
    The command name to test.
.OUTPUTS
    Boolean indicating whether the command exists.
#>
function Test-CommandExists {
    param([string]$Command)
    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

<#
.SYNOPSIS
    Gets the Python scripts directory path.
.DESCRIPTION
    Locates the Python scripts directory by checking pip installation location and common paths.
.OUTPUTS
    String path to Python scripts directory, or null if not found.
#>
function Get-PythonScriptsPath {
    # Get Python scripts directory from pip show
    try {
        $pipShow = python -m pip show pip 2>$null
        if ($pipShow) {
            $location = ($pipShow | Select-String "Location:").ToString().Split(":")[1].Trim()
            $scriptsPath = Join-Path $location "Scripts"
            if (Test-Path $scriptsPath) {
                return $scriptsPath
            }
        }
        
        # Fallback: try common Python paths
        $pythonExe = Get-Command python -ErrorAction SilentlyContinue
        if ($pythonExe) {
            $pythonDir = Split-Path $pythonExe.Source
            $scriptsPath = Join-Path $pythonDir "Scripts"
            if (Test-Path $scriptsPath) {
                return $scriptsPath
            }
        }
        
        # Try user-specific path (from the warning message)
        $userScripts = "$env:LOCALAPPDATA\Packages\PythonSoftwareFoundation.Python.3.13_qbz5n2kfra8p0\LocalCache\local-packages\Python313\Scripts"
        if (Test-Path $userScripts) {
            return $userScripts
        }
        
        return $null
    } catch {
        return $null
    }
}

<#
.SYNOPSIS
    Invokes yamllint to validate YAML files.
.DESCRIPTION
    Runs yamllint command with various fallback methods to validate YAML syntax and style.
.PARAMETER FilePath
    Path to the YAML file to validate.
.PARAMETER ConfigFile
    Optional path to yamllint configuration file.
.OUTPUTS
    Output from yamllint command.
#>
function Invoke-YamlLint {
    param(
        [string]$FilePath,
        [string]$ConfigFile = $null
    )
    
    # Try direct command first
    if (Test-CommandExists "yamllint") {
        if ($ConfigFile) {
            return & yamllint -c $ConfigFile $FilePath 2>&1
        } else {
            return & yamllint $FilePath 2>&1
        }
    }
    
    # Try with Python scripts path
    $scriptsPath = Get-PythonScriptsPath
    if ($scriptsPath) {
        $yamlLintPath = Join-Path $scriptsPath "yamllint.exe"
        if (Test-Path $yamlLintPath) {
            if ($ConfigFile) {
                return & $yamlLintPath -c $ConfigFile $FilePath 2>&1
            } else {
                return & $yamlLintPath $FilePath 2>&1
            }
        }
    }
    
    # Try with python -m yamllint
    try {
        if ($ConfigFile) {
            return python -m yamllint -c $ConfigFile $FilePath 2>&1
        } else {
            return python -m yamllint $FilePath 2>&1
        }
    } catch {
        throw "yamllint not found. Please ensure it's installed with 'pip install yamllint'"
    }
}

<#
.SYNOPSIS
    Installs required tools for validation.
.DESCRIPTION
    Installs necessary Python packages and PowerShell modules required for GitHub configuration validation.
#>
function Install-RequiredTools {
    Write-Info "Installing required tools..."
    
    # Check if Python is installed
    if (-not (Test-CommandExists "python")) {
        Write-ErrorMessage "Python is not installed. Please install Python first."
        exit 1
    }
    
    # Install PowerShell-Yaml module if not available
    if (-not (Get-Module -ListAvailable -Name PowerShell-Yaml)) {
        Write-Info "Installing PowerShell-Yaml module..."
        try {
            Install-Module -Name PowerShell-Yaml -Force -Scope CurrentUser -AllowClobber
            Write-Success "PowerShell-Yaml module installed"
        } catch {
            Write-WarningMessage "Failed to install PowerShell-Yaml module: $_"
            Write-Info "Will use Python fallback for YAML parsing"
        }
    }
    
    # Install yamllint
    Write-Info "Installing yamllint..."
    try {
        python -m pip install yamllint --user
        Write-Success "yamllint installed"
    } catch {
        Write-ErrorMessage "Failed to install yamllint: $_"
    }
    
    # Check if Node.js is installed
    if (-not (Test-CommandExists "node")) {
        Write-WarningMessage "Node.js is not installed. Some schema validation will be skipped."
    } else {
        # Install markdownlint-cli2
        if (-not (Test-CommandExists "markdownlint-cli2")) {
            Write-Info "Installing markdownlint-cli2..."
            npm install -g markdownlint-cli2
        }
        
        # Install js-yaml and ajv-cli
        if (-not (Test-CommandExists "js-yaml")) {
            Write-Info "Installing js-yaml..."
            npm install -g js-yaml
        }
        
        if (-not (Test-CommandExists "ajv")) {
            Write-Info "Installing ajv-cli..."
            npm install -g ajv-cli
        }
    }
    
    Write-Success "Tool installation completed"
}

<#
.SYNOPSIS
    Tests and validates YAML files.
.DESCRIPTION
    Validates all YAML files in the .github directory using yamllint for syntax and style checking.
.PARAMETER Verbose
    Enable verbose output.
.OUTPUTS
    Number of errors found.
#>
function Test-YamlFiles {
    Write-Info "Linting YAML files..."
    
    $yamlFiles = Get-ChildItem -Path ".github" -Filter "*.yml" -Recurse
    $yamlFiles += Get-ChildItem -Path ".github" -Filter "*.yaml" -Recurse
    $yamlFiles += Get-ChildItem -Path "." -Filter "*.yml" | Where-Object { $_.FullName -notmatch "\.github\\workflows" }
    $yamlFiles += Get-ChildItem -Path "." -Filter "*.yaml" | Where-Object { $_.FullName -notmatch "\.github\\workflows" }
    
    if ($yamlFiles.Count -eq 0) {
        Write-WarningMessage "No YAML files found"
        return
    }
    
    $configFile = if (Test-Path ".yamllint.yml") { ".yamllint.yml" } else { $null }
    $errors = 0
    
    foreach ($file in $yamlFiles) {
        if ($Verbose) {
            Write-Info "Checking $($file.Name)..."
        }
        
        try {
            $result = Invoke-YamlLint -FilePath $file.FullName -ConfigFile $configFile
            
            if ($LASTEXITCODE -eq 0) {
                if ($Verbose) {
                    Write-Success "$($file.Name) passed YAML linting"
                }
            } else {
                Write-ErrorMessage "YAML linting failed for $($file.Name):"
                Write-Output $result
                $errors++
            }
        } catch {
            Write-ErrorMessage "Failed to lint $($file.Name): $_"
            $errors++
        }
    }
    
    if ($errors -eq 0) {
        Write-Success "All YAML files passed linting"
    } else {
        Write-ErrorMessage "$errors YAML files failed linting"
    }
    
    return $errors
}

<#
.SYNOPSIS
    Tests and validates Markdown files.
.DESCRIPTION
    Validates all Markdown files in the repository using markdownlint for style and formatting.
.PARAMETER Verbose
    Enable verbose output.
.OUTPUTS
    Number of errors found.
#>
function Test-MarkdownFiles {
    Write-Info "Linting Markdown files..."
    
    $markdownFiles = Get-ChildItem -Path "." -Filter "*.md" -Recurse | Where-Object { 
        $_.FullName -notmatch "node_modules" -and $_.FullName -notmatch "\.git"
    }
    
    if ($markdownFiles.Count -eq 0) {
        Write-WarningMessage "No Markdown files found"
        return 0
    }
    
    Write-Info "Found $($markdownFiles.Count) Markdown files"
    
    $configFile = if (Test-Path ".markdownlint.json") { ".markdownlint.json" } else { $null }
    $errors = 0
    
    if (Test-CommandExists "markdownlint-cli2") {
        try {
            $markdownPaths = $markdownFiles | ForEach-Object { 
                $relativePath = (Resolve-Path $_.FullName -Relative) -replace '^\.\\', ''
                $relativePath -replace '\\', '/'
            }
            
            # Build arguments array for direct execution
            $lintArgs = @()
            if ($configFile) {
                $lintArgs += "--config"
                $lintArgs += $configFile
            }
            $lintArgs += $markdownPaths
            
            if ($Verbose) {
                Write-Info "Running: markdownlint-cli2 $($lintArgs -join ' ')"
            }
            
            $result = & markdownlint-cli2 @lintArgs 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "All Markdown files passed linting"
            } else {
                Write-ErrorMessage "Markdown linting failed:"
                Write-Output $result
                $errors++
            }
        } catch {
            Write-ErrorMessage "Failed to lint Markdown files: $_"
            $errors++
        }
    } else {
        Write-WarningMessage "markdownlint-cli2 not available, skipping Markdown linting"
    }
    
    return $errors
}

<#
.SYNOPSIS
    Tests and validates JSON files.
.DESCRIPTION
    Validates all JSON files in the repository for proper syntax and structure.
.PARAMETER Verbose
    Enable verbose output.
.OUTPUTS
    Number of errors found.
#>
function Test-JsonFiles {
    Write-Info "Validating JSON files..."
    
    $jsonFiles = Get-ChildItem -Path "." -Filter "*.json" -Recurse | Where-Object { 
        $_.FullName -notmatch "node_modules" -and $_.FullName -notmatch "\.git"
    }
    
    if ($jsonFiles.Count -eq 0) {
        Write-WarningMessage "No JSON files found"
        return 0
    }
    
    $errors = 0
    
    foreach ($file in $jsonFiles) {
        if ($Verbose) {
            Write-Info "Validating $($file.Name)..."
        }
        
        try {
            $content = Get-Content $file.FullName -Raw | ConvertFrom-Json
            # Content loaded successfully, JSON is valid
            $null = $content  # Suppress unused variable warning
            if ($Verbose) {
                Write-Success "$($file.Name) is valid JSON"
            }
        } catch {
            Write-ErrorMessage "Invalid JSON in $($file.Name): $_"
            $errors++
        }
    }
    
    if ($errors -eq 0) {
        Write-Success "All JSON files are valid"
    } else {
        Write-ErrorMessage "$errors JSON files are invalid"
    }
    
    return $errors
}

<#
.SYNOPSIS
    Tests and validates GitHub issue templates.
.DESCRIPTION
    Validates GitHub issue templates for proper structure and required fields.
.PARAMETER Verbose
    Enable verbose output.
.OUTPUTS
    Number of errors found.
#>
function Test-IssueTemplates {
    Write-Info "Testing issue templates..."
    
    $templateDir = "ISSUE_TEMPLATE"
    if (-not (Test-Path $templateDir)) {
        Write-WarningMessage "Issue template directory not found"
        return 0
    }
    
    $templates = Get-ChildItem -Path $templateDir -Filter "*.yml"
    $templates += Get-ChildItem -Path $templateDir -Filter "*.yaml"
    $templates += Get-ChildItem -Path $templateDir -Filter "*.md"
    
    if ($templates.Count -eq 0) {
        Write-WarningMessage "No issue templates found"
        return 0
    }
    
    Write-Info "Found $($templates.Count) issue templates"
    
    $errors = 0
    
    foreach ($template in $templates) {
        if ($Verbose) {
            Write-Info "Testing $($template.Name)..."
        }
        
        if ($template.Extension -in @(".yml", ".yaml")) {
            # Skip config.yml as it's not an issue template but a configuration file
            if ($template.Name -eq "config.yml") {
                if ($Verbose) {
                    Write-Info "Skipping $($template.Name) (configuration file)"
                }
                continue
            }
            
            # Test YAML issue templates
            try {
                $content = Get-Content $template.FullName -Raw | ConvertFrom-Yaml
                
                $requiredFields = @("name", "description", "body")
                foreach ($field in $requiredFields) {
                    if (-not $content.$field) {
                        Write-ErrorMessage "$($template.Name) missing required field: $field"
                        $errors++
                    }
                }
                
                if ($errors -eq 0 -and $Verbose) {
                    Write-Success "$($template.Name) is valid"
                }
            } catch {
                Write-ErrorMessage "Failed to parse YAML template $($template.Name): $_"
                $errors++
            }
        } elseif ($template.Extension -eq ".md") {
            # Test Markdown issue templates
            $content = Get-Content $template.FullName -Raw
            
            if ($content -match "^---\r?\n") {
                if ($Verbose) {
                    Write-Success "$($template.Name) has YAML frontmatter"
                }
            } else {
                Write-WarningMessage "$($template.Name) may not have YAML frontmatter"
            }
        }
    }
    
    if ($errors -eq 0) {
        Write-Success "All issue templates are valid"
    } else {
        Write-ErrorMessage "$errors issue template issues found"
    }
    
    return $errors
}

<#
.SYNOPSIS
    Tests and validates GitHub pull request templates.
.DESCRIPTION
    Validates GitHub pull request templates for proper structure and formatting.
.PARAMETER Verbose
    Enable verbose output.
.OUTPUTS
    Number of errors found.
#>
function Test-PullRequestTemplates {
    Write-Info "Testing PR templates..."
    
    $prTemplates = @()
    
    # Check for PR templates in current directory
    if (Test-Path "PULL_REQUEST_TEMPLATE.md") {
        $prTemplates += "PULL_REQUEST_TEMPLATE.md"
    }
    
    if (Test-Path "pull_request_template.md") {
        $prTemplates += "pull_request_template.md"
    }
    
    # Check for PR templates in .github directory
    if (Test-Path ".github/PULL_REQUEST_TEMPLATE.md") {
        $prTemplates += ".github/PULL_REQUEST_TEMPLATE.md"
    }
    
    if (Test-Path ".github/pull_request_template.md") {
        $prTemplates += ".github/pull_request_template.md"
    }
    
    # Check for PR templates in .github/pull_request_template directory
    if (Test-Path ".github/pull_request_template") {
        $prTemplates += Get-ChildItem -Path ".github/pull_request_template" -Filter "*.md" | ForEach-Object { $_.FullName }
    }
    
    if ($prTemplates.Count -eq 0) {
        Write-WarningMessage "No PR templates found"
        return 0
    }
    
    Write-Info "Found $($prTemplates.Count) PR templates"
    
    $errors = 0
    
    foreach ($template in $prTemplates) {
        if ($Verbose) {
            Write-Info "Testing $template..."
        }
        
        if (Test-Path $template) {
            $content = Get-Content $template -Raw
            
            if ([string]::IsNullOrWhiteSpace($content)) {
                Write-ErrorMessage "PR template $template is empty"
                $errors++
            } else {
                if ($Verbose) {
                    Write-Success "$template exists and has content"
                }
                
                # Check for common sections
                if ($content -match "(?i)(description|summary|changes)") {
                    if ($Verbose) {
                        Write-Success "$template contains description section"
                    }
                }
                
                if ($content -match "(?i)(checklist|todo|\[ \])") {
                    if ($Verbose) {
                        Write-Success "$template contains checklist"
                    }
                }
            }
        }
    }
    
    if ($errors -eq 0) {
        Write-Success "All PR templates are valid"
    } else {
        Write-ErrorMessage "$errors PR template issues found"
    }
    
    return $errors
}

<#
.SYNOPSIS
    Tests and validates GitHub workflow files.
.DESCRIPTION
    Validates GitHub Actions workflow files for proper YAML syntax and structure.
.PARAMETER Verbose
    Enable verbose output.
.OUTPUTS
    Number of errors found.
#>
function Test-WorkflowFiles {
    Write-Info "Testing workflow files..."
    
    $workflowDir = ".github/workflows"
    if (-not (Test-Path $workflowDir)) {
        Write-WarningMessage "Workflows directory not found"
        return 0
    }
    
    $workflows = Get-ChildItem -Path $workflowDir -Filter "*.yml"
    $workflows += Get-ChildItem -Path $workflowDir -Filter "*.yaml"
    
    if ($workflows.Count -eq 0) {
        Write-WarningMessage "No workflow files found"
        return 0
    }
    
    $errors = 0
    
    foreach ($workflow in $workflows) {
        if ($Verbose) {
            Write-Info "Testing $($workflow.Name)..."
        }
        
        try {
            $content = Get-Content $workflow.FullName -Raw | ConvertFrom-Yaml
            
            $requiredFields = @("on", "jobs")
            foreach ($field in $requiredFields) {
                if (-not $content.$field) {
                    Write-ErrorMessage "$($workflow.Name) missing required field: $field"
                    $errors++
                }
            }
            
            if (-not $content.name) {
                Write-WarningMessage "$($workflow.Name) missing 'name' field"
            }
            
            if ($errors -eq 0 -and $Verbose) {
                Write-Success "$($workflow.Name) has valid structure"
            }
        } catch {
            Write-ErrorMessage "Failed to parse workflow $($workflow.Name): $_"
            $errors++
        }
    }
    
    if ($errors -eq 0) {
        Write-Success "All workflow files are valid"
    } else {
        Write-ErrorMessage "$errors workflow issues found"
    }
    
    return $errors
}

# Helper function to convert YAML (requires PowerShell-Yaml module)
<#
.SYNOPSIS
    Converts YAML string to PowerShell object.
.DESCRIPTION
    Converts YAML content to PowerShell objects using PowerShell-Yaml module or Python fallback.
.PARAMETER InputObject
    The YAML string to convert.
.OUTPUTS
    PowerShell object representation of the YAML content.
#>
function ConvertFrom-Yaml {
    param([string]$InputObject)
    
    # First try PowerShell-Yaml module
    if (Get-Module -ListAvailable -Name PowerShell-Yaml) {
        try {
            Import-Module PowerShell-Yaml -Force
            return ConvertFrom-Yaml $InputObject
        } catch {
            # PowerShell-Yaml module failed, continue to fallback methods
            Write-WarningMessage "PowerShell-Yaml module failed: $($_.Exception.Message)"
        }
    }
    
    # Fallback: try to use python with pyyaml
    if (Test-CommandExists "python") {
        $tempFile = [System.IO.Path]::GetTempFileName()
        try {
            # Write YAML content to temp file with UTF-8 encoding
            [System.IO.File]::WriteAllText($tempFile, $InputObject, [System.Text.Encoding]::UTF8)
            
            # Use Python to convert YAML to JSON
            $pythonScript = @"
import yaml
import json
import sys

try:
    with open('$($tempFile.Replace('\', '\\'))', 'r', encoding='utf-8') as f:
        data = yaml.safe_load(f)
    print(json.dumps(data, ensure_ascii=False))
except Exception as e:
    print(f"Error: {e}", file=sys.stderr)
    sys.exit(1)
"@
            
            $result = python -c $pythonScript 2>$null
            if ($LASTEXITCODE -eq 0 -and $result) {
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
                return $result | ConvertFrom-Json
            } else {
                throw "Python YAML parsing failed"
            }
        } catch {
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            throw "Failed to parse YAML with Python: $_"
        }
    }
    
    # Last resort: try basic PowerShell parsing for simple YAML
    try {
        # Very basic YAML parsing - only works for simple key-value pairs
        $lines = $InputObject -split "`n"
        $result = @{}
        
        foreach ($line in $lines) {
            $line = $line.Trim()
            if ($line -and !$line.StartsWith('#') -and $line.Contains(':')) {
                $parts = $line -split ':', 2
                if ($parts.Length -eq 2) {
                    $key = $parts[0].Trim()
                    $value = $parts[1].Trim()
                    if ($value) {
                        $result[$key] = $value
                    }
                }
            }
        }
        
        return [PSCustomObject]$result
    } catch {
        throw "All YAML parsing methods failed. Consider installing PowerShell-Yaml module: Install-Module -Name PowerShell-Yaml"
    }
}

# Main execution
Write-Info "Starting GitHub configuration validation..."

if (-not $SkipInstall) {
    Install-RequiredTools
}

$totalErrors = 0

$totalErrors += Test-YamlFiles
$totalErrors += Test-MarkdownFiles
$totalErrors += Test-JsonFiles
$totalErrors += Test-IssueTemplates
$totalErrors += Test-PullRequestTemplates
$totalErrors += Test-WorkflowFiles

Write-Info "Validation completed."

if ($totalErrors -eq 0) {
    Write-Success "All validation checks passed! ✨"
    exit 0
} else {
    Write-ErrorMessage "Validation failed with $totalErrors errors"
    exit 1
}
