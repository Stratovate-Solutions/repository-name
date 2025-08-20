# 📋 Examples and Usage Patterns

This document provides comprehensive examples for using the Branch Protection Policy automation tools in various scenarios.

## 🚀 PowerShell Script Examples

### Basic Usage

#### Apply Default Protection to All Repositories
```powershell
# Apply default protection to predefined repository list
.\BranchProtectionPolicy.ps1 -GithubPAT "ghp_your_token_here"
```

#### Protect Specific Repositories
```powershell
# Target specific repositories
.\BranchProtectionPolicy.ps1 -GithubPAT "ghp_your_token_here" -Repos @(
    "Stratovate-Solutions/TeamsSurveyConfig",
    "Stratovate-Solutions/TeamsVoiceDiscovery"
)
```

#### Protect Different Branch
```powershell
# Protect development branch instead of main
.\BranchProtectionPolicy.ps1 -GithubPAT "ghp_your_token_here" -Branch "develop"
```

### Advanced Usage

#### Test Mode (WhatIf)
```powershell
# Test configuration without applying changes
.\BranchProtectionPolicy.ps1 -GithubPAT "ghp_your_token_here" -WhatIf
```

#### Verbose Logging
```powershell
# Enable detailed logging output
.\BranchProtectionPolicy.ps1 -GithubPAT "ghp_your_token_here" -Verbose
```

#### Custom Configuration with Status Checks
```powershell
# Use the function directly for custom settings
$repos = @("owner/repo1", "owner/repo2")
foreach ($repo in $repos) {
    Set-BranchProtection -Repo $repo -Branch "main" -Token $GithubPAT `
        -RequiredStatusChecks @("ci/build", "ci/test", "security/scan") `
        -RequiredReviewers 2 `
        -RequireCodeOwnerReviews $true
}
```

### Secure Token Handling

#### One-Time Secure Setup
```powershell
# Setup secure token storage (run once)
$securePath = "$env:USERPROFILE\.github"
if (-not (Test-Path $securePath)) { 
    New-Item -ItemType Directory -Path $securePath -Force 
}

Write-Host "Enter your GitHub Personal Access Token:" -ForegroundColor Yellow
$secureToken = Read-Host -AsSecureString
$secureToken | ConvertFrom-SecureString | Out-File "$securePath\github-pat.txt"

Write-Host "Token stored securely at: $securePath\github-pat.txt" -ForegroundColor Green
```

#### Retrieve and Use Secure Token
```powershell
# Retrieve token from secure storage
$securePath = "$env:USERPROFILE\.github\github-pat.txt"
if (Test-Path $securePath) {
    $secureString = Get-Content $securePath | ConvertTo-SecureString
    $plainToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    )
    
    # Use the securely stored token
    .\BranchProtectionPolicy.ps1 -GithubPAT $plainToken
} else {
    Write-Error "Secure token not found. Run setup script first."
}
```

### Batch Processing Examples

#### Organization-Wide Protection
```powershell
# Define repository categories
$criticalRepos = @(
    "Stratovate-Solutions/Teams-Health-Toolkit",
    "Stratovate-Solutions/TeamsPhoneProvisioning"
)

$standardRepos = @(
    "Stratovate-Solutions/TeamsSurveyConfig",
    "Stratovate-Solutions/TeamsVoiceDiscovery"
)

