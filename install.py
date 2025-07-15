#!/usr/bin/env python3
"""
Cross-platform Rust Development Tools Installer
Automatically detects the shell/OS and runs the appropriate installer script
"""

import os
import sys
import platform
import subprocess
import shutil
from pathlib import Path

def detect_shell():
    """Detect the current shell and operating system"""
    system = platform.system().lower()
    
    if system == "windows":
        # On Windows, check if we're in PowerShell or CMD
        if "PSModulePath" in os.environ:
            return "powershell"
        else:
            return "cmd"
    else:
        # On Unix-like systems, check the SHELL environment variable
        shell = os.environ.get("SHELL", "").lower()
        if "bash" in shell:
            return "bash"
        elif "zsh" in shell:
            return "zsh"
        elif "fish" in shell:
            return "fish"
        else:
            # Default to bash for Unix-like systems
            return "bash"

def check_rust_installed():
    """Check if Rust is installed"""
    try:
        subprocess.run(["rustc", "--version"], 
                      stdout=subprocess.DEVNULL, 
                      stderr=subprocess.DEVNULL, 
                      check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

def get_script_directory():
    """Get the directory where this script is located"""
    return Path(__file__).parent.absolute()

def run_installer(shell, args):
    """Run the appropriate installer based on the detected shell"""
    script_dir = get_script_directory()
    
    if shell in ["powershell", "cmd"]:
        # Windows - use PowerShell script
        ps_script = script_dir / "install.ps1"
        if not ps_script.exists():
            print("Error: install.ps1 not found in the same directory")
            return 1
        
        # Build PowerShell command
        ps_command = ["powershell", "-ExecutionPolicy", "Bypass", "-File", str(ps_script)]
        ps_command.extend(args)
        
        return subprocess.call(ps_command)
    else:
        # Unix-like systems - use bash script
        bash_script = script_dir / "install.sh"
        if not bash_script.exists():
            print("Error: install.sh not found in the same directory")
            return 1
        
        # Make sure the script is executable
        os.chmod(bash_script, 0o755)
        
        # Build bash command
        bash_command = ["bash", str(bash_script)]
        bash_command.extend(args)
        
        return subprocess.call(bash_command)

def main():
    """Main entry point"""
    # Get command line arguments (excluding script name)
    args = sys.argv[1:]
    
    # Show help if requested
    if "--help" in args or "-h" in args:
        print("Rust Development Tools Installer - Cross-Platform Wrapper")
        print("=========================================================")
        print()
        print("This script automatically detects your shell/OS and runs")
        print("the appropriate installer (PowerShell or Bash)")
        print()
        print("Usage: python install.py [options]")
        print("Options:")
        print("  --all            Install all tools without prompting")
        print("  --help, -h       Show this help message")
        print()
        print("Detected environment:")
        shell = detect_shell()
        print(f"  OS: {platform.system()}")
        print(f"  Shell: {shell}")
        print(f"  Rust installed: {'Yes' if check_rust_installed() else 'No'}")
        return 0
    
    # Quick Rust check
    if not check_rust_installed():
        print("Error: Rust is not installed!")
        print("Please install Rust first: https://rustup.rs")
        if platform.system() == "Windows":
            print("For Windows: https://win.rustup.rs")
        else:
            print("Run: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh")
        return 1
    
    # Detect shell and run appropriate installer
    shell = detect_shell()
    return run_installer(shell, args)

if __name__ == "__main__":
    sys.exit(main())