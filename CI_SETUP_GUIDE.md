# 🚀 Continuous Integration Setup Guide

## Overview

Your PowerShell project now has a comprehensive CI/CD pipeline configured with the following workflows:

### 🔄 Available Workflows

1. **Continuous Integration** (`continuous-integration.yml`)
   - Runs PSScriptAnalyzer for code quality
   - Executes Pester tests
   - Generates detailed build reports
   - Uploads artifacts for review

2. **Repository Validation** (`validate.yml`)
   - Validates YAML syntax in workflows
   - Checks repository structure
   - Ensures GitHub configuration compliance

3. **Reusable Workflows** (Optional)
   - `reusable-ci.yml` - Multi-language CI pipeline
   - `reusable-security-scan.yml` - Security scanning

## 🎯 Quick Start

### 1. Enable GitHub Actions

1. Go to your repository on GitHub
2. Click the **Actions** tab
3. Enable workflows if not already enabled
4. Your workflows will run automatically on push/PR

### 2. Test Your Pipeline

Create a simple test to verify everything works:

```powershell
# Create a test file: Tests/Example.Tests.ps1
Describe "Example Tests" {
    It "Should pass a basic test" {
        $true | Should -Be $true
    }
    
    It "Should demonstrate PowerShell testing" {
        $result = "Hello, World!"
        $result | Should -Be "Hello, World!"
    }
}
```

### 3. Commit and Push

```bash
git add .
git commit -m "Add CI/CD pipeline and example tests"
git push origin main
```

## 🔧 Configuration Options

### Workflow Triggers

The CI pipeline runs on:

- Push to `main` or `develop` branches
- Pull requests to `main`
- Manual dispatch (Run workflow button)

### Manual Execution

You can run workflows manually with options:

- **Debug mode**: Enable verbose logging
- **Skip tests**: Skip test execution for faster runs

### Skip CI for Specific Changes

Add to your commit message to skip CI:

```
git commit -m "Update documentation [skip ci]"
```

## 📁 Expected Project Structure

```
your-repo/
├── .github/
│   └── workflows/
│       ├── continuous-integration.yml
│       ├── validate.yml
│       ├── reusable-ci.yml (optional)
│       └── reusable-security-scan.yml (optional)
├── Tests/                    # Pester test files
│   └── *.Tests.ps1
├── *.ps1                     # PowerShell scripts
├── *.psm1                    # PowerShell modules
├── *.psd1                    # PowerShell manifests
├── README.md
├── LICENSE
└── PSScriptAnalyzerSettings.psd1 (optional)
```

## 🧪 Adding Tests

### Create Test Directory

```bash
mkdir Tests
```

### Example Test File

```powershell
# Tests/MyScript.Tests.ps1
BeforeAll {
    # Import the script/module being tested
    . $PSScriptRoot/../MyScript.ps1
}

Describe "MyScript Tests" {
    Context "When testing basic functionality" {
        It "Should return expected result" {
            $result = Get-MyFunction
            $result | Should -Not -BeNullOrEmpty
        }
    }
}
```

## 📊 Monitoring Your Pipeline

### 1. GitHub Actions Tab

- View workflow runs
- Check logs and results
- Download artifacts

### 2. Build Artifacts

Each run generates:

- PSScriptAnalyzer results (CSV/JSON)
- Test results (XML)
- Code coverage reports
- Build summary report

### 3. Status Checks

- Green checkmark = All checks passed
- Red X = Issues found
- Yellow dot = In progress

## 🔧 Customization

### PSScriptAnalyzer Settings

Create `PSScriptAnalyzerSettings.psd1`:

```powershell
@{
    Severity = @('Error', 'Warning')
    ExcludeRules = @(
        'PSUseShouldProcessForStateChangingFunctions'
    )
    IncludeDefaultRules = $true
}
```

### Pester Configuration

Customize test execution in your test files:

```powershell
$PesterConfiguration = New-PesterConfiguration
$PesterConfiguration.Run.PassThru = $true
$PesterConfiguration.CodeCoverage.Enabled = $true
```

## 🚨 Troubleshooting

### Common Issues

1. **Tests not found**
   - Ensure test files end with `.Tests.ps1`
   - Place tests in `Tests/` directory or root

2. **PSScriptAnalyzer errors**
   - Review the generated CSV report
   - Fix critical errors (severity: Error)
   - Warnings are informational

3. **Workflow fails**
   - Check the Actions tab for detailed logs
   - Review the build artifacts
   - Ensure all required files exist

### Getting Help

1. Check the GitHub Actions logs
2. Review the build report artifact
3. Consult PowerShell community resources
4. Contact your DevOps team

## 📈 Next Steps

1. **Add more tests** - Improve code coverage
2. **Configure branch protection** - Require CI checks
3. **Set up notifications** - Get alerts on failures
4. **Add security scanning** - Use the security workflow
5. **Create releases** - Automate versioning and deployment

## 🎉 You're Ready

Your PowerShell CI/CD pipeline is now configured and ready to use. Every push and pull request will automatically:

- ✅ Validate code quality with PSScriptAnalyzer
- ✅ Run your Pester tests
- ✅ Generate comprehensive reports
- ✅ Provide fast feedback on issues

Happy coding! 🚀
