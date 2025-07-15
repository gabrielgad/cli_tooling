#!/bin/bash

# Rust Development Tools Installer - Bash Version
# This script installs selected Rust-based development tools

set -e  # Exit on error

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
        if cargo install "$package_name"; then
            print_success "$tool_name installed successfully!"
            return 0
        else
            print_error "Failed to install $tool_name"
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
    ["rtx-cli"]="rtx-cli|rtx|Polyglot runtime version manager (like asdf)"
)

# Array to store selected tools
declare -a SELECTED_TOOLS=()

# Function to display tool selection menu
show_selection_menu() {
    print_header "Tool Selection"
    echo "Select which tools you want to install:"
    echo "(Use arrow keys to navigate, space to select/deselect, enter to confirm)"
    echo
    
    # For simple bash compatibility, we'll use a different approach
    local tools_array=("exa" "bat" "zellij" "mprocs" "ripgrep" "bacon" "cargo-info" "speedtest-rs" "rtx-cli")
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
        
        if install_tool "$tool" "$package_name" "$command_name"; then
            ((installed_count++))
        else
            ((failed_count++))
        fi
        echo
    done
    
    print_header "Installation Summary"
    print_success "Successfully installed: $installed_count tools"
    if [ $failed_count -gt 0 ]; then
        print_error "Failed to install: $failed_count tools"
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
            "rtx-cli")
                echo "  • rtx install rust : Install Rust version"
                echo "  • rtx use rust@1.75 : Use specific Rust version"
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
    if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --all            Install all tools without prompting"
        echo "  --help, -h       Show this help message"
        exit 0
    fi
    
    # Check Rust installation
    check_rust_installation
    
    # Handle --all flag
    if [ "$1" == "--all" ]; then
        print_status "Installing all tools..."
        SELECTED_TOOLS=("exa" "bat" "zellij" "mprocs" "ripgrep" "bacon" "cargo-info" "speedtest-rs" "rtx-cli")
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
    print_success "Setup complete! Happy coding with Rust! 🦀"
}

# Run main function
main "$@"