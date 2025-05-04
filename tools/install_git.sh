#!/usr/bin/env bash

# Git installation and configuration script
# Git is already installed via portable Git in the batch script
# This script handles additional configuration

# Set strict error handling
set -euo pipefail

# Define paths
DEV_DIR="$HOME/dev"
TOOLS_DIR="$DEV_DIR/tools"
BIN_DIR="$TOOLS_DIR/bin"
GIT_DIR="$TOOLS_DIR/git"

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check if Git is already installed
check_git_installation() {
    if [ -d "$GIT_DIR" ] && [ -f "$GIT_DIR/bin/git.exe" ]; then
        log "success" "Git is already installed at $GIT_DIR"
        return 0
    else
        log "error" "Git installation not found at $GIT_DIR"
        log "info" "Git should have been installed by the setup.bat script"
        log "info" "Please run the setup.bat script first"
        return 1
    fi
}

# Configure Git LFS
configure_git_lfs() {
    log "info" "Setting up Git LFS..."
    
    if [ -f "$GIT_DIR/mingw64/bin/git-lfs.exe" ]; then
        # Create symbolic link to git-lfs in the bin directory
        if [ ! -f "$BIN_DIR/git-lfs.exe" ]; then
            ln -sf "$GIT_DIR/mingw64/bin/git-lfs.exe" "$BIN_DIR/git-lfs.exe"
        fi
        
        # Initialize Git LFS
        "$GIT_DIR/bin/git.exe" lfs install --skip-repo
        
        log "success" "Git LFS configured"
    else
        log "warning" "Git LFS executable not found, skipping LFS setup"
    fi
}

# Create common Git aliases
create_git_aliases() {
    log "info" "Creating Git aliases..."
    
    # Common aliases for productivity
    "$GIT_DIR/bin/git.exe" config --global alias.co checkout
    "$GIT_DIR/bin/git.exe" config --global alias.br branch
    "$GIT_DIR/bin/git.exe" config --global alias.ci commit
    "$GIT_DIR/bin/git.exe" config --global alias.st status
    "$GIT_DIR/bin/git.exe" config --global alias.unstage 'reset HEAD --'
    "$GIT_DIR/bin/git.exe" config --global alias.last 'log -1 HEAD'
    "$GIT_DIR/bin/git.exe" config --global alias.visual '!gitk'
    "$GIT_DIR/bin/git.exe" config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
    
    log "success" "Git aliases created"
}

# Set Git editor
set_git_editor() {
    log "info" "Setting up Git editor..."
    
    # Check for available editors
    if [ -f "$TOOLS_DIR/sublime_text/sublime_text.exe" ]; then
        "$GIT_DIR/bin/git.exe" config --global core.editor "'$TOOLS_DIR/sublime_text/sublime_text.exe' -w"
        log "success" "Git editor set to Sublime Text"
    elif [ -f "$TOOLS_DIR/notepad++/notepad++.exe" ]; then
        "$GIT_DIR/bin/git.exe" config --global core.editor "'$TOOLS_DIR/notepad++/notepad++.exe' -multiInst -notabbar -nosession -noPlugin"
        log "success" "Git editor set to Notepad++"
    else
        # Default to Vim which comes with Git for Windows
        "$GIT_DIR/bin/git.exe" config --global core.editor "vim"
        log "success" "Git editor set to Vim"
    fi
}

# Configure Git credential helper
configure_credential_helper() {
    log "info" "Setting up Git credential helper..."
    
    # Use Git credential manager if available
    if [ -f "$GIT_DIR/mingw64/libexec/git-core/git-credential-manager.exe" ]; then
        "$GIT_DIR/bin/git.exe" config --global credential.helper manager
        log "success" "Git credential helper set to Git Credential Manager"
    else
        # Fall back to cache helper
        "$GIT_DIR/bin/git.exe" config --global credential.helper cache
        log "success" "Git credential helper set to cache"
    fi
}

# Configure Git to handle line endings properly
configure_line_endings() {
    log "info" "Configuring Git line endings..."
    
    # Set auto CRLF handling
    "$GIT_DIR/bin/git.exe" config --global core.autocrlf true
    
    log "success" "Git line endings configured"
}

# Configure additional Git settings
configure_additional_settings() {
    log "info" "Configuring additional Git settings..."
    
    # Set color UI
    "$GIT_DIR/bin/git.exe" config --global color.ui auto
    
    # Set push default
    "$GIT_DIR/bin/git.exe" config --global push.default simple
    
    # Set pull rebase by default
    "$GIT_DIR/bin/git.exe" config --global pull.rebase true
    
    # Enable git rerere
    "$GIT_DIR/bin/git.exe" config --global rerere.enabled true
    
    log "success" "Additional Git settings configured"
}

# Main function
main() {
    log "info" "Starting Git setup..."
    
    # Check if Git is already installed
    check_git_installation || exit 1
    
    # Create symbolic link to git.exe in the bin directory
    if [ ! -f "$BIN_DIR/git.exe" ]; then
        ln -sf "$GIT_DIR/bin/git.exe" "$BIN_DIR/git.exe"
    fi
    
    # Configure Git
    configure_git_lfs
    create_git_aliases
    set_git_editor
    configure_credential_helper
    configure_line_endings
    configure_additional_settings
    
    log "success" "Git setup complete"
    log "info" "Git version: $("$GIT_DIR/bin/git.exe" --version)"
}

# Run the main function
main
