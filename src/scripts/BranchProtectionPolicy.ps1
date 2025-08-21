<#
.SYNOPSIS
    Applies standardized branch protection policies to multiple GitHub repositories.

.DESCRIPTION
    This script automates the process of configuring branch protection policies across
    multiple GitHub repositories in the Stratovate Solutions organization. It ensures
    consistent security and quality standards by enforcing:
    - Required pull request reviews (1 approver minimum)
    - Dismissal of stale reviews on new commits
    - Admin enforcement of protection rules
    - Prevention of force pushes and branch deletions
    - Optional status check requirements

.PARAMETER GithubPAT
    GitHub Personal Access Token with 'repo' scope and admin permissions.
    Required for authenticating API calls to modify repository settings.
    
    Security Note: Store this token securely and never commit it to version control.
    Consider using GitHub Secrets or secure credential storage.

.PARAMETER Repos
    Array of repository names in "owner/repository" format to apply protection policies.
    Defaults to all current Stratovate Solutions Teams-related repositories.
    
    Examples:
    - "Stratovate-Solutions/TeamsSurveyConfig"
    - "myorg/myrepo"

.PARAMETER Branch
    Target branch name to protect. Defaults to "main".
    Common alternatives include "master", "develop", or "production".

.EXAMPLE
    .\BranchProtectionPolicy.ps1 -GithubPAT "ghp_xxxxxxxxxxxxxxxxxxxx"
    
    Applies default protection policies to all predefined repositories on the main branch.

.EXAMPLE
    .\BranchProtectionPolicy.ps1 -GithubPAT "ghp_xxxxxxxxxxxxxxxxxxxx" -Branch "develop" -Repos @("myorg/repo1", "myorg/repo2")
    
    Applies protection policies to specific repositories on the develop branch.

.EXAMPLE
    # Secure PAT storage and retrieval
    $secureToken = Read-Host "Enter GitHub PAT" -AsSecureString
    $plainToken = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken))
    .\BranchProtectionPolicy.ps1 -GithubPAT $plainToken

.NOTES
    File Name      : BranchProtectionPolicy.ps1
    Author         : Stratovate Solutions
    Prerequisite   : PowerShell 7.0+ for optimal compatibility
    Copyright      : (c) 2025 Stratovate Solutions LLC. All rights reserved.
    
    Version History:
    - v1.0: Initial version with basic branch protection
    - v1.1: Added secure token handling and enhanced error reporting
    - v1.2: Improved documentation and parameter validation

.LINK
    GitHub API Documentation: https://docs.github.com/en/rest/branches/branch-protection
    
.LINK
    Stratovate Solutions GitHub: https://github.com/Stratovate-Solutions

.INPUTS
    System.String
        GitHub PAT token for authentication
    
    System.String[]
        Array of repository names to protect
        
    System.String
        Branch name to apply protection to

.OUTPUTS
    System.Void
        Writes status messages to console indicating success/failure for each repository
        
    GitHub API Response Objects
        Success responses contain branch protection configuration details
#>

#Requires -Version 7.0
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(
        Mandatory = $true,
        HelpMessage = "GitHub Personal Access Token with repo admin scope"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$GithubPAT,
    
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Array of repositories in 'owner/repo' format"
    )]
    [ValidateScript({
        $_ | ForEach-Object { 
            if ($_ -notmatch '^[\w\-\.]+/[\w\-\.]+$') {
                throw "Repository '$_' must be in 'owner/repository' format"
            }
        }
        return $true
    })]
    [string[]]$Repos = @(
        "Stratovate-Solutions/TeamsSurveyConfig",
        "Stratovate-Solutions/TeamsVoiceDiscovery", 
        "Stratovate-Solutions/TeamsOperatorConnectServiceOffering",
        "Stratovate-Solutions/TeamsPhoneProvisioning",
        "Stratovate-Solutions/TeamsPhonePSTNQuality",
        "Stratovate-Solutions/Teams-Health-Toolkit",
        "Stratovate-Solutions/Utilities",
        "Stratovate-Solutions/StrideCHC-Teams-Voice-Deployment",
        "Stratovate-Solutions/wta-pilot-metrics",
        "Stratovate-Solutions/TeamsResourceAccount"
    ),
    
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Branch name to protect (default: main)"
    )]
    [ValidateNotNullOrEmpty()]
    [string]$Branch = "main"
)

