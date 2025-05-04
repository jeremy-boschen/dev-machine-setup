#!/usr/bin/env bash

# Windows Terminal installation script

# Set strict error handling
set -euo pipefail

# Define paths
DEV_DIR="$HOME/dev"
TOOLS_DIR="$DEV_DIR/tools"
BIN_DIR="$TOOLS_DIR/bin"
TEMP_DIR="$TOOLS_DIR/temp"

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define URLs for terminals
WINDOWS_TERMINAL_URL="https://github.com/microsoft/terminal/releases/download/v1.16.10261.0/Microsoft.WindowsTerminal_Win10_1.16.10261.0_8wekyb3d8bbwe.msixbundle"

# Log function for consistent output
log() {
    local level=$1
    local message=$2
    case $level in
        "info")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "success")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        "warning")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "error")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
        *)
            echo -e "$message"
            ;;
    esac
}

# Function to create temp directory if it doesn't exist
create_temp_dir() {
    if [ ! -d "$TEMP_DIR" ]; then
        mkdir -p "$TEMP_DIR"
        log "info" "Created temporary directory at $TEMP_DIR"
    fi
}

# Function to download a file
download_file() {
    local url=$1
    local output_file=$2
    
    log "info" "Downloading $url to $output_file..."
    
    if command -v curl &> /dev/null; then
        curl -L -o "$output_file" "$url"
    elif command -v wget &> /dev/null; then
        wget -O "$output_file" "$url"
    else
        log "error" "Neither curl nor wget is available. Cannot download files."
        return 1
    fi
    
    if [ -f "$output_file" ]; then
        log "success" "Download complete"
        return 0
    else
        log "error" "Download failed"
        return 1
    fi
}

# Function to install Windows Terminal
install_windows_terminal() {
    log "info" "Installing Windows Terminal..."
    
    local terminal_dir="$TOOLS_DIR/terminal"
    local terminal_msix="$TEMP_DIR/WindowsTerminal.msixbundle"
    
    # Check if we can install MSIX packages without admin rights
    log "warning" "Windows Terminal typically requires Microsoft Store or admin privileges to install."
    log "warning" "This script will download the MSIX package, but you may need to install it manually."
    log "warning" "Alternatively, you can use Git Bash as your terminal, which is already installed."
    
    # Download Windows Terminal
    download_file "$WINDOWS_TERMINAL_URL" "$terminal_msix" || return 1
    
    # Create directory for Windows Terminal
    mkdir -p "$terminal_dir"
    
    # Copy the MSIX package to the terminal directory
    cp "$terminal_msix" "$terminal_dir/"
    
    log "info" "Windows Terminal MSIX package downloaded to $terminal_dir/WindowsTerminal.msixbundle"
    log "info" "To install, double-click the MSIX file and follow the prompts (may require admin rights)."
    
    # Clean up
    rm -f "$terminal_msix"
    
    log "success" "Windows Terminal package ready for installation"
    
    # Configure Git Bash as a fallback
    log "info" "Configuring Git Bash as the primary terminal..."
    
    # Create a Windows shortcut to Git Bash in a convenient location
    local git_bash_shortcut="$HOME/Desktop/Git Bash.lnk"
    
    # Use PowerShell to create a shortcut
    powershell.exe -Command "
        \$WshShell = New-Object -ComObject WScript.Shell
        \$Shortcut = \$WshShell.CreateShortcut('$git_bash_shortcut')
        \$Shortcut.TargetPath = '$TOOLS_DIR/git/git-bash.exe'
        \$Shortcut.IconLocation = '$TOOLS_DIR/git/git-bash.exe,0'
        \$Shortcut.Description = 'Git Bash Terminal'
        \$Shortcut.WorkingDirectory = '$HOME'
        \$Shortcut.Save()
    " || log "warning" "Failed to create Git Bash shortcut on the desktop."
    
    log "success" "Git Bash configured as primary terminal"
}

# Function to configure terminal settings
configure_terminal_settings() {
    log "info" "Configuring terminal settings..."
    
    # Create custom .minttyrc for Git Bash
    local minttyrc="$HOME/.minttyrc"
    
    # Only update if it doesn't exist or is a default configuration
    if [ ! -f "$minttyrc" ] || [ $(wc -l < "$minttyrc") -lt 5 ]; then
        log "info" "Creating custom .minttyrc configuration for Git Bash..."
        
        cat > "$minttyrc" << EOF
# Git Bash terminal configuration
Font=Consolas
FontHeight=11
Transparency=off
FontSmoothing=full
Locale=en_US
Charset=UTF-8
Columns=120
Rows=30
OpaqueWhenFocused=no
ForegroundColour=131,148,150
BackgroundColour=0,43,54
CursorColour=220,50,47
ThemeFile=
FontWeight=400
FontIsBold=no
CursorType=block
EOF
        
        log "success" "Git Bash terminal configuration updated"
    else
        log "info" "Existing .minttyrc found, not overwriting"
    fi
}

# Main function
main() {
    log "info" "Starting terminal setup..."
    
    # Create directories
    mkdir -p "$BIN_DIR"
    create_temp_dir
    
    # Install Windows Terminal
    install_windows_terminal
    
    # Configure terminal settings
    configure_terminal_settings
    
    # Clean up temp directory
    rm -rf "$TEMP_DIR"
    
    log "success" "Terminal setup complete"
}

# Run the main function
main
