# 🛡️ GitHub Branch Protection Policy Automation

[![PowerShell](https://img.shields.io/badge/PowerShell-7.0+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![GitHub Issues](https://img.shields.io/github/issues/Stratovate-Solutions/BranchProtectionPolicy)](https://github.com/Stratovate-Solutions/BranchProtectionPolicy/issues)
[![Last Commit](https://img.shields.io/github/last-commit/Stratovate-Solutions/BranchProtectionPolicy)](https://github.com/Stratovate-Solutions/BranchProtectionPolicy/commits/main)

> **Automated enforcement of standardized branch protection policies across GitHub repositories**

This repository contains PowerShell scripts and GitHub Actions workflows for applying consistent branch protection policies across multiple repositories in the Stratovate Solutions organization. It ensures security, quality, and compliance standards are maintained across all code repositories.

---

## 🎯 Features

### 🔒 Security Enforcement

- **Required Pull Request Reviews** - Enforce peer review process
- **Code Owner Approval** - Ensure domain expert review when needed
- **Administrator Enforcement** - Apply rules to all users including admins
- **Force Push Prevention** - Protect against history rewriting
- **Branch Deletion Protection** - Prevent accidental branch removal

### 🚀 Quality Assurance

- **Status Check Requirements** - Mandate CI/CD pipeline success
- **Stale Review Dismissal** - Ensure reviews reflect current code
- **Configurable Review Count** - Flexible approval requirements (1-6 reviewers)
- **Linear History Option** - Maintain clean commit history

### 🔧 Automation & Management

- **Batch Processing** - Apply policies to multiple repositories
- **Secure Token Handling** - Best practices for credential management
- **Comprehensive Logging** - Detailed audit trails and troubleshooting
- **Error Recovery** - Robust error handling and retry mechanisms

---

## 📁 Repository Structure

BranchProtectionPolicy/
├── 📄 BranchProtectionPolicy.ps1          # Main PowerShell script
├── 📄 README.md                           # This documentation
├── 📄 LICENSE                             # MIT License
├── 📄 CHANGELOG.md                        # Version history
├── 📁 .github-org/                        # GitHub organization templates
│   ├── 📄 README.md                       # Organization docs
│   ├── 📄 CONTRIBUTING.md                 # Contribution guidelines
│   ├── 📄 SECURITY.md                     # Security policy
│   ├── 📁 .github/workflows/              # Reusable workflows
│   │   ├── 📄 apply-branch-protection.yml # Branch protection workflow
│   │   ├── 📄 reusable-ci.yml             # CI/CD workflow
│   │   └── 📄 reusable-release.yml        # Release automation
│   ├── 📁 ISSUE_TEMPLATE/                 # Issue templates
│   ├── 📁 workflow-templates/             # Template files
│   └── 📁 profile/                        # Organization profile
├── 📁 docs/                               # Additional documentation
├── 📁 examples/                           # Usage examples
├── 📁 tests/                              # Pester test scripts
└── 📁 logs/                               # Generated log files
```
BranchProtectionPolicy/
├── 📄 BranchProtectionPolicy.ps1          # Main PowerShell script
├── 📄 README.md                           # This documentation
├── 📄 LICENSE                             # MIT License
├── 📄 CHANGELOG.md                        # Version history
├── 📁 .github-org/                        # GitHub organization templates
│   ├── 📄 README.md                       # Organization docs
│   ├── 📄 CONTRIBUTING.md                 # Contribution guidelines
│   ├── 📄 SECURITY.md                     # Security policy
│   ├── 📁 .github/workflows/              # Reusable workflows
│   │   ├── 📄 apply-branch-protection.yml # Branch protection workflow
│   │   ├── 📄 reusable-ci.yml             # CI/CD workflow
│   │   └── 📄 reusable-release.yml        # Release automation
│   ├── 📁 ISSUE_TEMPLATE/                 # Issue templates
│   ├── 📁 workflow-templates/             # Template files
│   └── 📁 profile/                        # Organization profile
├── 📁 docs/                               # Additional documentation
├── 📁 examples/                           # Usage examples
├── 📁 tests/                              # Pester test scripts
└── 📁 logs/                               # Generated log files
```

---

## 🚀 Quick Start

### Prerequisites

- **PowerShell 7.0+** - [Download PowerShell](https://github.com/PowerShell/PowerShell/releases)
- **GitHub Personal Access Token** - [Create PAT](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
  - Required scopes: `repo`, `admin:repo_hook`
  - Admin permissions on target repositories

### Basic Usage

1. **Clone the repository**:

   ```powershell
   git clone https://github.com/Stratovate-Solutions/BranchProtectionPolicy.git
   cd BranchProtectionPolicy
   ```

2. **Run with default settings**:

   ```powershell
   .\BranchProtectionPolicy.ps1 -GithubPAT "your_github_token_here"
   ```

3. **Customize for specific repositories**:

   ```powershell
   .\BranchProtectionPolicy.ps1 -GithubPAT "your_token" -Branch "develop" -Repos @("owner/repo1", "owner/repo2")
   ```

### Secure Token Storage (Recommended)

```powershell
# One-time setup - store token securely
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
```

---

## 📖 Detailed Usage

### Command-Line Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `GithubPAT` | String | *Required* | GitHub Personal Access Token with repo admin scope |
| `Repos` | String[] | *Predefined list* | Array of repositories in 'owner/repo' format |
| `Branch` | String | `"main"` | Target branch name to protect |

### Advanced Examples

#### Protect Development Branch

```powershell
.\BranchProtectionPolicy.ps1 -GithubPAT $token -Branch "develop" -Repos @(
    "Stratovate-Solutions/TeamsSurveyConfig",
    "Stratovate-Solutions/TeamsVoiceDiscovery"
)
```

#### Test Mode (WhatIf)

```powershell
.\BranchProtectionPolicy.ps1 -GithubPAT $token -WhatIf
```

#### Verbose Logging

```powershell
.\BranchProtectionPolicy.ps1 -GithubPAT $token -Verbose
```

### Protection Policy Details

The script applies the following protection rules:

```json
{
  "required_status_checks": {
    "strict": true,
    "contexts": []
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
```

---

## 🔧 GitHub Actions Integration

### Using the Reusable Workflow

Create `.github/workflows/branch-protection.yml` in your repository:

```yaml
name: Apply Branch Protection

on:
  workflow_dispatch:
    inputs:
      branch:
        description: 'Branch to protect'
        default: 'main'
        type: string

jobs:
  protect:
    uses: Stratovate-Solutions/.github/.github/workflows/apply-branch-protection.yml@main
    with:
      repository: ${{ github.repository }}
      branch: ${{ inputs.branch || 'main' }}
      require-reviews: true
      required-reviewers: 1
      require-code-owner-reviews: true
      enforce-admins: true
      required-status-checks: "ci/build,ci/test"
    secrets:
      ADMIN_TOKEN: ${{ secrets.ADMIN_TOKEN }}
```

### Organization-Wide Deployment

For applying protection across all repositories:

```yaml
name: Organization Branch Protection

on:
  schedule:
    - cron: '0 2 * * 1'  # Weekly on Monday at 2 AM
  workflow_dispatch:

jobs:
  apply-to-all:
    strategy:
      matrix:
        repo: 
          - "Stratovate-Solutions/TeamsSurveyConfig"
          - "Stratovate-Solutions/TeamsVoiceDiscovery"
          # Add more repositories...
    
    uses: Stratovate-Solutions/.github/.github/workflows/apply-branch-protection.yml@main
    with:
      repository: ${{ matrix.repo }}
      branch: "main"
      require-reviews: true
      required-reviewers: 1
      enforce-admins: true
    secrets:
      ADMIN_TOKEN: ${{ secrets.ORGANIZATION_ADMIN_TOKEN }}
```

---

## 📊 Monitoring & Reporting

### Log Files

The script generates detailed logs in the `Logs/` directory:

- **Console Output**: Real-time status updates
- **Log Files**: `BranchProtection_YYYYMMDD_HHMMSS.log`
- **CSV Reports**: `BranchProtection_Results_YYYYMMDD_HHMMSS.csv`

### Example Log Output

```
[2025-08-19 14:30:15] [Info] Branch Protection Policy script started
[2025-08-19 14:30:15] [Info] Target repositories: 10
[2025-08-19 14:30:15] [Info] Target branch: main
[2025-08-19 14:30:16] [Success] ✅ Successfully applied protection to Stratovate-Solutions/TeamsSurveyConfig/main
[2025-08-19 14:30:17] [Success] ✅ Successfully applied protection to Stratovate-Solutions/TeamsVoiceDiscovery/main
[2025-08-19 14:30:20] [Info] === BRANCH PROTECTION SUMMARY ===
[2025-08-19 14:30:20] [Success] Successful applications: 10
[2025-08-19 14:30:20] [Info] Failed applications: 0
```

### Status Monitoring

Monitor the health of your branch protection policies:

```powershell
# Check current protection status
Get-Content "Logs\BranchProtection_Results_*.csv" | ConvertFrom-Csv | 
    Where-Object Status -eq "Success" | 
    Measure-Object | Select-Object Count
```

---

## 🛠️ Customization

### Modifying Protection Policies

To customize the protection settings, modify the `Set-BranchProtection` function:

```powershell
# Example: Require 2 reviewers and code owner approval
$result = Set-BranchProtection -Repo $repo -Branch $Branch -Token $GithubPAT `
    -RequiredReviewers 2 -RequireCodeOwnerReviews $true
```

### Adding Status Check Requirements

```powershell
# Require CI checks to pass
$result = Set-BranchProtection -Repo $repo -Branch $Branch -Token $GithubPAT `
    -RequiredStatusChecks @("continuous-integration", "security-scan")
```

### Organization-Specific Templates

Create custom protection templates in the `.github-org/` directory for different repository types:

- **Critical Systems**: High security, multiple reviewers
- **Development Projects**: Balanced security and velocity
- **Documentation Repos**: Lightweight protection

---

## 🔒 Security Considerations

### Token Security

1. **Never commit tokens** to version control
2. **Use minimal required scopes** (repo, admin:repo_hook)
3. **Set expiration dates** for tokens
4. **Rotate tokens regularly** (recommended: 90 days)
5. **Monitor token usage** through GitHub audit logs

### Access Control

1. **Limit admin tokens** to necessary personnel
2. **Use organization secrets** for shared tokens
3. **Implement approval workflows** for protection changes
4. **Regular access audits** and permission reviews

### Compliance

1. **Document protection policies** in your security manual
2. **Regular compliance checks** using automated scripts
3. **Audit trails** for all protection changes
4. **Exception handling** for emergency access needs

---

## 🧪 Testing

### Running Tests

```powershell
# Install Pester testing framework
Install-Module -Name Pester -Force -SkipPublisherCheck

# Run all tests
Invoke-Pester -Path "tests/" -OutputFormat NUnitXml -OutputFile "TestResults.xml"

# Run specific test
Invoke-Pester -Path "tests/BranchProtection.Tests.ps1" -Verbose
```

### Test Coverage

The test suite covers:

- ✅ Parameter validation
- ✅ Token format verification
- ✅ API error handling
- ✅ Configuration validation
- ✅ Logging functionality
- ✅ Security token handling

### Mock Testing

Test without affecting real repositories:

```powershell
# Use test repositories or mock API responses
.\BranchProtectionPolicy.ps1 -GithubPAT $testToken -Repos @("test-org/test-repo") -WhatIf
```

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](.github-org/CONTRIBUTING.md) for details.

### Development Setup

1. **Fork the repository**
2. **Create feature branch**: `git checkout -b feature/your-feature`
3. **Run tests**: `Invoke-Pester`
4. **Submit pull request**

### Coding Standards

- Follow PowerShell best practices
- Include comprehensive documentation
- Add tests for new functionality
- Use semantic commit messages

---

## 📈 Roadmap

### Upcoming Features

- [ ] **GitHub App Integration** - Replace PAT with GitHub App authentication
- [ ] **Policy Templates** - Predefined protection templates for different scenarios
- [ ] **Compliance Reporting** - Automated compliance status reports
- [ ] **Slack Integration** - Notifications for protection changes
- [ ] **Azure DevOps Support** - Extend to Azure Repos branch policies
- [ ] **Terraform Provider** - Infrastructure as Code approach

### Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

---

## 🆘 Support

### Getting Help

- **Documentation**: Check this README and inline code comments
- **Issues**: [GitHub Issues](https://github.com/Stratovate-Solutions/BranchProtectionPolicy/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Stratovate-Solutions/BranchProtectionPolicy/discussions)
- **Email**: DevOps team at <devops@stratovate.com>

### Troubleshooting

Common issues and solutions:

| Issue | Solution |
|-------|----------|
| 401 Unauthorized | Check token validity and scopes |
| 403 Forbidden | Verify admin permissions on repository |
| 404 Not Found | Confirm repository and branch names |
| 422 Validation Error | Review protection configuration |

### Emergency Contacts

For urgent issues affecting production repositories:

- **On-call DevOps**: +1-555-DEVOPS
- **Security Team**: <security@stratovate.com>
- **Escalation**: CTO office

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏢 About Stratovate Solutions

**Stratovate Solutions** is a leading Microsoft Teams and communications technology consulting firm. We specialize in:

- Microsoft Teams Voice and Calling Solutions
- Contact Center Integration
- Unified Communications Architecture
- DevOps and Automation Solutions

**Contact Information:**

- **Website**: [stratovate.com](https://stratovate.com)
- **Email**: <info@stratovate.com>
- **LinkedIn**: [Stratovate Solutions](https://linkedin.com/company/stratovate-solutions)

---

## 🎉 Acknowledgments

- **GitHub Team** - For excellent API documentation and support
- **PowerShell Community** - For best practices and modules
- **Security Researchers** - For branch protection recommendations
- **Open Source Contributors** - For inspiration and code examples

---

*Last Updated: August 19, 2025*
*Document Version: 2.0*
*Maintained by: Stratovate Solutions DevOps Team*
