#!/usr/bin/env pwsh

$template = Get-Item "ISSUE_TEMPLATE/bug_report.yml"
Write-Host "Testing $($template.Name)..."

$content = Get-Content $template.FullName -Raw | ConvertFrom-Yaml

Write-Host "Parsed content type: $($content.GetType().Name)"
Write-Host "Content keys: $($content.Keys -join ', ')"

$requiredFields = @("name", "description", "body")
$templateErrors = 0

foreach ($field in $requiredFields) {
    $fieldValue = $content.$field
    $exists = $fieldValue -ne $null -and $fieldValue -ne ""
    Write-Host "$field : exists = $exists, value = '$fieldValue'"
    
    if (-not $content.$field) {
        Write-Host "ERROR: $($template.Name) missing required field: $field"
        $templateErrors++
    }
}

Write-Host "Template errors: $templateErrors"

if ($templateErrors -eq 0) {
    Write-Host "✓ $($template.Name) is VALID"
} else {
    Write-Host "✗ $($template.Name) has $templateErrors errors"
}
