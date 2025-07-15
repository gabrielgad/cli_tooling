# Rust Development Tools Installer

A cross-platform installer for essential Rust development tools that works on Windows (PowerShell), macOS, and Linux.

## 🚀 Quick Start

### One-line Installation (All Tools)

**Windows (PowerShell):**

```powershell
.\install.ps1 --all
```

**macOS/Linux:**

```bash
./install.sh --all
```

**Cross-platform (Python):**

```bash
python install.py --all
```

### Interactive Installation (Select Tools)

Simply run the installer without arguments for an interactive selection menu:

**Windows:** `.\install.ps1` or double-click `install.cmd`  
**macOS/Linux:** `./install.sh`  
**Any OS:** `python install.py`

## 📦 Available Tools

| Tool | Command | Description |
|------|---------|-------------|
| **exa** | `exa` | Modern replacement for `ls` with colors, icons, and git integration |
| **bat** | `bat` | A `cat` clone with syntax highlighting and git integration |
| **zellij** | `zellij` | Terminal workspace multiplexer (like tmux but more user-friendly) |
| **mprocs** | `mprocs` | Run multiple processes in parallel with a TUI interface |
| **ripgrep** | `rg` | Blazingly fast recursive text search (better than grep) |
| **bacon** | `bacon` | Background Rust code checker - shows errors as you code |
| **cargo-info** | `cargo info` | Display detailed information about crates from crates.io |
| **speedtest-rs** | `speedtest-rs` | Command-line internet speed test |
| **rtx-cli** | `rtx` | Polyglot runtime version manager (manage multiple Rust/Node/Python versions) |

## 🔧 Prerequisites

- **Rust**: Must be installed first. Get it from [rustup.rs](https://rustup.rs)
- **Python 3** (optional): Only needed for the cross-platform wrapper

## 📁 Installation Files

``` dir
rust-dev-tools/
├── install.sh          # Bash installer for macOS/Linux
├── install.ps1         # PowerShell installer for Windows
├── install.py          # Cross-platform Python wrapper
├── install.cmd         # Windows batch file wrapper
└── README.md           # This file
```

## 🎯 Usage Examples

### Install specific tools interactively

```bash
./install.sh
# Then follow the prompts to select which tools to install
```

### Install all tools without prompts

```bash
./install.sh --all
```

### Get help

```bash
./install.sh --help
```

## 💡 Tool Usage Tips

### exa - Better ls

```bash
exa -la              # List all files with details
exa --tree           # Show directory tree
exa --icons          # Show file icons
exa -la --git        # Show git status
```

### bat - Better cat

```bash
bat file.rs          # View with syntax highlighting
bat -n file.rs       # Show line numbers
bat -A file.rs       # Show non-printable characters
bat *.rs             # View multiple files
```

### ripgrep - Fast search

```bash
rg "pattern"         # Search recursively
rg -i "pattern"      # Case-insensitive search
rg -t rust "TODO"    # Search only Rust files
rg -C 3 "error"      # Show 3 lines of context
```

### zellij - Terminal multiplexer

```bash
zellij               # Start new session
zellij attach        # Attach to existing session
# Ctrl+P, N for new pane
# Ctrl+P, X to close pane
```

### mprocs - Multiple processes

```bash
mprocs "cargo watch" "cargo test --watch"
mprocs server client worker
```

### bacon - Continuous checking

```bash
bacon                # Run default check
bacon test           # Run tests continuously
bacon clippy         # Run clippy continuously
```

### cargo-info - Crate information

```bash
cargo info serde     # Show info about serde
cargo info --json tokio  # JSON output
```

### speedtest-rs - Speed test

```bash
speedtest-rs         # Run speed test
speedtest-rs --json  # JSON output
```

### rtx - Runtime manager

```bash
rtx install rust     # Install latest Rust
rtx use rust@1.75    # Use specific version
rtx list             # Show installed versions
```

## 🔍 Troubleshooting

### "Rust is not installed"

Install Rust first:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### "Permission denied" on Linux/macOS

Make the script executable:

```bash
chmod +x install.sh
```

### PowerShell execution policy error

Run PowerShell as Administrator and execute:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Or run the installer with:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

### Tool already installed

The installer will skip tools that are already installed. To reinstall, first uninstall with:

```bash
cargo uninstall <tool-name>
```

## 🤝 Contributing

Feel free to suggest additional tools or improvements!

## 📝 License

This installer is provided as-is for the Rust community. The individual tools have their own licenses.
