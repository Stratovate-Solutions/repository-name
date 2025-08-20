# Changelog

All notable changes to the Branch Protection Policy project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive documentation and inline comments
- Enhanced error handling with specific troubleshooting guidance
- Secure token storage examples and best practices
- CSV export functionality for audit trails
- GitHub Actions workflow integration
- Organization-wide policy templates

### Changed
- Upgraded to PowerShell 7.0+ requirements
- Enhanced API error handling with specific status code responses
- Improved logging with structured output and file generation
- Updated to use Bearer token authentication format
- Enhanced parameter validation with descriptive error messages

### Security
- Added secure credential storage mechanisms
- Implemented token format validation
- Enhanced audit logging capabilities
- Added rate limiting between API requests

## [2.0.0] - 2025-08-19

### Added
- **Comprehensive Documentation**: Added detailed inline comments, parameter documentation, and usage examples
- **Enhanced Security**: Secure token handling with encrypted storage options
- **Advanced Error Handling**: Detailed error diagnostics with troubleshooting suggestions
- **Audit Logging**: Structured logging with file output and CSV reporting
- **GitHub Actions Integration**: Reusable workflows for automated protection application
- **Parameter Validation**: Enhanced input validation with descriptive error messages
- **WhatIf Support**: Test mode for validating configurations without applying changes
- **Status Check Support**: Configurable required status checks for CI/CD integration
- **Flexible Configuration**: Customizable review requirements and protection settings

### Changed
- **PowerShell 7.0+ Requirement**: Updated for modern PowerShell features and cross-platform compatibility
- **Bearer Token Authentication**: Updated to use modern GitHub API authentication
- **API Version Specification**: Added explicit API version for consistency
- **Enhanced Output**: Improved console output with color coding and progress indicators
- **Function Restructure**: Modularized code with proper function separation and documentation

### Fixed
- **Rate Limiting**: Added delays between API requests to respect GitHub API limits
- **Error Recovery**: Improved error handling with retry logic for transient failures
- **Token Validation**: Added token format validation before API calls
- **Repository Validation**: Enhanced repository name format validation

### Security
- **Secure Storage**: Added examples for secure token storage using Windows credential systems
- **Minimal Permissions**: Updated token requirements to use minimal necessary scopes
- **Audit Trail**: Comprehensive logging for security compliance and auditing
- **Input Sanitization**: Enhanced parameter validation to prevent injection attacks

## [1.1.0] - 2024-12-15

### Added
- Basic error handling for API failures
- Repository name validation
- Simple console output with success/failure indicators

### Changed
- Updated repository list to include current Stratovate Solutions projects
- Improved API request structure

### Fixed
- Handle empty status checks array properly
- Fixed token header format for GitHub API

## [1.0.0] - 2024-06-01

### Added
- Initial release of branch protection policy script
- Basic functionality to apply protection to multiple repositories
- Simple PowerShell script with minimal error handling
- Support for configurable repository lists and branch names
- GitHub API integration for branch protection

### Features
- Batch application of branch protection policies
- Configurable repository lists
- Basic authentication with GitHub Personal Access Tokens
- Standard protection settings enforcement

---

## Migration Guide

### Upgrading from v1.x to v2.0

#### Breaking Changes
1. **PowerShell Version**: Now requires PowerShell 7.0+
2. **Parameter Changes**: Enhanced parameter validation may affect existing scripts
3. **Output Format**: Log output format has changed significantly

#### Migration Steps
1. **Update PowerShell**: Install PowerShell 7.0 or later
2. **Update Token Storage**: Implement secure token storage (optional but recommended)
3. **Review Parameters**: Check any automated scripts for parameter compatibility
4. **Update Error Handling**: Review any scripts that parse output for new format

#### New Features Available
- Use `-WhatIf` parameter for testing configurations
- Leverage enhanced logging for better monitoring
- Implement secure token storage for production use
- Use new GitHub Actions workflows for automation

### Configuration Migration

#### Old Configuration (v1.x)
```powershell
.\BranchProtectionPolicy.ps1 -GithubPAT "token" -Repos @("repo1", "repo2")
```

#### New Configuration (v2.0)
```powershell
# Basic usage (unchanged)
.\BranchProtectionPolicy.ps1 -GithubPAT "token" -Repos @("repo1", "repo2")

# Enhanced usage with new features
.\BranchProtectionPolicy.ps1 -GithubPAT "token" -Repos @("repo1", "repo2") -Verbose -WhatIf
```

---

## Support

For questions about specific versions or migration assistance:

- **Current Version Issues**: [GitHub Issues](https://github.com/Stratovate-Solutions/BranchProtectionPolicy/issues)
- **Migration Help**: Contact DevOps team at devops@stratovate.com
- **Feature Requests**: [GitHub Discussions](https://github.com/Stratovate-Solutions/BranchProtectionPolicy/discussions)

---

*This changelog is maintained by the Stratovate Solutions DevOps team.*