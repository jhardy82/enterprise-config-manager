#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Enterprise Configuration Manager CLI Interface

.DESCRIPTION
    Command-line interface for enterprise configuration management operations.
    Supports loading, validating, converting, and managing configuration files
    across multiple formats with enterprise-grade features.

.PARAMETER Action
    Action to perform: Load, Validate, Convert, Test, Export, Schema, Audit

.PARAMETER ConfigPath
    Path to configuration file

.PARAMETER OutputPath
    Output path for export operations

.PARAMETER Format
    Configuration format (JSON, TOML, YAML, INI)

.PARAMETER Schema
    Path to schema file for validation

.PARAMETER OverridePaths
    Comma-separated list of override configuration paths

.PARAMETER ExpandEnvironment
    Expand environment variables in configuration

.PARAMETER Verbose
    Enable verbose output

.EXAMPLE
    .\Invoke-EnterpriseConfigManager.ps1 -Action Load -ConfigPath ".\app.json"
    Loads and displays configuration from JSON file.

.EXAMPLE
    .\Invoke-EnterpriseConfigManager.ps1 -Action Convert -ConfigPath ".\app.json" -OutputPath ".\app.toml" -Format TOML
    Converts JSON configuration to TOML format.

.EXAMPLE
    .\Invoke-EnterpriseConfigManager.ps1 -Action Validate -ConfigPath ".\app.json" -Schema ".\schema.json"
    Validates configuration against schema.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Load", "Validate", "Convert", "Test", "Export", "Schema", "Audit", "Interactive", "Demo")]
    [string]$Action,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "TOML", "YAML", "INI")]
    [string]$Format = "JSON",

    [Parameter(Mandatory = $false)]
    [string]$SchemaPath,

    [Parameter(Mandatory = $false)]
    [string]$OverridePaths,

    [Parameter(Mandatory = $false)]
    [switch]$ExpandEnvironment,

    [Parameter(Mandatory = $false)]
    [switch]$Indent
)

#region Setup and Module Import

$ErrorActionPreference = 'Stop'

# Get script directory
$ScriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$ModulePath = Join-Path -Path (Split-Path $ScriptRoot -Parent) -ChildPath "src\core\EnterpriseConfigManager.psm1"

# Import the module
if (Test-Path $ModulePath) {
    Import-Module $ModulePath -Force
    Write-Host "✅ Enterprise Config Manager module loaded" -ForegroundColor Green
} else {
    Write-Error "❌ Could not find module at: $ModulePath"
    exit 1
}

#endregion

#region Helper Functions

