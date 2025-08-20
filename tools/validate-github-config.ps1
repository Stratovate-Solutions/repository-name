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

function Test-CommandExists {
    param([string]$Command)
    return $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

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

function Install-RequiredTools {
    Write-Info "Installing required tools..."
    
    # Check if Python is installed
    if (-not (Test-CommandExists "python")) {
        Write-Error "Python is not installed. Please install Python first."
        exit 1
    }
    
    # Install PowerShell-Yaml module if not available
    if (-not (Get-Module -ListAvailable -Name PowerShell-Yaml)) {
        Write-Info "Installing PowerShell-Yaml module..."
        try {
            Install-Module -Name PowerShell-Yaml -Force -Scope CurrentUser -AllowClobber
            Write-Success "PowerShell-Yaml module installed"
        } catch {
            Write-Warning "Failed to install PowerShell-Yaml module: $_"
            Write-Info "Will use Python fallback for YAML parsing"
        }
    }
    
    # Install yamllint
    Write-Info "Installing yamllint..."
    try {
        python -m pip install yamllint --user
        Write-Success "yamllint installed"
    } catch {
        Write-Error "Failed to install yamllint: $_"
    }
    
    # Check if Node.js is installed
    if (-not (Test-CommandExists "node")) {
        Write-Warning "Node.js is not installed. Some schema validation will be skipped."
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

function Test-YamlFiles {
    Write-Info "Linting YAML files..."
    
    $yamlFiles = Get-ChildItem -Path ".github" -Filter "*.yml" -Recurse
    $yamlFiles += Get-ChildItem -Path ".github" -Filter "*.yaml" -Recurse
    $yamlFiles += Get-ChildItem -Path "." -Filter "*.yml" | Where-Object { $_.FullName -notmatch "\.github\\workflows" }
    $yamlFiles += Get-ChildItem -Path "." -Filter "*.yaml" | Where-Object { $_.FullName -notmatch "\.github\\workflows" }
    
    if ($yamlFiles.Count -eq 0) {
        Write-Warning "No YAML files found"
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
                Write-Error "YAML linting failed for $($file.Name):"
                Write-Host $result
                $errors++
            }
        } catch {
            Write-Error "Failed to lint $($file.Name): $_"
            $errors++
        }
    }
    
    if ($errors -eq 0) {
        Write-Success "All YAML files passed linting"
    } else {
        Write-Error "$errors YAML files failed linting"
    }
    
    return $errors
}

function Test-MarkdownFiles {
    Write-Info "Linting Markdown files..."
    
    $markdownFiles = Get-ChildItem -Path "." -Filter "*.md" -Recurse | Where-Object { 
        $_.FullName -notmatch "node_modules" -and $_.FullName -notmatch "\.git"
    }
    
    if ($markdownFiles.Count -eq 0) {
        Write-Warning "No Markdown files found"
        return 0
    }
    
    Write-Info "Found $($markdownFiles.Count) Markdown files"
    
    $configFile = if (Test-Path ".markdownlint.json") { ".markdownlint.json" } else { $null }
    $errors = 0
    
    if (Test-CommandExists "markdownlint-cli2") {
        try {
            $configParam = if ($configFile) { "--config $configFile" } else { "" }
            $markdownPaths = $markdownFiles | ForEach-Object { 
                $relativePath = (Resolve-Path $_.FullName -Relative) -replace '^\.\\', ''
                $relativePath -replace '\\', '/'
            }
            
            # Create a temp file with the list of files to process
            $tempFileList = [System.IO.Path]::GetTempFileName()
            $markdownPaths | Out-File -FilePath $tempFileList -Encoding UTF8
            
            $cmd = "markdownlint-cli2 $configParam --stdin < `"$tempFileList`""
            if ($Verbose) {
                Write-Info "Running: $cmd"
            }
            
            $result = Invoke-Expression $cmd 2>&1
            Remove-Item $tempFileList -Force -ErrorAction SilentlyContinue
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "All Markdown files passed linting"
            } else {
                Write-Error "Markdown linting failed:"
                Write-Host $result
                $errors++
            }
        } catch {
            Write-Error "Failed to lint Markdown files: $_"
            $errors++
        }
    } else {
        Write-Warning "markdownlint-cli2 not available, skipping Markdown linting"
    }
    
    return $errors
}

function Test-JsonFiles {
    Write-Info "Validating JSON files..."
    
    $jsonFiles = Get-ChildItem -Path "." -Filter "*.json" -Recurse | Where-Object { 
        $_.FullName -notmatch "node_modules" -and $_.FullName -notmatch "\.git"
    }
    
    if ($jsonFiles.Count -eq 0) {
        Write-Warning "No JSON files found"
        return 0
    }
    
    $errors = 0
    
    foreach ($file in $jsonFiles) {
        if ($Verbose) {
            Write-Info "Validating $($file.Name)..."
        }
        
        try {
            $content = Get-Content $file.FullName -Raw | ConvertFrom-Json
            if ($Verbose) {
                Write-Success "$($file.Name) is valid JSON"
            }
        } catch {
            Write-Error "Invalid JSON in $($file.Name): $_"
            $errors++
        }
    }
    
    if ($errors -eq 0) {
        Write-Success "All JSON files are valid"
    } else {
        Write-Error "$errors JSON files are invalid"
    }
    
    return $errors
}

function Test-IssueTemplates {
    Write-Info "Testing issue templates..."
    
    $templateDir = "ISSUE_TEMPLATE"
    if (-not (Test-Path $templateDir)) {
        Write-Warning "Issue template directory not found"
        return 0
    }
    
    $templates = Get-ChildItem -Path $templateDir -Filter "*.yml"
    $templates += Get-ChildItem -Path $templateDir -Filter "*.yaml"
    $templates += Get-ChildItem -Path $templateDir -Filter "*.md"
    
    if ($templates.Count -eq 0) {
        Write-Warning "No issue templates found"
        return 0
    }
    
    Write-Info "Found $($templates.Count) issue templates"
    
    $errors = 0
    
    foreach ($template in $templates) {
        if ($Verbose) {
            Write-Info "Testing $($template.Name)..."
        }
        
        if ($template.Extension -in @(".yml", ".yaml")) {
            # Test YAML issue templates
            try {
                $content = Get-Content $template.FullName -Raw | ConvertFrom-Yaml
                
                $requiredFields = @("name", "description", "body")
                foreach ($field in $requiredFields) {
                    if (-not $content.$field) {
                        Write-Error "$($template.Name) missing required field: $field"
                        $errors++
                    }
                }
                
                if ($errors -eq 0 -and $Verbose) {
                    Write-Success "$($template.Name) is valid"
                }
            } catch {
                Write-Error "Failed to parse YAML template $($template.Name): $_"
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
                Write-Warning "$($template.Name) may not have YAML frontmatter"
            }
        }
    }
    
    if ($errors -eq 0) {
        Write-Success "All issue templates are valid"
    } else {
        Write-Error "$errors issue template issues found"
    }
    
    return $errors
}

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
        Write-Warning "No PR templates found"
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
                Write-Error "PR template $template is empty"
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
        Write-Error "$errors PR template issues found"
    }
    
    return $errors
}

function Test-WorkflowFiles {
    Write-Info "Testing workflow files..."
    
    $workflowDir = ".github/workflows"
    if (-not (Test-Path $workflowDir)) {
        Write-Warning "Workflows directory not found"
        return 0
    }
    
    $workflows = Get-ChildItem -Path $workflowDir -Filter "*.yml"
    $workflows += Get-ChildItem -Path $workflowDir -Filter "*.yaml"
    
    if ($workflows.Count -eq 0) {
        Write-Warning "No workflow files found"
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
                    Write-Error "$($workflow.Name) missing required field: $field"
                    $errors++
                }
            }
            
            if (-not $content.name) {
                Write-Warning "$($workflow.Name) missing 'name' field"
            }
            
            if ($errors -eq 0 -and $Verbose) {
                Write-Success "$($workflow.Name) has valid structure"
            }
        } catch {
            Write-Error "Failed to parse workflow $($workflow.Name): $_"
            $errors++
        }
    }
    
    if ($errors -eq 0) {
        Write-Success "All workflow files are valid"
    } else {
        Write-Error "$errors workflow issues found"
    }
    
    return $errors
}

# Helper function to convert YAML (requires PowerShell-Yaml module)
function ConvertFrom-Yaml {
    param([string]$InputObject)
    
    # First try PowerShell-Yaml module
    if (Get-Module -ListAvailable -Name PowerShell-Yaml) {
        try {
            Import-Module PowerShell-Yaml -Force
            return ConvertFrom-Yaml $InputObject
        } catch {
            # Continue to fallback methods
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
    Write-Error "Validation failed with $totalErrors errors"
    exit 1
}