# Apply strict protection to critical repositories
foreach ($repo in $criticalRepos) {
    Set-BranchProtection -Repo $repo -Branch "main" -Token $GithubPAT `
        -RequiredReviewers 2 `
        -RequireCodeOwnerReviews $true `
        -RequiredStatusChecks @("ci/build", "ci/test", "security/scan", "compliance/check")
}

# Apply standard protection to other repositories
foreach ($repo in $standardRepos) {
    Set-BranchProtection -Repo $repo -Branch "main" -Token $GithubPAT `
        -RequiredReviewers 1 `
        -RequiredStatusChecks @("ci/build", "ci/test")
}
```

#### Multi-Branch Protection
```powershell
# Protect multiple branches in repositories
$repos = @("owner/repo1", "owner/repo2")
$branches = @("main", "develop", "release")

foreach ($repo in $repos) {
    foreach ($branch in $branches) {
        try {
            $result = Set-BranchProtection -Repo $repo -Branch $branch -Token $GithubPAT
            Write-Host "✅ Protected $repo/$branch" -ForegroundColor Green
        }
        catch {
            Write-Warning "⚠️ Failed to protect $repo/$branch : $($_.Exception.Message)"
        }
    }
}
```

## 🔄 GitHub Actions Examples

### Repository-Level Workflow

Create `.github/workflows/branch-protection.yml`:

```yaml
name: Apply Branch Protection

on:
  workflow_dispatch:
    inputs:
      branch:
        description: 'Branch to protect'
        required: false
        default: 'main'
        type: string
      reviewers:
        description: 'Number of required reviewers'
        required: false
        default: '1'
        type: string

jobs:
  apply-protection:
    runs-on: ubuntu-latest
    
    steps:
      - name: Apply Branch Protection
        uses: Stratovate-Solutions/.github/.github/workflows/apply-branch-protection.yml@main
        with:
          repository: ${{ github.repository }}
          branch: ${{ github.event.inputs.branch || 'main' }}
          require-reviews: true
          required-reviewers: ${{ fromJson(github.event.inputs.reviewers || '1') }}
          require-code-owner-reviews: true
          enforce-admins: true
          required-status-checks: "ci/build,ci/test"
        secrets:
          ADMIN_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Organization-Wide Workflow

Create `.github/workflows/org-protection.yml`:

```yaml
name: Organization Branch Protection

on:
  schedule:
    - cron: '0 2 * * 1'  # Weekly on Monday at 2 AM
  workflow_dispatch:
    inputs:
      dry-run:
        description: 'Dry run mode (test only)'
        required: false
        default: false
        type: boolean

jobs:
  # Define repository matrix
  define-repos:
    runs-on: ubuntu-latest
    outputs:
      matrix: ${{ steps.set-matrix.outputs.matrix }}
    
    steps:
      - name: Define Repository Matrix
        id: set-matrix
        run: |
          # Define repositories and their protection requirements
          cat << 'EOF' > repos.json
          {
            "include": [
              {
                "repo": "Stratovate-Solutions/TeamsSurveyConfig",
                "branch": "main",
                "reviewers": 1,
                "status-checks": "ci/build,ci/test"
              },
              {
                "repo": "Stratovate-Solutions/TeamsVoiceDiscovery", 
                "branch": "main",
                "reviewers": 1,
                "status-checks": "ci/build,ci/test,security/scan"
              },
              {
                "repo": "Stratovate-Solutions/Teams-Health-Toolkit",
                "branch": "main", 
                "reviewers": 2,
                "status-checks": "ci/build,ci/test,security/scan,compliance/check"
              }
            ]
          }
          EOF
          
          echo "matrix=$(cat repos.json)" >> $GITHUB_OUTPUT

  # Apply protection to each repository
  apply-protection:
    needs: define-repos
    runs-on: ubuntu-latest
    
    strategy:
      matrix: ${{ fromJson(needs.define-repos.outputs.matrix) }}
      fail-fast: false  # Continue with other repos if one fails
      
    steps:
      - name: Apply Protection to ${{ matrix.repo }}
        if: ${{ !github.event.inputs.dry-run }}
        uses: Stratovate-Solutions/.github/.github/workflows/apply-branch-protection.yml@main
        with:
          repository: ${{ matrix.repo }}
          branch: ${{ matrix.branch }}
          require-reviews: true
          required-reviewers: ${{ matrix.reviewers }}
          require-code-owner-reviews: true
          enforce-admins: true
          required-status-checks: ${{ matrix.status-checks }}
        secrets:
          ADMIN_TOKEN: ${{ secrets.ORG_ADMIN_TOKEN }}
          
      - name: Dry Run for ${{ matrix.repo }}
        if: ${{ github.event.inputs.dry-run }}
        run: |
          echo "Would apply protection to: ${{ matrix.repo }}/${{ matrix.branch }}"
          echo "Settings:"
          echo "  - Required reviewers: ${{ matrix.reviewers }}"
          echo "  - Status checks: ${{ matrix.status-checks }}"
          echo "  - Code owner reviews: true"
          echo "  - Enforce admins: true"
```

### Conditional Protection Based on Repository Type

```yaml
name: Smart Branch Protection

on:
  workflow_dispatch:
    inputs:
      repository:
        description: 'Repository to analyze and protect'
        required: true
        type: string

jobs:
  analyze-repo:
    runs-on: ubuntu-latest
    outputs:
      repo-type: ${{ steps.analyze.outputs.repo-type }}
      protection-level: ${{ steps.analyze.outputs.protection-level }}
    
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
        with:
          repository: ${{ github.event.inputs.repository }}
          
      - name: Analyze Repository Type
        id: analyze
        run: |
          # Determine repository type and appropriate protection level
          if [[ -f "package.json" ]]; then
            echo "repo-type=nodejs" >> $GITHUB_OUTPUT
            if grep -q "express\|koa\|fastify" package.json; then
              echo "protection-level=high" >> $GITHUB_OUTPUT
            else
              echo "protection-level=standard" >> $GITHUB_OUTPUT
            fi
          elif [[ -f "requirements.txt" || -f "pyproject.toml" ]]; then
            echo "repo-type=python" >> $GITHUB_OUTPUT
            if grep -q "django\|flask\|fastapi" requirements.txt pyproject.toml 2>/dev/null; then
              echo "protection-level=high" >> $GITHUB_OUTPUT
            else
              echo "protection-level=standard" >> $GITHUB_OUTPUT
            fi
          elif [[ -f "*.csproj" || -f "*.sln" ]]; then
            echo "repo-type=dotnet" >> $GITHUB_OUTPUT
            echo "protection-level=high" >> $GITHUB_OUTPUT
          elif [[ -f "*.ps1" || -f "*.psm1" ]]; then
            echo "repo-type=powershell" >> $GITHUB_OUTPUT
            echo "protection-level=standard" >> $GITHUB_OUTPUT
          else
            echo "repo-type=unknown" >> $GITHUB_OUTPUT
            echo "protection-level=standard" >> $GITHUB_OUTPUT
          fi

  apply-protection:
    needs: analyze-repo
    runs-on: ubuntu-latest
    
    steps:
      - name: Apply High Security Protection
        if: needs.analyze-repo.outputs.protection-level == 'high'
        uses: Stratovate-Solutions/.github/.github/workflows/apply-branch-protection.yml@main
        with:
          repository: ${{ github.event.inputs.repository }}
          branch: 'main'
          require-reviews: true
          required-reviewers: 2
          require-code-owner-reviews: true
          enforce-admins: true
          required-status-checks: "ci/build,ci/test,security/scan,compliance/check"
        secrets:
          ADMIN_TOKEN: ${{ secrets.ADMIN_TOKEN }}
          
      - name: Apply Standard Protection
        if: needs.analyze-repo.outputs.protection-level == 'standard'
        uses: Stratovate-Solutions/.github/.github/workflows/apply-branch-protection.yml@main
        with:
          repository: ${{ github.event.inputs.repository }}
          branch: 'main'
          require-reviews: true
          required-reviewers: 1
          require-code-owner-reviews: false
          enforce-admins: true
          required-status-checks: "ci/build,ci/test"
        secrets:
          ADMIN_TOKEN: ${{ secrets.ADMIN_TOKEN }}
```

## 🔧 Integration Examples

### Azure DevOps Integration

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
      - develop

pool:
  vmImage: 'windows-latest'

variables:
  - group: 'github-tokens'  # Variable group containing GITHUB_PAT

stages:
  - stage: ApplyBranchProtection
    displayName: 'Apply GitHub Branch Protection'
    
    jobs:
      - job: ProtectBranches
        displayName: 'Protect Repository Branches'
        
        steps:
          - task: PowerShell@2
            displayName: 'Apply Branch Protection Policies'
            inputs:
              targetType: 'inline'
              script: |
                # Download the script
                Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/Stratovate-Solutions/BranchProtectionPolicy/main/BranchProtectionPolicy.ps1' -OutFile 'BranchProtectionPolicy.ps1'
                
                # Apply protection
                .\BranchProtectionPolicy.ps1 -GithubPAT '$(GITHUB_PAT)' -Repos @('$(Build.Repository.Name)') -Verbose
              pwsh: true
```

### Terraform Integration

```hcl
# terraform/github-protection.tf
terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

# Configure the GitHub provider
provider "github" {
  token = var.github_token
  owner = "Stratovate-Solutions"
}

# Define repository list
variable "repositories" {
  description = "List of repositories to protect"
  type = list(object({
    name                = string
    branch              = string
    required_reviewers  = number
    require_code_owners = bool
    status_checks      = list(string)
  }))
  
  default = [
    {
      name                = "TeamsSurveyConfig"
      branch              = "main"
      required_reviewers  = 1
      require_code_owners = false
      status_checks      = ["ci/build", "ci/test"]
    },
    {
      name                = "Teams-Health-Toolkit"
      branch              = "main"
      required_reviewers  = 2
      require_code_owners = true
      status_checks      = ["ci/build", "ci/test", "security/scan"]
    }
  ]
}

# Apply branch protection to each repository
resource "github_branch_protection" "protection" {
  for_each = { for repo in var.repositories : repo.name => repo }
  
  repository_id = each.value.name
  pattern       = each.value.branch
  
  required_status_checks {
    strict   = true
    contexts = each.value.status_checks
  }
  
  required_pull_request_reviews {
    required_approving_review_count = each.value.required_reviewers
    dismiss_stale_reviews          = true
    require_code_owner_reviews     = each.value.require_code_owners
  }
  
  enforce_admins = true
  
  allows_deletions    = false
  allows_force_pushes = false
}
```

### Slack Integration

```powershell
# SlackNotification.ps1
function Send-SlackNotification {
    param(
        [string]$WebhookUrl,
        [string]$Message,
        [string]$Channel = "#devops",
        [string]$Username = "Branch Protection Bot",
        [string]$Color = "good"
    )
    
    $payload = @{
        channel = $Channel
        username = $Username
        attachments = @(
            @{
                color = $Color
                text = $Message
                ts = [int][double]::Parse((Get-Date -UFormat %s))
            }
        )
    } | ConvertTo-Json -Depth 3
    
    try {
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $payload -ContentType "application/json"
        Write-Host "✅ Slack notification sent successfully" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to send Slack notification: $($_.Exception.Message)"
    }
}

# Enhanced script with Slack notifications
$results = @()
foreach ($repo in $Repos) {
    $result = Set-BranchProtection -Repo $repo -Branch $Branch -Token $GithubPAT
    $results += $result
    
    if ($result.Status -eq "Success") {
        $message = "✅ Branch protection applied to $repo/$Branch"
        Send-SlackNotification -WebhookUrl $SlackWebhook -Message $message -Color "good"
    } else {
        $message = "❌ Failed to protect $repo/$Branch : $($result.Error)"
        Send-SlackNotification -WebhookUrl $SlackWebhook -Message $message -Color "danger"
    }
}
```

## 📊 Monitoring and Reporting Examples

### PowerShell Monitoring Script

```powershell
# BranchProtectionMonitor.ps1
function Get-BranchProtectionStatus {
    param(
        [string]$GithubPAT,
        [string[]]$Repositories,
        [string]$Branch = "main"
    )
    
    $results = @()
    
    foreach ($repo in $Repositories) {
        try {
            $uri = "https://api.github.com/repos/$repo/branches/$Branch/protection"
            $headers = @{
                "Authorization" = "Bearer $GithubPAT"
                "Accept" = "application/vnd.github+json"
            }
            
            $protection = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
            
            $results += [PSCustomObject]@{
                Repository = $repo
                Branch = $Branch
                Protected = $true
                RequiredReviews = $protection.required_pull_request_reviews.required_approving_review_count
                EnforceAdmins = $protection.enforce_admins.enabled
                StatusChecks = $protection.required_status_checks.contexts -join ", "
                LastChecked = Get-Date
            }
        }
        catch {
            $results += [PSCustomObject]@{
                Repository = $repo
                Branch = $Branch
                Protected = $false
                Error = $_.Exception.Message
                LastChecked = Get-Date
            }
        }
    }
    
    return $results
}

# Generate compliance report
$repos = @("Stratovate-Solutions/TeamsSurveyConfig", "Stratovate-Solutions/TeamsVoiceDiscovery")
$status = Get-BranchProtectionStatus -GithubPAT $GithubPAT -Repositories $repos

# Export to CSV
$status | Export-Csv -Path "BranchProtectionStatus_$(Get-Date -Format 'yyyyMMdd').csv" -NoTypeInformation

# Display summary
$protected = ($status | Where-Object Protected -eq $true).Count
$total = $status.Count
Write-Host "Protection Status: $protected/$total repositories protected" -ForegroundColor $(if ($protected -eq $total) { "Green" } else { "Yellow" })
```

### GitHub Actions Monitoring Workflow

```yaml
name: Branch Protection Monitoring

on:
  schedule:
    - cron: '0 8 * * 1'  # Weekly Monday morning report
  workflow_dispatch:

jobs:
  monitor-protection:
    runs-on: ubuntu-latest
    
    steps:
      - name: Check Branch Protection Status
        uses: actions/github-script@v7
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            const repos = [
              'Stratovate-Solutions/TeamsSurveyConfig',
              'Stratovate-Solutions/TeamsVoiceDiscovery',
              'Stratovate-Solutions/Teams-Health-Toolkit'
            ];
            
            const results = [];
            
            for (const repoName of repos) {
              const [owner, repo] = repoName.split('/');
              
              try {
                const { data: protection } = await github.rest.repos.getBranchProtection({
                  owner,
                  repo,
                  branch: 'main'
                });
                
                results.push({
                  repository: repoName,
                  protected: true,
                  requiredReviews: protection.required_pull_request_reviews?.required_approving_review_count || 0,
                  enforceAdmins: protection.enforce_admins.enabled,
                  statusChecks: protection.required_status_checks?.contexts.join(', ') || 'None'
                });
              } catch (error) {
                results.push({
                  repository: repoName,
                  protected: false,
                  error: error.message
                });
              }
            }
            
            // Generate report
            const protected = results.filter(r => r.protected).length;
            const total = results.length;
            
            let report = `# 🛡️ Branch Protection Status Report\n\n`;
            report += `**Overall Status:** ${protected}/${total} repositories protected\n\n`;
            report += `| Repository | Protected | Required Reviews | Enforce Admins | Status Checks |\n`;
            report += `|------------|-----------|------------------|----------------|---------------|\n`;
            
            for (const result of results) {
              const status = result.protected ? '✅' : '❌';
              const reviews = result.requiredReviews || 'N/A';
              const admins = result.enforceAdmins ? '✅' : '❌';
              const checks = result.statusChecks || 'None';
              
              report += `| ${result.repository} | ${status} | ${reviews} | ${admins} | ${checks} |\n`;
            }
            
            if (protected < total) {
              report += `\n⚠️ **Action Required:** ${total - protected} repositories need protection configuration.\n`;
            }
            
            console.log(report);
            
            // Create issue if repositories are unprotected
            if (protected < total) {
              await github.rest.issues.create({
                owner: 'Stratovate-Solutions',
                repo: 'BranchProtectionPolicy',
                title: `Branch Protection Status Alert - ${total - protected} repositories unprotected`,
                body: report,
                labels: ['security', 'compliance']
              });
            }
```

These examples provide comprehensive coverage of different usage scenarios, from basic script execution to advanced automation and monitoring workflows. Adapt them to your specific organizational needs and security requirements.