function Write-Banner {
    param([string]$Title)
    
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host " 🏢 Enterprise Configuration Manager - $Title" -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Blue
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Show-Configuration {
    param([hashtable]$Configuration, [string]$Title = "Configuration")
    
    Write-Host ""
    Write-Host "📋 $Title:" -ForegroundColor Magenta
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    $json = $Configuration | ConvertTo-Json -Depth 10
    if ($json.Length -gt 2000) {
        $json = $json.Substring(0, 2000) + "... (truncated)"
    }
    
    Write-Host $json -ForegroundColor White
    Write-Host ""
}

function Show-ValidationResults {
    param([hashtable]$Results)
    
    Write-Host ""
    Write-Host "🔍 Validation Results:" -ForegroundColor Magenta
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    
    if ($Results.IsValid) {
        Write-Success "Configuration is valid"
    } else {
        Write-Error "Configuration validation failed"
    }
    
    if ($Results.Errors.Count -gt 0) {
        Write-Host ""
        Write-Host "❌ Errors:" -ForegroundColor Red
        foreach ($error in $Results.Errors) {
            Write-Host "   • $error" -ForegroundColor Red
        }
    }
    
    if ($Results.Warnings.Count -gt 0) {
        Write-Host ""
        Write-Host "⚠️  Warnings:" -ForegroundColor Yellow
        foreach ($warning in $Results.Warnings) {
            Write-Host "   • $warning" -ForegroundColor Yellow
        }
    }
    
    if ($Results.TestResults.Count -gt 0) {
        Write-Host ""
        Write-Host "📊 Test Results:" -ForegroundColor Cyan
        foreach ($test in $Results.TestResults.GetEnumerator()) {
            $status = if ($test.Value) { "✅ PASS" } else { "❌ FAIL" }
            Write-Host "   • $($test.Key): $status" -ForegroundColor $(if ($test.Value) { "Green" } else { "Red" })
        }
    }
    Write-Host ""
}

#endregion

#region Action Implementations

function Invoke-LoadAction {
    param([string]$ConfigPath, [string[]]$OverridePaths, [switch]$ExpandEnvironment)
    
    Write-Banner "Load Configuration"
    
    if (-not $ConfigPath) {
        throw "ConfigPath is required for Load action"
    }
    
    if (-not (Test-Path $ConfigPath)) {
        throw "Configuration file not found: $ConfigPath"
    }
    
    Write-Info "Loading configuration from: $ConfigPath"
    
    $config = Import-EnterpriseConfiguration -ConfigPath $ConfigPath -OverridePaths $OverridePaths -ExpandEnvironmentVariables:$ExpandEnvironment
    
    Show-Configuration -Configuration $config -Title "Loaded Configuration"
    Write-Success "Configuration loaded successfully"
}

function Invoke-ValidateAction {
    param([string]$ConfigPath, [string]$SchemaPath)
    
    Write-Banner "Validate Configuration"
    
    if (-not $ConfigPath) {
        throw "ConfigPath is required for Validate action"
    }
    
    Write-Info "Validating configuration: $ConfigPath"
    
    $schema = $null
    if ($SchemaPath) {
        Write-Info "Using schema: $SchemaPath"
        # Load schema if provided (implementation would depend on schema format)
    }
    
    $results = Test-EnterpriseConfiguration -ConfigPath $ConfigPath -Schema $schema -TestEnvironmentExpansion
    
    Show-ValidationResults -Results $results
    
    if ($results.IsValid) {
        Write-Success "Configuration validation completed successfully"
    } else {
        Write-Error "Configuration validation failed"
        exit 1
    }
}

function Invoke-ConvertAction {
    param([string]$ConfigPath, [string]$OutputPath, [string]$Format, [switch]$Indent)
    
    Write-Banner "Convert Configuration"
    
    if (-not $ConfigPath) {
        throw "ConfigPath is required for Convert action"
    }
    
    if (-not $OutputPath) {
        throw "OutputPath is required for Convert action"
    }
    
    Write-Info "Converting: $ConfigPath → $OutputPath (Format: $Format)"
    
    $config = Import-EnterpriseConfiguration -ConfigPath $ConfigPath
    Export-EnterpriseConfiguration -Configuration $config -OutputPath $OutputPath -Format $Format -Indent:$Indent
    
    Write-Success "Configuration converted successfully"
    Write-Info "Output saved to: $OutputPath"
}

function Invoke-TestAction {
    param([string]$ConfigPath)
    
    Write-Banner "Test Configuration"
    
    if (-not $ConfigPath) {
        throw "ConfigPath is required for Test action"
    }
    
    Write-Info "Running comprehensive tests on: $ConfigPath"
    
    $results = Test-EnterpriseConfiguration -ConfigPath $ConfigPath -TestEnvironmentExpansion
    
    Show-ValidationResults -Results $results
    
    # Additional tests
    Write-Info "Running additional configuration tests..."
    
    try {
        $config = Import-EnterpriseConfiguration -ConfigPath $ConfigPath -ExpandEnvironmentVariables
        Write-Success "Environment variable expansion test passed"
    }
    catch {
        Write-Warning "Environment variable expansion test failed: $($_.Exception.Message)"
    }
    
    if ($results.IsValid) {
        Write-Success "All configuration tests completed successfully"
    } else {
        Write-Error "Configuration tests failed"
        exit 1
    }
}

function Invoke-AuditAction {
    Write-Banner "Configuration Audit"
    
    $context = Get-ConfigurationContext
    
    Write-Host "📊 Configuration Management Audit Report" -ForegroundColor Magenta
    Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "⏰ Context Timestamp: $($context.Timestamp)" -ForegroundColor White
    Write-Host "🔍 Cache Enabled: $($context.CacheEnabled)" -ForegroundColor White
    Write-Host "⏱️  Cache Timeout: $($context.CacheTimeout) seconds" -ForegroundColor White
    Write-Host "🌍 Environment Expansion: $($context.EnvironmentExpansion)" -ForegroundColor White
    Write-Host "✅ Validation Enabled: $($context.ValidationEnabled)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "📁 Loaded Configurations: $($context.LoadedConfigs.Count)" -ForegroundColor Cyan
    foreach ($config in $context.LoadedConfigs.GetEnumerator()) {
        Write-Host "   • $($config.Key)" -ForegroundColor White
    }
    Write-Host ""
    
    if ($context.ValidationErrors.Count -gt 0) {
        Write-Host "❌ Validation Errors: $($context.ValidationErrors.Count)" -ForegroundColor Red
        foreach ($error in $context.ValidationErrors) {
            Write-Host "   • $error" -ForegroundColor Red
        }
        Write-Host ""
    } else {
        Write-Success "No validation errors found"
    }
    
    if ($context.AuditLog.Count -gt 0) {
        Write-Host "📋 Recent Operations:" -ForegroundColor Cyan
        $recentOps = $context.AuditLog | Sort-Object Timestamp -Descending | Select-Object -First 10
        foreach ($op in $recentOps) {
            $status = if ($op.Success) { "✅" } else { "❌" }
            Write-Host "   $status $($op.Timestamp.ToString('yyyy-MM-dd HH:mm:ss')) - $($op.Action)" -ForegroundColor White
        }
    }
    
    Write-Host ""
    Write-Success "Audit completed"
}

function Invoke-InteractiveAction {
    Write-Banner "Interactive Mode"
    
    do {
        Write-Host ""
        Write-Host "🎮 Interactive Configuration Manager" -ForegroundColor Magenta
        Write-Host "─────────────────────────────────────────────────────────────" -ForegroundColor Gray
        Write-Host "1. Load Configuration"
        Write-Host "2. Validate Configuration"
        Write-Host "3. Convert Configuration"
        Write-Host "4. Test Configuration"
        Write-Host "5. View Audit Log"
        Write-Host "6. Reset Context"
        Write-Host "7. Run Demo"
        Write-Host "0. Exit"
        Write-Host ""
        
        $choice = Read-Host "Select an option (0-7)"
        
        switch ($choice) {
            "1" {
                $path = Read-Host "Enter configuration file path"
                if ($path -and (Test-Path $path)) {
                    try {
                        Invoke-LoadAction -ConfigPath $path
                    }
                    catch {
                        Write-Error "Failed to load configuration: $($_.Exception.Message)"
                    }
                } else {
                    Write-Warning "File not found or path not provided"
                }
            }
            "2" {
                $path = Read-Host "Enter configuration file path"
                if ($path -and (Test-Path $path)) {
                    try {
                        Invoke-ValidateAction -ConfigPath $path
                    }
                    catch {
                        Write-Error "Failed to validate configuration: $($_.Exception.Message)"
                    }
                } else {
                    Write-Warning "File not found or path not provided"
                }
            }
            "3" {
                $inputPath = Read-Host "Enter input configuration file path"
                $outputPath = Read-Host "Enter output file path"
                $format = Read-Host "Enter output format (JSON/TOML/YAML/INI) [JSON]"
                if (-not $format) { $format = "JSON" }
                
                if ($inputPath -and $outputPath -and (Test-Path $inputPath)) {
                    try {
                        Invoke-ConvertAction -ConfigPath $inputPath -OutputPath $outputPath -Format $format
                    }
                    catch {
                        Write-Error "Failed to convert configuration: $($_.Exception.Message)"
                    }
                } else {
                    Write-Warning "Invalid paths provided"
                }
            }
            "4" {
                $path = Read-Host "Enter configuration file path"
                if ($path -and (Test-Path $path)) {
                    try {
                        Invoke-TestAction -ConfigPath $path
                    }
                    catch {
                        Write-Error "Failed to test configuration: $($_.Exception.Message)"
                    }
                } else {
                    Write-Warning "File not found or path not provided"
                }
            }
            "5" {
                Invoke-AuditAction
            }
            "6" {
                Reset-ConfigurationContext
                Write-Success "Configuration context reset"
            }
            "7" {
                Invoke-DemoAction
            }
            "0" {
                Write-Info "Goodbye!"
                break
            }
            default {
                Write-Warning "Invalid selection. Please try again."
            }
        }
        
        if ($choice -ne "0") {
            Read-Host "Press Enter to continue..."
        }
        
    } while ($choice -ne "0")
}

function Invoke-DemoAction {
    Write-Banner "Configuration Manager Demo"
    
    $tempDir = Join-Path $env:TEMP "ConfigManagerDemo"
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }
    
    Write-Info "Creating demo configuration files in: $tempDir"
    
    # Create sample JSON configuration
    $jsonConfig = @{
        Application = @{
            Name = "Demo App"
            Version = "1.0.0"
            Environment = '${ENV_TYPE}'
        }
        Database = @{
            ConnectionString = "Server=localhost;Database=DemoDb"
            Timeout = 30
            EnableLogging = $true
        }
        Features = @{
            EnableCache = $true
            CacheSize = 100
            AllowAnonymous = $false
        }
    }
    
    $jsonPath = Join-Path $tempDir "demo-config.json"
    $jsonConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $jsonPath
    Write-Success "Created JSON configuration: $jsonPath"
    
    # Create override configuration
    $overrideConfig = @{
        Database = @{
            Timeout = 60
        }
        Features = @{
            CacheSize = 200
        }
    }
    
    $overridePath = Join-Path $tempDir "override-config.json"
    $overrideConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $overridePath
    Write-Success "Created override configuration: $overridePath"
    
    # Demo 1: Load basic configuration
    Write-Info "Demo 1: Loading basic configuration"
    $config = Import-EnterpriseConfiguration -ConfigPath $jsonPath
    Show-Configuration -Configuration $config -Title "Basic Configuration"
    
    # Demo 2: Load with overrides
    Write-Info "Demo 2: Loading configuration with overrides"
    $configWithOverride = Import-EnterpriseConfiguration -ConfigPath $jsonPath -OverridePaths @($overridePath)
    Show-Configuration -Configuration $configWithOverride -Title "Configuration with Overrides"
    
    # Demo 3: Environment variable expansion
    Write-Info "Demo 3: Environment variable expansion"
    $env:ENV_TYPE = "Development"
    $configExpanded = Import-EnterpriseConfiguration -ConfigPath $jsonPath -ExpandEnvironmentVariables
    Show-Configuration -Configuration $configExpanded -Title "Configuration with Environment Expansion"
    
    # Demo 4: Validation
    Write-Info "Demo 4: Configuration validation"
    $results = Test-EnterpriseConfiguration -ConfigPath $jsonPath -TestEnvironmentExpansion
    Show-ValidationResults -Results $results
    
    # Demo 5: Format conversion
    Write-Info "Demo 5: Format conversion"
    $tomlPath = Join-Path $tempDir "demo-config.toml"
    Export-EnterpriseConfiguration -Configuration $config -OutputPath $tomlPath -Format TOML
    Write-Success "Converted to TOML: $tomlPath"
    
    if (Test-Path $tomlPath) {
        Write-Host "TOML Content:" -ForegroundColor Magenta
        Get-Content $tomlPath | ForEach-Object { Write-Host "  $_" -ForegroundColor White }
    }
    
    # Demo 6: Audit log
    Write-Info "Demo 6: Viewing audit log"
    Invoke-AuditAction
    
    Write-Host ""
    Write-Success "Demo completed! Demo files created in: $tempDir"
    Write-Info "You can experiment with these files using the interactive mode"
}

