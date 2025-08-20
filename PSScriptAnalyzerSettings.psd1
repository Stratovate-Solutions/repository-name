# PSScriptAnalyzer Settings for GitHub Branch Protection Policy Project
@{
    # Severity level filtering
    Severity = @('Error', 'Warning')
    
    # Exclude certain rules that are not appropriate for this project
    ExcludeRules = @(
        # Allow Write-Host in example scripts and user-facing scripts
        'PSAvoidUsingWriteHost',
        
        # Allow trailing whitespace (formatting preference)
        'PSAvoidTrailingWhitespace',
        
        # Allow plural nouns for functions that operate on collections
        'PSUseSingularNouns',
        
        # Allow approved verbs that are contextually appropriate
        'PSUseApprovedVerbs'
    )
    
    # Include only the most important rules for this project
    IncludeRules = @(
        # Security rules (critical)
        'PSAvoidUsingConvertToSecureStringWithPlainText',
        'PSAvoidUsingPlainTextForPassword',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingComputerNameHardcoded',
        'PSAvoidGlobalVars',
        
        # Best practices (important)
        'PSAvoidDefaultValueForMandatoryParameter',
        'PSAvoidUsingEmptyCatchBlock',
        'PSAvoidUsingPositionalParameters',
        'PSProvideCommentHelp',
        'PSUseCmdletCorrectly',
        'PSUsePSCredentialType',
        
        # Code quality
        'PSPossibleIncorrectComparisonWithNull',
        'PSReservedCmdletChar',
        'PSReservedParams',
        'PSUseDeclaredVarsMoreThanAssignments'
    )
    
    # Custom rule settings
    Rules = @{
        PSProvideCommentHelp = @{
            Enable = $true
            ExportedOnly = $false
            BlockComment = $true
            VSCodeSnippetCorrection = $false
            Placement = "before"
        }
        
        PSUseConsistentIndentation = @{
            Enable = $true
            Kind = 'space'
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            IndentationSize = 4
        }
        
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckPipeForRedundantWhitespace = $false
            CheckSeparator = $true
            CheckParameter = $false
        }
    }
}
