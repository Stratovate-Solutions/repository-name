# Microsoft Teams Voice Discovery Tool - GitHub Copilot Instructions

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Bootstrap, Build, and Test the Repository
- `pwsh --version` -- verify PowerShell 7+ is available (tested: 7.4.10 works)
- Install MicrosoftTeams module: `pwsh -Command "Install-Module MicrosoftTeams -Force -Scope CurrentUser"`
- Verify module: `pwsh -Command "Get-Module MicrosoftTeams -ListAvailable"`
- **CRITICAL**: Module requires version 5.6.0+ for compatibility
- Import the tool module: `pwsh -Command "Import-Module ./src/TeamsVoiceExportModule.psd1 -Force"`
- **Import CSV module**: `pwsh -Command "Import-Module ./src/Export-TeamsCSV.psm1 -Force"` (no unapproved verb warnings)
- Run tests: `pwsh ./tests/Run-AllTests.ps1 -ContinueOnFailure` -- takes **54 seconds**. NEVER CANCEL. Set timeout to 90+ seconds.
- Comprehensive test validation: `pwsh ./tests/Run-AllTests.ps1 -TestSuite All -ContinueOnFailure -GenerateReport` -- takes **54 seconds**. NEVER CANCEL.

### Running the Application
- **ALWAYS run the bootstrapping steps first**
- Interactive menu (recommended): `pwsh ./Start-TeamsVoiceMenu.ps1` -- **NOW INCLUDES ALL 4 EXPORT OPTIONS**
- Direct export: `pwsh ./Start-TeamsVoiceExport.ps1`
- With Word reports: `pwsh ./Start-TeamsVoiceExport.ps1 -IncludeWordReport`
- **Quick export mode**: `pwsh ./Start-TeamsVoiceExport.ps1 -QuickMode` -- essential data only for rapid assessment
- **Interactive custom export**: `pwsh ./Start-TeamsVoiceExport.ps1 -Interactive` -- select specific components
- Test mode without Teams connection: `pwsh ./Start-TeamsVoiceExport.ps1 -WhatIf` -- NOTE: WhatIf not supported, will error

### Tool Validation and Troubleshooting
- Test Teams module: `pwsh ./tools/Fix-TeamsModule.ps1 -TestOnly` -- takes **8 seconds**. Set timeout to 30+ seconds.
- Fix Teams issues: `pwsh ./tools/Fix-TeamsModule.ps1 -ForceReinstall`
- Create client packages: `pwsh ./tools/Create-EngagementPackage.ps1 -ClientName "TestClient"`

## Validation

### Manual Validation Requirements
- **ALWAYS run through at least one complete end-to-end scenario after making changes**
- Test the interactive menu startup by running `pwsh ./Start-TeamsVoiceMenu.ps1` and verify the professional header displays correctly (timeout after 3 seconds to exit safely)
- **NEW**: Verify all 4 export options display in menu: Standard, Executive, Quick, Custom
- Validate help system: `pwsh -Command "Get-Help ./Start-TeamsVoiceExport.ps1"` should display comprehensive help with examples
- Validate configuration: `pwsh -Command "Test-Path ./config/TeamsVoiceConfig.json && (Get-Content ./config/TeamsVoiceConfig.json | ConvertFrom-Json | Select-Object -ExpandProperty ExportTargets).Count"` should return "True" and "24"
- **Teams Connection Testing**: The tool requires Microsoft Teams connectivity for actual exports. Without Teams connection, you can only test:
  - Module import and syntax validation
  - Test suite execution (62/63 tests pass without Teams)
  - Menu system startup (professional header displays)
  - Configuration file validation (39/40 tests pass)
  - Security validation (16/17 tests pass)
- **With Teams Connection**: Always test by connecting to Teams and running a complete export to validate all functionality

### Specific Manual Test Scenarios
After making any changes, run these validation scenarios:
1. **Module Import Test**: `pwsh -Command "Import-Module ./src/TeamsVoiceExportModule.psd1 -Force; Get-Module TeamsVoiceExportModule"` - should show module loaded despite MicrosoftTeams warning
2. **CSV Module Import Test**: `pwsh -Command "Import-Module ./src/Export-TeamsCSV.psm1 -Force; Get-Module Export-TeamsCSV"` - should load without unapproved verb warnings
3. **Configuration Validation**: `pwsh ./tests/Test-TeamsVoiceExport.ps1 -TestType Configuration` - should show 39/40 pass
4. **Security Validation**: `pwsh ./tests/Test-TeamsVoiceExport.ps1 -TestType Security` - should show 16/17 pass  
5. **Menu Startup Test**: `timeout 3 pwsh ./Start-TeamsVoiceMenu.ps1` - should display professional header with 4 export options
6. **Help System Test**: `pwsh -Command "Get-Help ./Start-TeamsVoiceExport.ps1 -Examples"` - should show 4 usage examples including QuickMode
7. **Export Options Test**: Verify menu shows: \[1\] Standard Export, \[2\] Executive Export, \[3\] Quick Export, \[4\] Custom Export