#region Security and Token Management
<#
    SECURITY BEST PRACTICES:
    
    1. Never store PATs in plain text files or commit them to version control
    2. Use Windows Credential Manager or Azure Key Vault for production environments
    3. Rotate PATs regularly (GitHub recommends every 90 days)
    4. Use fine-grained PATs with minimal necessary permissions
    5. Consider using GitHub Apps for organization-wide automation
    
    The following code demonstrates secure token storage for one-time setup.
    Uncomment and run once to store your PAT securely, then comment out again.
#>

# UNCOMMENT FOR INITIAL SECURE TOKEN STORAGE SETUP:
# Write-Information "Setting up secure token storage..." -InformationAction Continue
# $securePath = "$env:USERPROFILE\.github"
# if (-not (Test-Path $securePath)) { New-Item -ItemType Directory -Path $securePath -Force }
# $pat = Read-Host "Enter your GitHub PAT" -AsSecureString
# $pat | ConvertFrom-SecureString | Out-File "$securePath\github-pat.txt"
# Write-Information "Token stored securely. Comment out this section and use the retrieval code below." -InformationAction Continue

# SECURE TOKEN RETRIEVAL (use this in production):
# $securePath = "$env:USERPROFILE\.github\github-pat.txt"
# if (Test-Path $securePath) {
#     $secureString = Get-Content $securePath | ConvertTo-SecureString
#     $GithubPAT = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
#         [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
#     )
#     Write-Information "Token retrieved from secure storage." -InformationAction Continue
# }
#endregion

#region Logging and Error Handling Configuration

# Configure PowerShell preferences for better error handling
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"  # Suppress progress bars for cleaner output

# Initialize logging
$LogPath = "$PSScriptRoot\Logs"
if (-not (Test-Path $LogPath)) { 
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null 
}

$LogFile = Join-Path $LogPath "BranchProtection_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-BranchProtectionLog {
    <#
    .SYNOPSIS
        Writes timestamped messages to both console and log file.
    
    .PARAMETER Message
        The message to log.
        
    .PARAMETER Level
        Log level: Info, Warning, Error, Success.
    #>
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to file
    $logEntry | Out-File -FilePath $LogFile -Append -Encoding UTF8
    
    # Write to console with color coding using Write-Information and Write-Warning instead of Write-Host
    switch ($Level) {
        "Info"    { Write-Information $logEntry -InformationAction Continue }
        "Warning" { Write-Warning $logEntry }
        "Error"   { Write-Error $logEntry -ErrorAction Continue }
        "Success" { Write-Information $logEntry -InformationAction Continue }
    }
}

Write-BranchProtectionLog "Branch Protection Policy script started" -Level "Info"
Write-BranchProtectionLog "Log file: $LogFile" -Level "Info"
Write-BranchProtectionLog "Target repositories: $($Repos.Count)" -Level "Info"
Write-BranchProtectionLog "Target branch: $Branch" -Level "Info"

#endregion

#region Branch Protection Configuration

