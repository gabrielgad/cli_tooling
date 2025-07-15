# Rust Development Tools Installer - PowerShell Version
# This script installs selected Rust-based development tools with emoji support detection

# Enable strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Check for emoji support
param(
    [switch]$NoEmoji
)

# Set emoji variables
if ($NoEmoji) {
    $global:RustEmoji = "[RUST]"
    $global:SuccessEmoji = "[OK]"
    $global:ErrorEmoji = "[ERROR]"
    $global:WarningEmoji = "[WARN]"
    $global:InfoEmoji = "[INFO]"
    $global:ToolEmoji = "[TOOL]"
} else {
    $global:RustEmoji = "🦀"
    $global:SuccessEmoji = "✅"
    $global:ErrorEmoji = "❌"
    $global:WarningEmoji = "⚠️"
    $global:InfoEmoji = "ℹ️"
    $global:ToolEmoji = "🔧"
}

# Color functions
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] " -ForegroundColor Blue -NoNewline
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Header {
    param([string]$Title)
    Write-Host "`n" -NoNewline
    Write-Host "=== $Title ===" -ForegroundColor Cyan -BackgroundColor Black
    Write-Host ""
}

# Function to check if a command exists
function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

# Function to check Rust installation
function Test-RustInstallation {
    Write-Header "Checking Rust Installation"
    
    if (-not (Test-CommandExists "rustc")) {
        Write-Error "Rust is not installed!"
        Write-Host "Please install Rust first by visiting: https://rustup.rs"
        Write-Host "For Windows, download and run: https://win.rustup.rs"
        exit 1
    }
    
    if (-not (Test-CommandExists "cargo")) {
        Write-Error "Cargo is not found in PATH!"
        Write-Host "Please ensure Rust is properly installed and cargo is in your PATH"
        exit 1
    }
    
    $rustVersion = rustc --version
    $cargoVersion = cargo --version
    
    Write-Success "Rust is installed!"
    Write-Host "  $rustVersion"
    Write-Host "  $cargoVersion"
}

# Function to install a cargo package
function Install-Tool {
    param(
        [string]$ToolName,
        [string]$PackageName = $ToolName,
        [string]$CommandName = $ToolName
    )
    
    if (Test-CommandExists $CommandName) {
        Write-Warning "$ToolName is already installed. Skipping..."
        return $true
    }
    else {
        Write-Status "Installing $ToolName..."
        try {
            $output = cargo install $PackageName 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "$ToolName installed successfully!"
                return $true
            }
            else {
                Write-Error "Failed to install $ToolName"
                Write-Host $output
                return $false
            }
        }
        catch {
            Write-Error "Failed to install $ToolName`: $_"
            return $false
        }
    }
}

# Tool definitions
$Tools = @{
    "exa" = @{
        Package = "exa"
        Command = "exa"
        Description = "Modern replacement for 'ls' with colors and git integration"
    }
    "bat" = @{
        Package = "bat"
        Command = "bat"
        Description = "A cat clone with syntax highlighting and git integration"
    }
    "zellij" = @{
        Package = "zellij"
        Command = "zellij"
        Description = "Terminal workspace multiplexer (like tmux but friendlier)"
    }
    "mprocs" = @{
        Package = "mprocs"
        Command = "mprocs"
        Description = "Run multiple processes in parallel with TUI"
    }
    "ripgrep" = @{
        Package = "ripgrep"
        Command = "rg"
        Description = "Blazingly fast recursive grep"
    }
    "bacon" = @{
        Package = "bacon"
        Command = "bacon"
        Description = "Background Rust code checker"
    }
    "cargo-info" = @{
        Package = "cargo-info"
        Command = "cargo-info"
        Description = "Display crate information from crates.io"
    }
    "speedtest-rs" = @{
        Package = "speedtest-rs"
        Command = "speedtest-rs"
        Description = "Command-line internet speed test"
    }
    "rtx-cli" = @{
        Package = "rtx-cli"
        Command = "rtx"
        Description = "Polyglot runtime version manager (like asdf)"
    }
    "nushell" = @{
        Package = "nu"
        Command = "nu"
        Description = "A new type of shell with structured data"
    }
}

# Tool order for display
$ToolOrder = @("exa", "bat", "zellij", "mprocs", "ripgrep", "bacon", "cargo-info", "speedtest-rs", "rtx-cli", "nushell")

# Function to display tool selection menu
function Show-SelectionMenu {
    Write-Header "Tool Selection"
    Write-Host "Select which tools you want to install:"
    Write-Host ""
    
    # Create selection hashtable with all tools selected by default
    $selections = @{}
    foreach ($tool in $ToolOrder) {
        $selections[$tool] = $true
    }
    
    # Display all tools
    Write-Host "Available tools (all selected by default):"
    Write-Host ""
    
    foreach ($tool in $ToolOrder) {
        $info = $Tools[$tool]
        if ($selections[$tool]) {
            Write-Host "[x] " -ForegroundColor Green -NoNewline
        }
        else {
            Write-Host "[ ] " -ForegroundColor Red -NoNewline
        }
        Write-Host "$tool - $($info.Description)"
    }
    
    Write-Host ""
    $response = Read-Host "Install all selected tools? [Y/n]"
    
    if ($response -match '^[Nn]$') {
        # Manual selection
        $selected = @()
        foreach ($tool in $ToolOrder) {
            $info = $Tools[$tool]
            Write-Host ""
            Write-Host $tool -ForegroundColor White -BackgroundColor DarkGray -NoNewline
            Write-Host " - $($info.Description)"
            $toolResponse = Read-Host "Install $tool`? [Y/n]"
            
            if ($toolResponse -notmatch '^[Nn]$') {
                $selected += $tool
            }
        }
        return $selected
    }
    else {
        # Install all
        return $ToolOrder
    }
}

