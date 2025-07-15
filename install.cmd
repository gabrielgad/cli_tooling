@echo off
REM Windows batch file wrapper for Rust Dev Tools Installer

REM Check if Python is available
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python is not installed or not in PATH
    echo Trying PowerShell script directly...
    powershell -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
) else (
    REM Use Python wrapper for better compatibility
    python "%~dp0install.py" %*
)