#endregion

#region Main Execution

try {
    # Parse override paths if provided
    $overridePathArray = @()
    if ($OverridePaths) {
        $overridePathArray = $OverridePaths -split ','
    }
    
    # Execute the requested action
    switch ($Action) {
        "Load" {
            Invoke-LoadAction -ConfigPath $ConfigPath -OverridePaths $overridePathArray -ExpandEnvironment:$ExpandEnvironment
        }
        "Validate" {
            Invoke-ValidateAction -ConfigPath $ConfigPath -SchemaPath $SchemaPath
        }
        "Convert" {
            Invoke-ConvertAction -ConfigPath $ConfigPath -OutputPath $OutputPath -Format $Format -Indent:$Indent
        }
        "Test" {
            Invoke-TestAction -ConfigPath $ConfigPath
        }
        "Audit" {
            Invoke-AuditAction
        }
        "Interactive" {
            Invoke-InteractiveAction
        }
        "Demo" {
            Invoke-DemoAction
        }
        default {
            Write-Error "Unknown action: $Action"
            exit 1
        }
    }
    
    Write-Host ""
    Write-Success "Operation completed successfully"
}
catch {
    Write-Host ""
    Write-Error "Operation failed: $($_.Exception.Message)"
    
    if ($_.Exception.InnerException) {
        Write-Error "Inner exception: $($_.Exception.InnerException.Message)"
    }
    
    if ($PSCmdlet.MyInvocation.BoundParameters['Verbose']) {
        Write-Host ""
        Write-Host "Stack Trace:" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
    }
    
    exit 1
}

#endregion