### Expected Test Results
- Unit tests: 62/63 pass (MicrosoftTeams dependency failure expected without module installed)
- Configuration tests: 39/40 pass (module loading failure expected without Teams module)
- Security tests: 16/17 pass (1 skipped due to platform ACL limitations)
- Performance tests: 21/22 pass (concurrent operations slow but functional)
- **Module compliance**: No PowerShell unapproved verb warnings (fixed Flatten-PSObject → ConvertTo-FlatObject)
- **Error handling**: Proper exit code propagation (no more false success messages)
- Total test time: **54 seconds** for complete suite
- Module import: Loads successfully despite MicrosoftTeams dependency warning

### Required Validation Commands
- Always run before committing: `pwsh ./tests/Run-AllTests.ps1 -ContinueOnFailure`
- Syntax validation: Module imports successfully with warnings about missing MicrosoftTeams dependency
- Configuration validation: JSON configuration files must parse correctly
- **NEW**: Exit code validation: Failed exports properly return exit code 1

## Common Tasks

### Repository Structure
```
TeamsVoiceDiscovery/
├── Start-TeamsVoiceMenu.ps1         # Interactive CLI menu (recommended entry point) - UPDATED
├── Start-TeamsVoiceExport.ps1       # Clean launcher with process isolation - ENHANCED
├── TeamsVoiceConfigExport.ps1       # Core export script - ENHANCED
├── src/                             # Source code (PowerShell module)
│   ├── TeamsVoiceExportModule.psm1  # Main module (1317+ lines)
│   ├── TeamsVoiceExportModule.psd1  # Module manifest
│   └── Export-TeamsCSV.psm1         # CSV export module (MOVED from modules/)
├── config/                          # Configuration management
│   └── TeamsVoiceConfig.json        # Export targets and settings (24 export targets)
├── tests/                           # Test framework (183 comprehensive tests)
│   ├── Test-TeamsVoiceExport.ps1    # Main test suite
│   ├── Run-AllTests.ps1             # Test runner
│   └── Test-*.ps1                   # Specialized test suites
├── tools/                           # Utility scripts
│   ├── Fix-TeamsModule.ps1          # Teams module troubleshooting
│   └── Create-EngagementPackage.ps1 # Client deliverable generation
├── output/                          # Export output directory (auto-created)
├── logs/                            # Application logs (auto-created)
├── backups/                         # Configuration backups (auto-created)
└── docs/                            # Comprehensive documentation
```

### GitHub Community Files Organization
**IMPORTANT**: All GitHub community files must be located in the `.github/` directory according to GitHub best practices:

#### Required Locations:
- **`.github/CODE_OF_CONDUCT.md`** - Community behavior guidelines and enforcement policies
- **`.github/CONTRIBUTING.md`** - Developer contribution guidelines, coding standards, and pull request processes  
- **`.github/SECURITY.md`** - Security vulnerability reporting procedures and contact information
- **`.github/SUPPORT.md`** - User support resources, troubleshooting links, and help channels

#### File Placement Rules:
- **NEVER place community files in root directory** - GitHub won't automatically recognize them
- **Always use `.github/` prefix** - Enables automatic GitHub UI integration and repository health checks
- **Keep consistent naming** - Use UPPERCASE for community file names (GitHub convention)
- **Validate placement** - GitHub repository insights should show "Community" section with all files detected

#### Benefits of Proper Placement:
- **Automatic GitHub Recognition** - Files appear in repository "Community" tab and insights
- **Enhanced Discoverability** - GitHub promotes these files in repository interface
- **Professional Appearance** - Follows open-source project best practices and conventions
- **Clean Root Directory** - Separates development files from community/governance files

#### Root Directory Files (Correctly Positioned):
- **`README.md`** - Project overview and quick start (stays in root for immediate visibility)
- **`LICENSE.md`** - Legal license information (stays in root for GitHub license detection)
- **`CHANGELOG.md`** - Version history and release notes (stays in root for easy access)
- **Project-specific documentation** - Technical docs that don't fall under community guidelines

### Recent Code Changes and Enhancements

#### Export Menu System (MAJOR UPDATE)
- **All 4 Export Options Available**: Menu now properly displays Standard, Executive, Quick, and Custom export options
- **Enhanced Error Handling**: Fixed misleading success messages when Teams connection fails
- **Proper Exit Code Propagation**: Failed exports now correctly return exit code 1
- **QuickMode Support**: Added `-QuickMode` parameter for rapid essential data exports

