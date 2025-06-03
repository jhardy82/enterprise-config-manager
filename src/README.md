# Enterprise Configuration Manager

**Universal Configuration Management for Enterprise PowerShell Applications**

A comprehensive, enterprise-grade configuration management framework that handles multiple configuration formats with advanced features like hierarchical overrides, schema validation, environment variable expansion, and audit trails.

## 🎯 Overview

The Enterprise Configuration Manager provides a unified approach to configuration management across PowerShell applications, supporting JSON, TOML, YAML, and INI formats with enterprise security and compliance features.

### Key Features

- **Multi-Format Support**: JSON, TOML, YAML, INI configuration files
- **Hierarchical Overrides**: System → User → Project → Runtime configuration layers
- **Environment Variable Expansion**: Dynamic configuration with fallback patterns
- **Schema Validation**: Enforce data types and required properties
- **Audit Trail**: Complete configuration access and modification logging
- **Cross-Platform**: Windows, Linux, macOS compatible
- **PowerShell 5.1+**: Backward compatibility maintained
- **Enterprise Security**: Secure credential integration and compliance logging

## 🚀 Quick Start

### Installation

```powershell
# Clone the repository
git clone https://github.com/your-org/enterprise-config-manager
cd enterprise-config-manager

# Import the module
Import-Module .\src\core\EnterpriseConfigManager.psm1
```

### Basic Usage

```powershell
# Load configuration
$config = Import-EnterpriseConfiguration -ConfigPath ".\config\app.json"

# Use Get-OrElse pattern for safe access
$databaseUrl = Get-OrElse -Value $config.Database.Url -Default "localhost"
$timeout = Get-OrElse -Value $config.Database.Timeout -Default 30

# Validate configuration
$results = Test-EnterpriseConfiguration -ConfigPath ".\config\app.json"
if (-not $results.IsValid) {
    Write-Error "Configuration validation failed"
}
```

### CLI Interface

```powershell
# Interactive mode
.\Invoke-EnterpriseConfigManager.ps1 -Action Interactive

# Load and display configuration
.\Invoke-EnterpriseConfigManager.ps1 -Action Load -ConfigPath ".\app.json"

# Convert between formats
.\Invoke-EnterpriseConfigManager.ps1 -Action Convert -ConfigPath ".\app.json" -OutputPath ".\app.toml" -Format TOML

# Validate configuration
.\Invoke-EnterpriseConfigManager.ps1 -Action Validate -ConfigPath ".\app.json"

# Run comprehensive tests
.\Invoke-EnterpriseConfigManager.ps1 -Action Test -ConfigPath ".\app.json"

# View audit trail
.\Invoke-EnterpriseConfigManager.ps1 -Action Audit
```

## 📋 Configuration Formats

### JSON Configuration
```json
{
  "Application": {
    "Name": "MyApp",
    "Version": "1.0.0",
    "Environment": "${ENV_TYPE}"
  },
  "Database": {
    "ConnectionString": "Server=localhost;Database=MyDb",
    "Timeout": 30,
    "EnableLogging": true
  }
}
```

### TOML Configuration
```toml
[Application]
Name = "MyApp"
Version = "1.0.0"
Environment = "${ENV_TYPE}"

[Database]
ConnectionString = "Server=localhost;Database=MyDb"
Timeout = 30
EnableLogging = true
```

### YAML Configuration
```yaml
Application:
  Name: MyApp
  Version: 1.0.0
  Environment: ${ENV_TYPE}
Database:
  ConnectionString: Server=localhost;Database=MyDb
  Timeout: 30
  EnableLogging: true
```

## 🏗️ Advanced Features

### Hierarchical Configuration

```powershell
# Load with override hierarchy
$config = Import-EnterpriseConfiguration `
    -ConfigPath ".\base-config.json" `
    -OverridePaths @(".\env-config.json", ".\user-config.json") `
    -ExpandEnvironmentVariables
```

### Schema Validation

```powershell
# Create configuration schema
$schema = New-ConfigurationSchema
$schema.AddProperty("DatabaseUrl", [string], $true)
$schema.AddProperty("Timeout", [int], $false)
$schema.AddValidator("DatabaseUrl", { param($value) $value -match "^https?://" })

# Create manager with schema
$manager = New-ConfigurationManager -ConfigPath ".\app.json" -Schema $schema
$config = $manager.LoadConfiguration()
```

### Environment Variable Expansion

```powershell
# Configuration with environment variables
$config = @{
    DatabaseUrl = "${DATABASE_URL}"
    LogLevel = "${LOG_LEVEL:-INFO}"  # With fallback
    TempPath = "%TEMP%\myapp"        # Windows-style
}

