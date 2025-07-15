#!/bin/bash

# Rust Development Tools Installer - Bash Version
# This script installs selected Rust-based development tools with emoji support detection

set -euo pipefail  # Exit on error, undefined vars, and pipe failures

# Trap to show where script exits unexpectedly
trap 'echo "Script exited at line $LINENO"' EXIT

# Detect emoji support
SUPPORTS_EMOJI="true"
if [ "${INSTALLER_EMOJI_SUPPORT:-1}" = "0" ]; then
    SUPPORTS_EMOJI="false"
fi

# Colors for output (check if terminal supports colors)
if [ -t 1 ] && [ -n "$(tput colors)" ] && [ "$(tput colors)" -ge 8 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    NC=''
fi

# Emoji and fallback versions
if [ "$SUPPORTS_EMOJI" = "true" ]; then
    RUST_EMOJI="🦀"
    SUCCESS_EMOJI="✅"
    ERROR_EMOJI="❌"
    WARNING_EMOJI="⚠️"
    INFO_EMOJI="ℹ️"
    TOOL_EMOJI="🔧"
else
    RUST_EMOJI="[RUST]"
    SUCCESS_EMOJI="[OK]"
    ERROR_EMOJI="[ERROR]"
    WARNING_EMOJI="[WARN]"
    INFO_EMOJI="[INFO]"
    TOOL_EMOJI="[TOOL]"
fi

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_header() {
    echo -e "\n${CYAN}${BOLD}=== $1 ===${NC}\n"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Rust installation
check_rust_installation() {
    print_header "Checking Rust Installation"
    
    if ! command_exists rustc; then
        print_error "Rust is not installed!"
        echo "Please install Rust first by visiting: https://rustup.rs"
        echo "Run: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        exit 1
    fi
    
    if ! command_exists cargo; then
        print_error "Cargo is not found in PATH!"
        echo "Please ensure Rust is properly installed and cargo is in your PATH"
        exit 1
    fi
    
    local rust_version=$(rustc --version)
    local cargo_version=$(cargo --version)
    
    print_success "Rust is installed!"
    echo "  $rust_version"
    echo "  $cargo_version"
}

# Function to analyze installation failure and return reason
analyze_failure() {
    local stderr_output="$1"
    
    # Check for common failure patterns
    if echo "$stderr_output" | grep -q "Could not find openssl via pkg-config"; then
        echo "Missing OpenSSL development libraries (install pkg-config and libssl-dev)"
    elif echo "$stderr_output" | grep -q "pkg-config command could not be found"; then
        echo "Missing pkg-config (install with: apt install pkg-config)"
    elif echo "$stderr_output" | grep -q "linker.*not found"; then
        echo "Missing C/C++ compiler or linker"
    elif echo "$stderr_output" | grep -q "permission denied"; then
        echo "Permission denied (check file permissions)"
    elif echo "$stderr_output" | grep -q "network.*error\|connection.*failed"; then
        echo "Network error (check internet connection)"
    elif echo "$stderr_output" | grep -q "disk.*full\|no space left"; then
        echo "Insufficient disk space"
    elif echo "$stderr_output" | grep -q "rustc.*not found"; then
        echo "Rust compiler not found in PATH"
    elif echo "$stderr_output" | grep -q "cargo.*not found"; then
        echo "Cargo not found in PATH"
    elif echo "$stderr_output" | grep -q "failed to compile"; then
        echo "Compilation failed (check build dependencies)"
    elif echo "$stderr_output" | grep -q "failed to download"; then
        echo "Download failed (check network and crates.io availability)"
    else
        echo "Unknown build error (check full output above)"
    fi
}

# Function to install a cargo package
install_tool() {
    local tool_name=$1
    local package_name=${2:-$1}  # Use second parameter if provided, otherwise use tool_name
    local command_name=${3:-$1}  # Command to check if installed
    
    if command_exists "$command_name"; then
        print_warning "$tool_name is already installed. Skipping..."
        return 0
    else
        print_status "Installing $tool_name..."
        
        # Create temporary file for stderr
        local stderr_file=$(mktemp)
        
        # Run cargo install and capture stderr
        if cargo install "$package_name" 2>"$stderr_file"; then
            print_success "$tool_name installed successfully!"
            rm -f "$stderr_file"
            return 0
        else
            # Analyze the failure
            local failure_reason=$(analyze_failure "$(cat "$stderr_file")")
            FAILED_TOOLS+=("$tool_name")
            FAILURE_REASONS+=("$failure_reason")
            
            print_error "Failed to install $tool_name"
            rm -f "$stderr_file"
            return 1
        fi
    fi
}

# Tool definitions
declare -A TOOLS=(
    ["exa"]="exa|exa|Modern replacement for 'ls' with colors and git integration"
    ["bat"]="bat|bat|A cat clone with syntax highlighting and git integration"
    ["zellij"]="zellij|zellij|Terminal workspace multiplexer (like tmux but friendlier)"
    ["mprocs"]="mprocs|mprocs|Run multiple processes in parallel with TUI"
    ["ripgrep"]="ripgrep|rg|Blazingly fast recursive grep"
    ["bacon"]="bacon|bacon|Background Rust code checker"
    ["cargo-info"]="cargo-info|cargo-info|Display crate information from crates.io"
    ["speedtest-rs"]="speedtest-rs|speedtest-rs|Command-line internet speed test"
    ["mise"]="mise|mise|Polyglot runtime version manager (like asdf, formerly rtx)"
    ["nushell"]="nu|nu|A new type of shell with structured data"
)

# Array to store selected tools
declare -a SELECTED_TOOLS=()

# Arrays to track installation results
declare -a FAILED_TOOLS=()
declare -a FAILURE_REASONS=()

# Function to display tool selection menu
show_selection_menu() {
    print_header "Tool Selection"
    echo "Select which tools you want to install:"
    echo "(Use arrow keys to navigate, space to select/deselect, enter to confirm)"
    echo
    
    # For simple bash compatibility, we'll use a different approach
    local tools_array=("exa" "bat" "zellij" "mprocs" "ripgrep" "bacon" "cargo-info" "speedtest-rs" "mise" "nushell")
    local selected=()
    
    # Initialize all as selected
    for i in "${!tools_array[@]}"; do
        selected[$i]=true
    done
    
    echo "Available tools (all selected by default):"
    echo
    
    for i in "${!tools_array[@]}"; do
        local tool="${tools_array[$i]}"
        local info="${TOOLS[$tool]}"
        IFS='|' read -r package_name command_name description <<< "$info"
        
        if [ "${selected[$i]}" = true ]; then
            echo -e "${GREEN}[x]${NC} $tool - $description"
        else
            echo -e "${RED}[ ]${NC} $tool - $description"
        fi
    done
    
    echo
    read -p "Install all selected tools? [Y/n] " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        # Manual selection
        for i in "${!tools_array[@]}"; do
            local tool="${tools_array[$i]}"
            local info="${TOOLS[$tool]}"
            IFS='|' read -r package_name command_name description <<< "$info"
            
            echo
            echo -e "${BOLD}$tool${NC} - $description"
            read -p "Install $tool? [Y/n] " -n 1 -r
            echo
            
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                SELECTED_TOOLS+=("$tool")
            fi
        done
    else
        # Install all
        SELECTED_TOOLS=("${tools_array[@]}")
    fi
}

# Function to install selected tools
install_selected_tools() {
    if [ ${#SELECTED_TOOLS[@]} -eq 0 ]; then
        print_warning "No tools selected for installation."
        return
    fi
    
    print_header "Installing Selected Tools"
    echo "Installing ${#SELECTED_TOOLS[@]} tools..."
    echo
    
    local installed_count=0
    local failed_count=0
    
    for tool in "${SELECTED_TOOLS[@]}"; do
        local info="${TOOLS[$tool]}"
        IFS='|' read -r package_name command_name description <<< "$info"
        
        print_status "Processing tool: $tool ($((installed_count + failed_count + 1)) of ${#SELECTED_TOOLS[@]})"
        
        if install_tool "$tool" "$package_name" "$command_name"; then
            ((installed_count++)) || true
        else
            ((failed_count++)) || true
        fi
        echo
    done
    
    print_header "Installation Summary"
    
    if [ $installed_count -gt 0 ]; then
        print_success "Successfully installed: $installed_count tools"
    fi
    
    if [ $failed_count -gt 0 ]; then
        print_error "Failed to install: $failed_count tools"
        echo
        echo "${BOLD}Failure Details:${NC}"
        for i in "${!FAILED_TOOLS[@]}"; do
            echo -e "  ${RED}•${NC} ${BOLD}${FAILED_TOOLS[$i]}${NC}: ${FAILURE_REASONS[$i]}"
        done
        echo
        echo "${BOLD}Common Solutions:${NC}"
        echo "  • For OpenSSL/pkg-config errors: sudo apt install pkg-config libssl-dev"
        echo "  • For compiler errors: sudo apt install build-essential"
        echo "  • For network errors: check internet connection and try again"
    fi
}

# Function to show usage tips
show_usage_tips() {
    print_header "Quick Usage Tips"
    
    for tool in "${SELECTED_TOOLS[@]}"; do
        case $tool in
            "exa")
                echo "  • exa -la          : List all files with details"
                echo "  • exa --tree       : Show directory tree"
                ;;
            "bat")
                echo "  • bat <file>       : View file with syntax highlighting"
                echo "  • bat -n <file>    : Show line numbers"
                ;;
            "ripgrep")
                echo "  • rg <pattern>     : Search for pattern recursively"
                echo "  • rg -i <pattern>  : Case-insensitive search"
                ;;
            "zellij")
                echo "  • zellij           : Start new session"
                echo "  • zellij attach    : Attach to existing session"
                ;;
            "mprocs")
                echo "  • mprocs <cmd1> <cmd2> : Run multiple commands"
                ;;
            "bacon")
                echo "  • bacon            : Start watching for errors"
                echo "  • bacon test       : Run tests continuously"
                ;;
            "cargo-info")
                echo "  • cargo info <crate> : Show crate information"
                ;;
            "speedtest-rs")
                echo "  • speedtest-rs     : Run internet speed test"
                ;;
            "mise")
                echo "  • mise install rust : Install Rust version"
                echo "  • mise use rust@1.75 : Use specific Rust version"
                ;;
            "nushell")
                echo "  • nu               : Start Nushell interactive session"
                echo "  • nu script.nu     : Run Nushell script"
                ;;
        esac
    done
}