#### PowerShell Compliance (FIXED)
- **Approved Verbs Only**: Renamed `Flatten-PSObject` to `ConvertTo-FlatObject` in CSV module
- **No Verb Warnings**: Module imports cleanly without PowerShell verb compliance warnings
- **Enhanced Validation**: Improved parameter validation throughout

#### Process Isolation (ENHANCED)
- **Better Error Detection**: Launcher properly captures subprocess exit codes
- **Clean Failure Reporting**: No more "Export completed successfully!" when exports fail
- **Debug Capabilities**: Enhanced logging for troubleshooting

### Key Components to Always Check
- **After changing src/TeamsVoiceExportModule.psm1**: Always test module import and run unit tests
- **After changing config/TeamsVoiceConfig.json**: Always validate JSON syntax and run configuration tests
- **After changing Start-TeamsVoiceMenu.ps1**: Always test menu startup and verify all 4 export options display
- **After changing any test files**: Always run the full test suite to ensure no regressions
- **NEW**: After changing exit code handling: Verify proper error propagation with failed export scenarios
- **After adding/moving community files**: Ensure all GitHub community files (CODE_OF_CONDUCT.md, CONTRIBUTING.md, SECURITY.md, SUPPORT.md) are in `.github/` directory for proper GitHub recognition

### Frequently Accessed Files (UPDATED PATHS)
- `src/TeamsVoiceExportModule.psm1` - Core business logic (most frequently modified)
- `src/Export-TeamsCSV.psm1` - CSV export functionality (moved from modules/)
- `config/TeamsVoiceConfig.json` - Export configuration (24 export targets defined)
- `Start-TeamsVoiceMenu.ps1` - Primary user interface (enhanced with 4 export options)
- `tests/Test-TeamsVoiceExport.ps1` - Main test validation
- `tools/Fix-TeamsModule.ps1` - Troubleshooting utility

### Dependencies and Installation
- **PowerShell 5.1+ required** (tested with PowerShell 7.4.10)
- **MicrosoftTeams module 5.6.0+ required** for production use
- **No build system**: This is a pure PowerShell solution with no compilation step
- **Installation command**: `Install-Module MicrosoftTeams -Force -Scope CurrentUser`
- **Verification**: `Get-Module MicrosoftTeams -ListAvailable` should show version 5.6.0+
- **NEW**: Import both modules: `Import-Module ./src/TeamsVoiceExportModule.psd1 -Force; Import-Module ./src/Export-TeamsCSV.psm1 -Force`

### Export Options and Parameters (UPDATED)

#### Available Export Modes
1. **Standard Export**: `pwsh ./Start-TeamsVoiceExport.ps1`
   - CSV and JSON files with all configuration data
   - Complete configuration export for technical teams

2. **Executive Export**: `pwsh ./Start-TeamsVoiceExport.ps1 -IncludeWordReport`
   - Standard export plus professional Word documents
   - Executive summaries and business-ready reports

3. **Quick Export** (NEW): `pwsh ./Start-TeamsVoiceExport.ps1 -QuickMode`
   - Essential data only for rapid assessment
   - Exports: VoiceRoutes, VoiceRoutingPolicies, DialPlans, DirectRoutingGateways, AutoAttendants, CallQueues

4. **Custom Export** (ENHANCED): `pwsh ./Start-TeamsVoiceExport.ps1 -Interactive`
   - Interactive selection of specific configuration components
   - Customizable for specific client requirements

#### Menu Navigation (ENHANCED)
- Menu option 2 now shows all 4 export options
- Clear descriptions for each export type
- Proper error handling for failed exports
- Exit code validation for automation scenarios

### Timing Expectations and Timeouts
- **Unit tests**: 0.48 seconds (set timeout: 30 seconds)
- **Complete test suite**: 54 seconds (set timeout: 90 seconds) - NEVER CANCEL
- **Performance tests**: 53.52 seconds (set timeout: 90 seconds) - NEVER CANCEL  
- **Module troubleshooting**: 8 seconds (set timeout: 30 seconds)
- **Module import**: <1 second (both modules)
- **Configuration validation**: <1 second
- **Quick export mode**: 15-20 seconds (vs 30+ seconds for full export)

### Error Scenarios and Troubleshooting (UPDATED)
- **Module import fails**: Expected if MicrosoftTeams not installed. Use `./tools/Fix-TeamsModule.ps1 -TestOnly` to diagnose
- **Test failures with MicrosoftTeams dependency**: Expected in environments without Teams module
- **Menu display corruption**: Normal in non-interactive terminals. Test with `Get-Help` commands instead
- **Export requires Teams connection**: Cannot test actual exports without Microsoft Teams authentication
- **NEW**: Exit code validation: Check `$LASTEXITCODE` after export operations for automation
- **NEW**: PowerShell verb warnings eliminated: All functions use approved PowerShell verbs

