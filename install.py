#!/usr/bin/env python3
"""
Universal Rust Development Tools Installer
Handles complex environments including WSL, MinGW, Git Bash, and various terminal emulators
"""

import os
import sys
import platform
import subprocess
import shutil
import locale
import re
from pathlib import Path

class EnvironmentDetector:
    """Comprehensive environment detection for cross-platform compatibility"""
    
    def __init__(self):
        self.os_type = platform.system().lower()
        self.is_wsl = self._detect_wsl()
        self.is_mingw = self._detect_mingw()
        self.is_cygwin = self._detect_cygwin()
        self.is_git_bash = self._detect_git_bash()
        self.terminal_type = self._detect_terminal()
        self.supports_emoji = self._detect_emoji_support()
        self.python_type = self._detect_python_type()
        self.actual_shell = self._detect_actual_shell()
        
    def _detect_wsl(self):
        """Detect if running in WSL"""
        # Check for WSL-specific files and environment
        if os.path.exists("/proc/version"):
            try:
                with open("/proc/version", "r") as f:
                    return "microsoft" in f.read().lower()
            except:
                pass
        return "WSL_DISTRO_NAME" in os.environ or "WSL_INTEROP" in os.environ
    
    def _detect_mingw(self):
        """Detect if running in MinGW/MSYS2"""
        return (
            "MSYSTEM" in os.environ or 
            "MINGW" in os.environ.get("MSYSTEM", "") or
            "/mingw" in os.environ.get("PATH", "").lower()
        )
    
    def _detect_cygwin(self):
        """Detect if running in Cygwin"""
        return (
            "CYGWIN" in os.environ or 
            os.path.exists("/cygdrive") or
            "/cygwin" in sys.executable.lower()
        )
    
    def _detect_git_bash(self):
        """Detect if running in Git Bash"""
        return (
            "MINGW" in os.environ.get("MSYSTEM", "") and 
            "Git" in os.environ.get("EXEPATH", "")
        )
    
    def _detect_terminal(self):
        """Detect terminal emulator type"""
        # Check various terminal environment variables
        term_program = os.environ.get("TERM_PROGRAM", "")
        terminal_emulator = os.environ.get("TERMINAL_EMULATOR", "")
        wt_session = os.environ.get("WT_SESSION", "")
        
        if "vscode" in term_program.lower():
            return "vscode"
        elif wt_session:
            return "windows_terminal"
        elif "ConEmu" in os.environ:
            return "conemu"
        elif terminal_emulator:
            return terminal_emulator.lower()
        elif self.is_mingw or self.is_git_bash:
            return "mintty"
        else:
            return "unknown"
    
    def _detect_emoji_support(self):
        """Detect if terminal supports emoji"""
        # Windows Terminal and VSCode generally support emoji
        if self.terminal_type in ["windows_terminal", "vscode"]:
            return True
        
        # Check locale for UTF-8 support
        try:
            current_locale = locale.getlocale()[1]
            if current_locale and "utf" in current_locale.lower():
                return True
        except:
            pass
        
        # Check LANG environment variable
        lang = os.environ.get("LANG", "")
        if "UTF-8" in lang or "utf8" in lang.lower():
            return True
        
        # Conservative default
        return False
    
    def _detect_python_type(self):
        """Detect if Python is Windows native or WSL/Unix"""
        # Check if Python executable is Windows-style
        if "\\" in sys.executable or re.match(r"^[A-Za-z]:", sys.executable):
            return "windows"
        else:
            return "unix"
    
    def _detect_actual_shell(self):
        """Detect the actual shell to use based on environment"""
        # If we're in WSL but Python is Windows, we need special handling
        if self.is_wsl and self.python_type == "windows":
            return "wsl_from_windows"
        
        # MinGW/Git Bash should always use bash
        if self.is_mingw or self.is_git_bash or self.is_cygwin:
            return "bash"
        
        # Native Windows
        if self.os_type == "windows" and not (self.is_wsl or self.is_mingw or self.is_cygwin):
            if "PSModulePath" in os.environ:
                return "powershell"
            else:
                return "cmd"
        
        # Unix-like systems
        shell_env = os.environ.get("SHELL", "").lower()
        if "bash" in shell_env:
            return "bash"
        elif "zsh" in shell_env:
            return "zsh"
        elif "fish" in shell_env:
            return "fish"
        else:
            return "bash"  # Default for Unix
    
    def get_summary(self):
        """Get a summary of detected environment"""
        return {
            "OS": self.os_type,
            "WSL": self.is_wsl,
            "MinGW/MSYS2": self.is_mingw,
            "Git Bash": self.is_git_bash,
            "Cygwin": self.is_cygwin,
            "Terminal": self.terminal_type,
            "Emoji Support": self.supports_emoji,
            "Python Type": self.python_type,
            "Shell": self.actual_shell
        }