function Set-BranchProtection {
    <#
    .SYNOPSIS
        Applies branch protection settings to a specific GitHub repository branch.
    
    .DESCRIPTION
        This function configures branch protection policies using the GitHub REST API.
        It enforces security best practices including required reviews, status checks,
        and restrictions on force pushes and deletions.
    
    .PARAMETER Repo
        Repository name in "owner/repository" format.
        
    .PARAMETER Branch
        Target branch name to protect.
        
    .PARAMETER Token
        GitHub Personal Access Token with repository admin permissions.
    
    .PARAMETER RequiredStatusChecks
        Array of required status check contexts that must pass before merging.
        Examples: @("ci/build", "security/scan", "tests/unit")
    
    .PARAMETER RequiredReviewers
        Number of required approving reviews before merge (default: 1).
    
    .PARAMETER RequireCodeOwnerReviews
        Whether to require reviews from code owners (default: false).
        
    .PARAMETER EnforceAdmins
        Whether to enforce restrictions for repository administrators (default: true).
    
    .EXAMPLE
        Set-BranchProtection -Repo "myorg/myrepo" -Branch "main" -Token $token
        
    .EXAMPLE
        Set-BranchProtection -Repo "myorg/myrepo" -Branch "main" -Token $token -RequiredStatusChecks @("ci/build") -RequiredReviewers 2
    
    .OUTPUTS
        PSCustomObject containing the API response with protection configuration details.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if ($_ -notmatch '^[\w\-\.]+/[\w\-\.]+$') {
                throw "Repository must be in 'owner/repository' format"
            }
            return $true
        })]
        [string]$Repo,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Branch,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Token,
        
        [Parameter(Mandatory = $false)]
        [string[]]$RequiredStatusChecks = @(),
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 6)]
        [int]$RequiredReviewers = 1,
        
        [Parameter(Mandatory = $false)]
        [bool]$RequireCodeOwnerReviews = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$EnforceAdmins = $true,
        
        [Parameter(Mandatory = $false)]
        [bool]$AllowForcePushes = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$AllowDeletions = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$DismissStaleReviews = $true
    )
    
    try {
        Write-BranchProtectionLog "Configuring protection for $Repo/$Branch..." -Level "Info"
        
        # Validate token format (basic check)
        if ($Token -notmatch '^(ghp_|github_pat_)[\w]{36,}$') {
            Write-BranchProtectionLog "Warning: Token format may be invalid. Expected format: ghp_* or github_pat_*" -Level "Warning"
        }
        
        # Construct API endpoint
        $uri = "https://api.github.com/repos/$Repo/branches/$Branch/protection"
        
        # Prepare request headers
        $headers = @{
            "Authorization" = "Bearer $Token"  # Updated to Bearer token format
            "Accept"        = "application/vnd.github+json"
            "User-Agent"    = "Stratovate-BranchProtectionScript/1.2"
            "X-GitHub-Api-Version" = "2022-11-28"  # Specify API version for consistency
        }
        
        # Build protection configuration object
        $protectionConfig = @{
            # Required status checks configuration
            required_status_checks = if ($RequiredStatusChecks.Count -gt 0) {
                @{
                    strict   = $true        # Require branches to be up to date before merging
                    contexts = $RequiredStatusChecks
                }
            } else { 
                $null  # No status checks required
            }
            
            # Admin enforcement
            enforce_admins = $EnforceAdmins
            
            # Pull request review requirements
            required_pull_request_reviews = @{
                required_approving_review_count = $RequiredReviewers
                dismiss_stale_reviews          = $DismissStaleReviews
                require_code_owner_reviews     = $RequireCodeOwnerReviews
                restrict_pushes_that_create_pr = $false  # Allow PR creation from any user
                require_last_push_approval     = $false  # Don't require fresh approval after each push
            }
            
            # Restrictions (null = no restrictions, applies to all users)
            restrictions = $null
            
            # Force push and deletion controls
            allow_force_pushes = $AllowForcePushes
            allow_deletions    = $AllowDeletions
            
            # Additional security settings
            block_creations = $false  # Allow branch creation
            required_linear_history = $false  # Allow merge commits
        }
        
        # Convert to JSON with proper depth for nested objects
        $requestBody = $protectionConfig | ConvertTo-Json -Depth 10 -Compress
        
        Write-BranchProtectionLog "Protection settings: $requestBody" -Level "Info"
        
        # Make API request with WhatIf support
        if ($PSCmdlet.ShouldProcess($Repo, "Apply branch protection to $Branch")) {
            $response = Invoke-RestMethod -Method PUT -Uri $uri -Headers $headers -Body $requestBody -ContentType "application/json"
            
            Write-BranchProtectionLog "✅ Successfully applied protection to $Repo/$Branch" -Level "Success"
            Write-BranchProtectionLog "Protection URL: $($response.url)" -Level "Info"
            
            return [PSCustomObject]@{
                Repository = $Repo
                Branch = $Branch
                Status = "Success"
                Url = $response.url
                RequiredStatusChecks = $RequiredStatusChecks
                RequiredReviewers = $RequiredReviewers
                EnforceAdmins = $EnforceAdmins
                Response = $response
            }
        } else {
            Write-BranchProtectionLog "WhatIf: Would apply protection to $Repo/$Branch" -Level "Info"
            return [PSCustomObject]@{
                Repository = $Repo
                Branch = $Branch
                Status = "WhatIf"
                RequiredStatusChecks = $RequiredStatusChecks
                RequiredReviewers = $RequiredReviewers
                EnforceAdmins = $EnforceAdmins
            }
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        $statusCode = $_.Exception.Response.StatusCode.value__ -as [int]
        
        # Enhanced error handling with specific GitHub API error responses
        switch ($statusCode) {
            401 { 
                Write-BranchProtectionLog "❌ Authentication failed: Invalid or expired token for $Repo" -Level "Error"
                $suggestion = "Verify token has 'repo' scope and hasn't expired"
            }
            403 { 
                Write-BranchProtectionLog "❌ Forbidden: Insufficient permissions for $Repo" -Level "Error" 
                $suggestion = "Ensure token has admin permissions on the repository"
            }
            404 { 
                Write-BranchProtectionLog "❌ Not found: Repository or branch '$Branch' doesn't exist for $Repo" -Level "Error"
                $suggestion = "Verify repository name and branch exist"
            }
            422 { 
                Write-BranchProtectionLog "❌ Validation failed: Invalid protection configuration for $Repo" -Level "Error"
                $suggestion = "Check protection settings for conflicts or invalid values"
            }
            default { 
                Write-BranchProtectionLog "❌ Unexpected error ($statusCode): $errorMessage" -Level "Error"
                $suggestion = "Check GitHub API status and try again"
            }
        }
        
        Write-BranchProtectionLog "Suggestion: $suggestion" -Level "Warning"
        
        return [PSCustomObject]@{
            Repository = $Repo
            Branch = $Branch
            Status = "Failed"
            Error = $errorMessage
            StatusCode = $statusCode
            Suggestion = $suggestion
        }
    }
}

