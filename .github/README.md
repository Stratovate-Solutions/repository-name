# .github Repository

This repository contains organization-wide GitHub configurations, templates, and workflows for Stratovate Solutions.

## 📁 Directory Structure

```
.github/
├── ISSUE_TEMPLATE/           # Issue templates for bug reports and feature requests
│   ├── bug_report.yml       # Bug report template
│   ├── feature_request.yml  # Feature request template
│   └── config.yml          # Issue template configuration
├── workflows/               # GitHub Actions workflows
│   ├── ci.yml              # Continuous Integration pipeline
│   └── label-sync.yml      # Label synchronization workflow
├── CODEOWNERS              # Code ownership rules
├── dependabot.yml          # Dependabot configuration
├── FUNDING.yml             # Funding configuration
├── labels.yml              # Repository labels configuration
├── pull_request_template.md # Pull request template
└── settings.yml            # Repository settings template
```

## 🔧 Features

### Issue Templates
- **Bug Report**: Structured template for reporting bugs with environment details
- **Feature Request**: Template for suggesting new features with priority levels
- **Configuration**: Links to support channels and documentation

### Pull Request Template
- Comprehensive PR template with type classification
- Testing checklist and breaking change indicators
- Conventional commits format guidance

### GitHub Actions Workflows
- **CI/CD Pipeline**: Automated testing, linting, and security scanning
- **Label Sync**: Synchronizes repository labels across the organization

### Repository Configuration
- **Dependabot**: Automated dependency updates for multiple ecosystems
- **CODEOWNERS**: Defines code review responsibilities
- **Labels**: Standardized label schema for all repositories
- **Settings**: Default repository settings template

## 🚀 Usage

### For New Repositories
1. This repository automatically provides templates to all repositories in the organization
2. Issue and PR templates will be available automatically
3. Use the workflows as examples or copy them to your repository

### For Existing Repositories
1. Copy relevant workflow files to your repository's `.github/workflows/` directory
2. Customize the configurations based on your project needs
3. Update CODEOWNERS with your project-specific ownership rules

## 📝 Customization

### Adding New Issue Templates
1. Create a new YAML file in `ISSUE_TEMPLATE/`
2. Follow the GitHub issue form schema
3. Update `config.yml` if needed

### Modifying Workflows
1. Edit the workflow files in `workflows/`
2. Test changes in a fork or feature branch
3. Update documentation as needed

### Updating Labels
1. Modify `labels.yml` with new label definitions
2. The label-sync workflow will automatically apply changes
3. Use semantic colors and descriptions

## 🛡️ Security

- All workflows use pinned action versions for security
- Dependabot keeps dependencies up to date
- CodeQL analysis is included in CI pipeline
- Security policies are enforced through branch protection

## 📚 Documentation

- [GitHub Templates Documentation](https://docs.github.com/en/communities/using-templates-to-encourage-useful-issues-and-pull-requests)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Dependabot Documentation](https://docs.github.com/en/code-security/dependabot)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This repository is licensed under the MIT License. See [LICENSE](../LICENSE) for details.

---

**Stratovate Solutions** - Building the future, one solution at a time. ✨