### CI/CD Integration Patterns (ENHANCED)
Based on documentation, the tool supports:
```yaml
# Azure DevOps
- task: PowerShell@2
  inputs:
    filePath: 'tests/Run-AllTests.ps1'
    arguments: '-GenerateReport -ContinueOnFailure'
  timeoutInMinutes: 2

# GitHub Actions  
- name: Run Tests
  shell: pwsh
  run: |
    ./tests/Run-AllTests.ps1 -GenerateReport
  timeout-minutes: 2

# Validate exit codes in automation
- name: Test Export Functionality
  shell: pwsh
  run: |
    ./Start-TeamsVoiceExport.ps1 -QuickMode
    if ($LASTEXITCODE -ne 0) { exit 1 }
```

### Production Deployment Notes (UPDATED)
- **Teams Administrator permissions required** for production use
- **Module distribution**: PowerShell Gallery ready (see .psd1 manifest)
- **No external dependencies** beyond PowerShell and MicrosoftTeams module
- **Output location**: `./output/` directory (auto-created)
- **Client packages**: Generated in structured folders via tools/Create-EngagementPackage.ps1
- **NEW**: Automated error detection for CI/CD pipelines
- **NEW**: QuickMode for rapid client assessments (15-minute exports vs 30+ minutes)

### Configuration Management
- Main config: `config/TeamsVoiceConfig.json` (279 lines, 24 export targets)
- Backup configs: Auto-generated in `backups/` directory
- Export validation: All 24 export targets validated in test suite
- JSON syntax: Must be valid JSON (validated in tests)
- **NEW**: QuickMode configuration: 6 essential export targets for rapid assessment

### Known Working Commands Reference (UPDATED)
These commands have been validated to work:
```powershell
# Module testing (both modules)
pwsh -Command "Test-ModuleManifest ./src/TeamsVoiceExportModule.psd1"
pwsh -Command "Import-Module ./src/Export-TeamsCSV.psm1 -Force"

# Test execution
pwsh ./tests/Run-AllTests.ps1 -ContinueOnFailure
pwsh ./tests/Test-TeamsVoiceExport.ps1 -TestType Unit

# Tool validation  
pwsh ./tools/Fix-TeamsModule.ps1 -TestOnly

# Help and documentation
pwsh -Command "Get-Help ./Start-TeamsVoiceExport.ps1"
pwsh -Command "Get-Help ./Start-TeamsVoiceExport.ps1 -Examples"

# Application startup (requires Teams for full functionality)
pwsh ./Start-TeamsVoiceMenu.ps1  # Shows all 4 export options
pwsh ./Start-TeamsVoiceExport.ps1  # Standard export
pwsh ./Start-TeamsVoiceExport.ps1 -IncludeWordReport  # Executive export
pwsh ./Start-TeamsVoiceExport.ps1 -QuickMode  # Quick assessment
pwsh ./Start-TeamsVoiceExport.ps1 -Interactive  # Custom selection

# Exit code validation for automation
pwsh ./Start-TeamsVoiceExport.ps1 -QuickMode; if ($LASTEXITCODE -ne 0) { Write-Error "Export failed" }
```

### Performance Baselines (UPDATED)
Validated performance metrics:
- **Module import**: <0.002 seconds average (both modules)
- **Configuration load**: <0.001 seconds average  
- **Test execution**: 0.36 seconds per test type
- **Memory usage**: <50MB baseline, +1.88MB during operations
- **Concurrent operations**: 10.036 seconds (acceptable for 5 concurrent processes)
- **Quick export**: 15-20 seconds (50% faster than full export)
- **Executive export**: 30-45 seconds (includes Word document generation)

### Breaking Changes and Migration Notes
- **Module Location**: Export-TeamsCSV moved from `modules/` to `src/` directory
- **Function Names**: `Flatten-PSObject` renamed to `ConvertTo-FlatObject` (PowerShell compliance)
- **Import Paths**: Update any scripts importing modules to use `./src/` path
- **Menu Options**: Menu now shows 4 export options instead of 2
- **Exit Codes**: Scripts now properly return non-zero exit codes on failure (check automation scripts)

### Quality Assurance Checklist
Before any release or major change:
- [ ] All 4 export options display in interactive menu
- [ ] No PowerShell unapproved verb warnings during module import
- [ ] Exit codes properly propagate (test with failed export scenarios)
- [ ] Complete test suite runs in 54 seconds without cancellation
- [ ] Help system shows 4 usage examples
- [ ] Configuration validation returns "True" and "24"
- [ ] Quick export mode functions correctly
- [ ] Module imports from `src/` directory without errors