#endregion

#region Main Execution Logic

try {
    Write-BranchProtectionLog "Starting branch protection application process..." -Level "Info"
    
    # Validate GitHub token format
    if ($GithubPAT -notmatch '^(ghp_|github_pat_)[\w]{36,}$') {
        Write-BranchProtectionLog "Warning: GitHub token format appears invalid. Expected: ghp_* or github_pat_*" -Level "Warning"
        $confirmation = Read-Host "Continue anyway? (y/N)"
        if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
            Write-BranchProtectionLog "Operation cancelled by user" -Level "Warning"
            exit 1
        }
    }
    
    # Initialize results tracking
    $results = @()
    $successCount = 0
    $failureCount = 0
    
    # Process each repository
    Write-BranchProtectionLog "Processing $($Repos.Count) repositories..." -Level "Info"
    
    foreach ($repo in $Repos) {
        Write-BranchProtectionLog "Processing repository: $repo" -Level "Info"
        
        try {
            # Apply branch protection with enhanced configuration
            $result = Set-BranchProtection -Repo $repo -Branch $Branch -Token $GithubPAT -Verbose:$VerbosePreference
            $results += $result
            
            if ($result.Status -eq "Success") {
                $successCount++
            } elseif ($result.Status -eq "Failed") {
                $failureCount++
            }
        }
        catch {
            Write-BranchProtectionLog "Unexpected error processing $repo : $($_.Exception.Message)" -Level "Error"
            $failureCount++
            
            $results += [PSCustomObject]@{
                Repository = $repo
                Branch = $Branch
                Status = "Failed"
                Error = $_.Exception.Message
            }
        }
        
        # Add a small delay between requests to be respectful to GitHub API
        Start-Sleep -Milliseconds 500
    }
    
    # Generate summary report
    Write-BranchProtectionLog "`n=== BRANCH PROTECTION SUMMARY ===" -Level "Info"
    Write-BranchProtectionLog "Total repositories processed: $($Repos.Count)" -Level "Info"
    Write-BranchProtectionLog "Successful applications: $successCount" -Level "Success"
    Write-BranchProtectionLog "Failed applications: $failureCount" -Level $(if ($failureCount -gt 0) { "Error" } else { "Info" })
    
    # Detailed results
    Write-BranchProtectionLog "`n=== DETAILED RESULTS ===" -Level "Info"
    foreach ($result in $results) {
        $status = $result.Status
        $level = switch ($status) {
            "Success" { "Success" }
            "Failed" { "Error" }
            "WhatIf" { "Info" }
            default { "Warning" }
        }
        
        Write-BranchProtectionLog "$($result.Repository)/$($result.Branch): $status" -Level $level
        
        if ($result.Error) {
            Write-BranchProtectionLog "  Error: $($result.Error)" -Level "Error"
            if ($result.Suggestion) {
                Write-BranchProtectionLog "  Suggestion: $($result.Suggestion)" -Level "Warning"
            }
        }
    }
    
    # Export results to CSV for further analysis
    $csvPath = Join-Path $LogPath "BranchProtection_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-BranchProtectionLog "Results exported to: $csvPath" -Level "Info"
    
    # Final status
    if ($failureCount -eq 0) {
        Write-BranchProtectionLog "`n🎉 All repositories successfully protected!" -Level "Success"
        exit 0
    } else {
        Write-BranchProtectionLog "`n⚠️  Some repositories failed to be protected. Check logs for details." -Level "Warning"
        exit 1
    }
}
catch {
    Write-BranchProtectionLog "Critical error in main execution: $($_.Exception.Message)" -Level "Error"
    Write-BranchProtectionLog "Stack trace: $($_.ScriptStackTrace)" -Level "Error"
    exit 2
}
finally {
    Write-BranchProtectionLog "Branch protection script completed at $(Get-Date)" -Level "Info"
    Write-BranchProtectionLog "Full log available at: $LogFile" -Level "Info"
}

#endregion

<#
.NOTES
    TROUBLESHOOTING GUIDE:
    
    Common Issues and Solutions:
    
    1. 401 Unauthorized Error:
       - Token expired or invalid
       - Token doesn't have 'repo' scope
       - Solution: Generate new PAT with proper permissions
    
    2. 403 Forbidden Error:
       - Insufficient repository permissions
       - Token lacks admin access
       - Solution: Ensure admin access or ask repo owner to grant permissions
    
    3. 404 Not Found Error:
       - Repository name incorrect
       - Branch doesn't exist
       - Private repo without access
       - Solution: Verify repository name and branch existence
    
    4. 422 Validation Error:
       - Invalid protection configuration
       - Conflicting settings
       - Solution: Review protection settings and GitHub documentation
    
    5. Rate Limiting:
       - Too many API requests
       - Solution: Implement delays between requests (already included)
    
    Best Practices:
    - Test with a single repository first using -WhatIf
    - Keep tokens secure and rotate regularly
    - Monitor GitHub API rate limits
    - Review protection policies periodically
    - Use organization-level policies when possible
#>