# Main execution
main() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╦═╗╦ ╦╔═╗╔╦╗  ╔╦╗╔═╗╦  ╦  ╔╦╗╔═╗╔═╗╦  ╔═╗"
    echo "╠╦╝║ ║╚═╗ ║    ║║║╣ ╚╗╔╝   ║ ║ ║║ ║║  ╚═╗"
    echo "╩╚═╚═╝╚═╝ ╩   ═╩╝╚═╝ ╚╝    ╩ ╚═╝╚═╝╩═╝╚═╝"
    echo -e "${NC}"
    echo "Rust Development Tools Installer v1.0"
    echo "======================================"
    echo
    
    # Check for command line arguments
    if [ "${1:-}" == "--help" ] || [ "${1:-}" == "-h" ]; then
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --all            Install all tools without prompting"
        echo "  --help, -h       Show this help message"
        exit 0
    fi
    
    # Check Rust installation
    check_rust_installation
    
    # Handle --all flag
    if [ "${1:-}" == "--all" ]; then
        print_status "Installing all tools..."
        SELECTED_TOOLS=("exa" "bat" "zellij" "mprocs" "ripgrep" "bacon" "cargo-info" "speedtest-rs" "mise" "nushell")
    else
        # Show selection menu
        show_selection_menu
    fi
    
    # Install selected tools
    install_selected_tools
    
    # Show usage tips
    if [ ${#SELECTED_TOOLS[@]} -gt 0 ]; then
        show_usage_tips
    fi
    
    echo
    print_success "Setup complete! Happy coding with Rust! $RUST_EMOJI"
    
    # Remove the exit trap since we're exiting normally
    trap - EXIT
}

# Run main function
main "$@"
exit 0