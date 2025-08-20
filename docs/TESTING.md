# GitHub Organization Configuration Testing

This repository includes comprehensive linting and validation for GitHub organization-wide configuration files.

## Automated Testing

### Workflows

- **`lint-validation.yml`** - Runs linting and schema validation on all configuration files
- **`integration-tests.yml`** - Tests functionality and structure of GitHub templates and workflows

### What Gets Tested

#### Linting & Formatting
- ✅ **YAML files** - Syntax, formatting, and structure validation using `yamllint`
- ✅ **Markdown files** - Style and formatting validation using `markdownlint-cli2`
- ✅ **JSON files** - Syntax validation
- ✅ **Schema validation** - GitHub workflow and issue template schema compliance

#### Integration Testing
- ✅ **Issue templates** - Validates required fields and structure
- ✅ **PR templates** - Checks for existence and common sections
- ✅ **Workflow syntax** - Validates GitHub Actions workflow structure
- ✅ **Repository simulation** - Tests configuration in a mock repository setup
- ✅ **Dependabot config** - Validates Dependabot configuration if present

## Local Validation

### Quick Validation
Run the PowerShell validation script:

```powershell
.\validate-github-config.ps1
```

### Manual Tool Setup
If you prefer to install and run tools manually:

```powershell
# Install Python tools
pip install yamllint

# Install Node.js tools (if Node.js is available)
npm install -g markdownlint-cli2 js-yaml ajv-cli

# Run individual validations
yamllint -c .yamllint.yml .github/workflows/*.yml
markdownlint-cli2 --config .markdownlint.json "**/*.md"
```

## Configuration Files

- **`.yamllint.yml`** - YAML linting configuration
- **`.markdownlint.json`** - Markdown linting rules
- **`validate-github-config.ps1`** - Local validation script

## CI/CD Integration

The workflows automatically run on:
- Push to `main`/`master` branches
- Pull requests to `main`/`master` branches

### Workflow Status
- ✅ All checks pass = Configuration is valid
- ❌ Checks fail = Review errors and fix issues

## Common Issues & Solutions

### YAML Linting Errors
- Check indentation (2 spaces)
- Verify line length (max 120 characters)
- Ensure proper YAML syntax

### Markdown Linting Errors
- Check line length (max 120 characters)
- Verify heading structure
- Ensure consistent list formatting

### Schema Validation Errors
- Verify required fields in issue templates (`name`, `description`, `body`)
- Check workflow structure (`on`, `jobs`)
- Validate GitHub Actions syntax

## Best Practices

1. **Run local validation** before committing changes
2. **Use consistent formatting** across all files
3. **Include required fields** in templates
4. **Test workflows** in a separate repository first
5. **Keep documentation** up to date

## Troubleshooting

### PowerShell Execution Policy
If you can't run the validation script:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Missing Dependencies
The validation script will attempt to install required tools automatically. If installation fails:
- Ensure Python is installed and in PATH
- Ensure Node.js is installed (optional, for enhanced validation)
- Run with admin privileges if needed

### YAML Parsing Issues
If you encounter YAML parsing errors, consider installing the PowerShell-Yaml module:
```powershell
Install-Module -Name PowerShell-Yaml -Force
```