def check_rust_installed():
    """Check if Rust is installed"""
    try:
        # Try to run rustc in various ways
        commands = [
            ["rustc", "--version"],
            ["cargo", "--version"]
        ]
        
        for cmd in commands:
            try:
                result = subprocess.run(cmd, 
                                      stdout=subprocess.PIPE, 
                                      stderr=subprocess.PIPE, 
                                      text=True,
                                      timeout=5)
                if result.returncode == 0:
                    return True
            except:
                continue
        
        # If in WSL with Windows Python, try WSL command
        env = EnvironmentDetector()
        if env.is_wsl and env.python_type == "windows":
            try:
                result = subprocess.run(["wsl", "rustc", "--version"],
                                      stdout=subprocess.PIPE,
                                      stderr=subprocess.PIPE,
                                      timeout=5)
                return result.returncode == 0
            except:
                pass
        
        return False
    except:
        return False

def get_script_directory():
    """Get the directory where this script is located"""
    return Path(__file__).parent.absolute()

def run_installer(env_detector, args):
    """Run the appropriate installer based on detected environment"""
    script_dir = get_script_directory()
    
    # Handle special case: WSL accessed from Windows Python
    if env_detector.actual_shell == "wsl_from_windows":
        bash_script = script_dir / "install.sh"
        if not bash_script.exists():
            print("Error: install.sh not found")
            return 1
        
        # Convert Windows path to WSL path
        wsl_path = subprocess.run(["wsl", "wslpath", str(bash_script)],
                                 capture_output=True, text=True).stdout.strip()
        
        # Build WSL command
        wsl_command = ["wsl", "bash", wsl_path]
        wsl_command.extend(args)
        
        # Pass emoji support as environment variable
        env = os.environ.copy()
        env["INSTALLER_EMOJI_SUPPORT"] = "1" if env_detector.supports_emoji else "0"
        
        return subprocess.call(wsl_command, env=env)
    
    # Handle MinGW/Git Bash/Cygwin - always use bash
    elif env_detector.is_mingw or env_detector.is_git_bash or env_detector.is_cygwin:
        bash_script = script_dir / "install.sh"
        if not bash_script.exists():
            print("Error: install.sh not found")
            return 1
        
        # Make sure script is executable
        try:
            os.chmod(bash_script, 0o755)
        except:
            pass
        
        # Use bash directly
        bash_command = ["bash", str(bash_script)]
        bash_command.extend(args)
        
        # Pass emoji support as environment variable
        env = os.environ.copy()
        env["INSTALLER_EMOJI_SUPPORT"] = "1" if env_detector.supports_emoji else "0"
        
        return subprocess.call(bash_command, env=env)
    
    # Windows PowerShell/CMD
    elif env_detector.actual_shell in ["powershell", "cmd"]:
        ps_script = script_dir / "install.ps1"
        if not ps_script.exists():
            print("Error: install.ps1 not found")
            return 1
        
        # Build PowerShell command
        ps_command = ["powershell", "-ExecutionPolicy", "Bypass", "-File", str(ps_script)]
        
        # Pass emoji support as argument
        if not env_detector.supports_emoji:
            ps_command.append("-NoEmoji")
        
        ps_command.extend(args)
        
        return subprocess.call(ps_command)
    
    # Standard Unix/Linux
    else:
        bash_script = script_dir / "install.sh"
        if not bash_script.exists():
            print("Error: install.sh not found")
            return 1
        
        # Make sure script is executable
        os.chmod(bash_script, 0o755)
        
        # Build bash command
        bash_command = ["bash", str(bash_script)]
        bash_command.extend(args)
        
        # Pass emoji support as environment variable
        env = os.environ.copy()
        env["INSTALLER_EMOJI_SUPPORT"] = "1" if env_detector.supports_emoji else "0"
        
        return subprocess.call(bash_command, env=env)

def main():
    """Main entry point"""
    args = sys.argv[1:]
    
    # Initialize environment detector
    env_detector = EnvironmentDetector()
    
    # Show debug info if requested
    if "--debug" in args:
        print("Environment Detection Results:")
        print("=" * 40)
        for key, value in env_detector.get_summary().items():
            print(f"{key}: {value}")
        print("=" * 40)
        print()
        args.remove("--debug")
    
    # Show help if requested
    if "--help" in args or "-h" in args:
        print("Universal Rust Development Tools Installer")
        print("=" * 40)
        print()
        print("This installer automatically detects your environment and runs")
        print("the appropriate installation script.")
        print()
        print("Usage: python install.py [options]")
        print("Options:")
        print("  --all            Install all tools without prompting")
        print("  --debug          Show environment detection details")
        print("  --help, -h       Show this help message")
        print()
        print("Detected environment:")
        for key, value in env_detector.get_summary().items():
            print(f"  {key}: {value}")
        return 0
    
    # Quick Rust check
    if not check_rust_installed():
        print("Error: Rust is not installed!")
        print("Please install Rust first: https://rustup.rs")
        if env_detector.os_type == "windows" or env_detector.python_type == "windows":
            print("For Windows: https://win.rustup.rs")
        else:
            print("Run: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh")
        return 1
    
    # Run appropriate installer
    return run_installer(env_detector, args)

if __name__ == "__main__":
    sys.exit(main())