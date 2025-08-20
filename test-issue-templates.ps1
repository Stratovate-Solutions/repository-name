#!/usr/bin/env pwsh

# Import the function
. "tools/validate-github-config.ps1"

# Run just the issue template test
$errors = Test-IssueTemplates
Write-Host "Function returned: $errors errors"