# Expand environment variables
$expanded = Import-EnterpriseConfiguration -ConfigPath ".\app.json" -ExpandEnvironmentVariables
```

### Get-OrElse Pattern

```powershell
# Safe configuration access with fallbacks
$databaseUrl = Get-OrElse -Value $config.Database.Url -Default "localhost"
$retryCount = Get-OrElse -Value $config.Retry.Count -Default 3
$enableFeature = Get-OrElse -Value $config.Features.NewFeature -Default $false

# Complex fallback chains
$logPath = Get-OrElse -Value $config.Logging.Path -Default (
    Get-OrElse -Value $env:LOG_PATH -Default "C:\Logs\app.log"
)
```

## 🔧 API Reference

### Core Functions

#### Import-EnterpriseConfiguration
Loads configuration with hierarchical override support.

```powershell
Import-EnterpriseConfiguration 
    -ConfigPath <string>
    [-OverridePaths <string[]>] 
    [-ExpandEnvironmentVariables] 
    [-ValidateSchema]
```

#### Export-EnterpriseConfiguration
Exports configuration to specified format.

```powershell
Export-EnterpriseConfiguration 
    -Configuration <hashtable>
    -OutputPath <string>
    [-Format <string>] 
    [-Indent]
```

#### Test-EnterpriseConfiguration
Validates configuration file and schema compliance.

```powershell
Test-EnterpriseConfiguration 
    -ConfigPath <string>
    [-Schema <ConfigurationSchema>] 
    [-TestEnvironmentExpansion]
```

#### Get-OrElse
Provides fallback value pattern for safe configuration access.

```powershell
Get-OrElse 
    -Value <object>
    -Default <object>
```

### Configuration Manager Class

```powershell
# Create configuration manager
$manager = New-ConfigurationManager -ConfigPath ".\app.json"

# Add search paths for overrides
$manager.AddSearchPath(".\config-overrides")

# Load configuration
$config = $manager.LoadConfiguration()

# Get specific values
$value = $manager.GetConfigValue("Database.Timeout", 30)
```

## 🔐 Security Features

### Secure Credential Management
- Integration with PowerShell SecretManagement
- No plain-text credentials in configuration files
- Environment variable expansion for sensitive data

### Audit Trail
- Complete configuration access logging
- Modification tracking
- Compliance reporting

### Schema Enforcement
- Data type validation
- Required property enforcement
- Custom validation rules

## 🧪 Testing

### Running Tests
```powershell
# Run all tests
Invoke-Pester -Path .\tests\

# Run specific test category
Invoke-Pester -Path .\tests\ -Tag "Unit"
Invoke-Pester -Path .\tests\ -Tag "Integration"
```

### Test Categories
- **Unit Tests**: Core functionality and edge cases
- **Integration Tests**: Multi-format configuration loading
- **Security Tests**: Credential handling and validation
- **Performance Tests**: Large configuration file handling

## 📦 Use Cases

### Enterprise Application Configuration
```powershell
# Load environment-specific configuration
$env:ENVIRONMENT = "Production"
$config = Import-EnterpriseConfiguration `
    -ConfigPath ".\base-config.json" `
    -OverridePaths @(".\prod-config.json") `
    -ExpandEnvironmentVariables

# Use throughout application
$connectionString = Get-OrElse -Value $config.Database.Primary -Default $config.Database.Fallback
```

### Multi-Environment Deployment
```powershell
# Development environment
$devConfig = Import-EnterpriseConfiguration -ConfigPath ".\config\dev.json"

# Production environment with overrides
$prodConfig = Import-EnterpriseConfiguration `
    -ConfigPath ".\config\base.json" `
    -OverridePaths @(".\config\prod-overrides.json", ".\config\secrets.json")
```

### Configuration Migration
```powershell
# Convert legacy INI to modern JSON
.\Invoke-EnterpriseConfigManager.ps1 `
    -Action Convert `
    -ConfigPath ".\legacy-config.ini" `
    -OutputPath ".\modern-config.json" `
    -Format JSON -Indent
```

## 🛠️ Development

### Contributing
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

### Code Standards
- PowerShell 5.1+ compatibility
- Comprehensive error handling
- Verbose logging support
- Cross-platform compatibility

### Architecture
```
src/
├── core/
│   └── EnterpriseConfigManager.psm1    # Main module
├── tests/
│   ├── Unit/                           # Unit tests
│   ├── Integration/                    # Integration tests
│   └── TestHelpers/                    # Test utilities
├── examples/                           # Usage examples
└── docs/                              # Documentation
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Support

- **Issues**: GitHub Issues for bug reports and feature requests
- **Discussions**: GitHub Discussions for questions and community support
- **Enterprise Support**: Contact your organization's IT team

---

**Enterprise Configuration Manager** - Making configuration management simple, secure, and scalable for enterprise PowerShell applications.