# Function to install selected tools
function Install-SelectedTools {
    param([string[]]$SelectedTools)
    
    if ($SelectedTools.Count -eq 0) {
        Write-Warning "No tools selected for installation."
        return
    }
    
    Write-Header "Installing Selected Tools"
    Write-Host "Installing $($SelectedTools.Count) tools..."
    Write-Host ""
    
    $installedCount = 0
    $failedCount = 0
    
    foreach ($tool in $SelectedTools) {
        $info = $Tools[$tool]
        $result = Install-Tool -ToolName $tool -PackageName $info.Package -CommandName $info.Command
        
        if ($result) {
            $installedCount++
        }
        else {
            $failedCount++
        }
        Write-Host ""
    }
    
    Write-Header "Installation Summary"
    Write-Success "Successfully installed: $installedCount tools"
    if ($failedCount -gt 0) {
        Write-Error "Failed to install: $failedCount tools"
    }
}

# Function to show usage tips
function Show-UsageTips {
    param([string[]]$SelectedTools)
    
    Write-Header "Quick Usage Tips"
    
    foreach ($tool in $SelectedTools) {
        switch ($tool) {
            "exa" {
                Write-Host "  • exa -la          : List all files with details"
                Write-Host "  • exa --tree       : Show directory tree"
            }
            "bat" {
                Write-Host "  • bat <file>       : View file with syntax highlighting"
                Write-Host "  • bat -n <file>    : Show line numbers"
            }
            "ripgrep" {
                Write-Host "  • rg <pattern>     : Search for pattern recursively"
                Write-Host "  • rg -i <pattern>  : Case-insensitive search"
            }
            "zellij" {
                Write-Host "  • zellij           : Start new session"
                Write-Host "  • zellij attach    : Attach to existing session"
            }
            "mprocs" {
                Write-Host "  • mprocs <cmd1> <cmd2> : Run multiple commands"
            }
            "bacon" {
                Write-Host "  • bacon            : Start watching for errors"
                Write-Host "  • bacon test       : Run tests continuously"
            }
            "cargo-info" {
                Write-Host "  • cargo info <crate> : Show crate information"
            }
            "speedtest-rs" {
                Write-Host "  • speedtest-rs     : Run internet speed test"
            }
            "rtx-cli" {
                Write-Host "  • rtx install rust : Install Rust version"
                Write-Host "  • rtx use rust@1.75 : Use specific Rust version"
            }
            "nushell" {
                Write-Host "  • nu               : Start Nushell interactive session"
                Write-Host "  • nu script.nu     : Run Nushell script"
            }
        }
    }
}

# Main execution
function Main {
    param([string[]]$Args)
    
    Clear-Host
    Write-Host "╦═╗╦ ╦╔═╗╔╦╗  ╔╦╗╔═╗╦  ╦  ╔╦╗╔═╗╔═╗╦  ╔═╗" -ForegroundColor Cyan
    Write-Host "╠╦╝║ ║╚═╗ ║    ║║║╣ ╚╗╔╝   ║ ║ ║║ ║║  ╚═╗" -ForegroundColor Cyan
    Write-Host "╩╚═╚═╝╚═╝ ╩   ═╩╝╚═╝ ╚╝    ╩ ╚═╝╚═╝╩═╝╚═╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Rust Development Tools Installer v1.0"
    Write-Host "======================================"
    Write-Host ""
    
    # Check for command line arguments
    if ($Args -contains "--help" -or $Args -contains "-h") {
        Write-Host "Usage: .\install.ps1 [options]"
        Write-Host "Options:"
        Write-Host "  --all            Install all tools without prompting"
        Write-Host "  --help, -h       Show this help message"
        exit 0
    }
    
    # Check Rust installation
    Test-RustInstallation
    
    # Handle --all flag
    if ($Args -contains "--all") {
        Write-Status "Installing all tools..."
        $selectedTools = $ToolOrder
    }
    else {
        # Show selection menu
        $selectedTools = Show-SelectionMenu
    }
    
    # Install selected tools
    Install-SelectedTools -SelectedTools $selectedTools
    
    # Show usage tips
    if ($selectedTools.Count -gt 0) {
        Show-UsageTips -SelectedTools $selectedTools
    }
    
    Write-Host ""
    Write-Success "Setup complete! Happy coding with Rust! $global:RustEmoji"
}

# Run main function
Main -Args $args