#!/usr/bin/env bash

# Text editors installation script

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

# Define URLs for portable versions
SUBLIME_URL="https://download.sublimetext.com/sublime_text_build_4143_x64.zip"
NOTEPAD_PLUS_PLUS_URL="https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.5.4/npp.8.5.4.portable.x64.zip"

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

# Function to extract a zip file
extract_zip() {
    local zip_file=$1
    local extract_dir=$2
    
    log "info" "Extracting $zip_file to $extract_dir..."
    
    # Create extract directory if it doesn't exist
    if [ ! -d "$extract_dir" ]; then
        mkdir -p "$extract_dir"
    fi
    
    # Check if unzip command is available
    if command -v unzip &> /dev/null; then
        unzip -q -o "$zip_file" -d "$extract_dir"
    # Check if 7z command is available (from Git for Windows)
    elif command -v 7z &> /dev/null; then
        7z x -y -o"$extract_dir" "$zip_file" > /dev/null
    # Use Windows PowerShell as a fallback
    else
        log "info" "Using PowerShell to extract zip file..."
        powershell.exe -Command "Expand-Archive -Path '$zip_file' -DestinationPath '$extract_dir' -Force"
    fi
    
    if [ $? -eq 0 ]; then
        log "success" "Extraction complete"
        return 0
    else
        log "error" "Extraction failed"
        return 1
    fi
}

# Function to install Sublime Text
install_sublime_text() {
    log "info" "Installing Sublime Text..."
    
    local sublime_dir="$TOOLS_DIR/sublime_text"
    local sublime_zip="$TEMP_DIR/sublime_text.zip"
    
    # Skip if already installed
    if [ -f "$sublime_dir/sublime_text.exe" ]; then
        log "success" "Sublime Text is already installed at $sublime_dir"
        return 0
    fi
    
    # Download Sublime Text
    download_file "$SUBLIME_URL" "$sublime_zip" || return 1
    
    # Extract Sublime Text
    extract_zip "$sublime_zip" "$sublime_dir" || return 1
    
    # Create symlink in bin directory
    if [ -f "$sublime_dir/sublime_text.exe" ]; then
        ln -sf "$sublime_dir/sublime_text.exe" "$BIN_DIR/sublime_text.exe"
        ln -sf "$sublime_dir/sublime_text.exe" "$BIN_DIR/subl.exe"
        log "success" "Sublime Text installed successfully"
    else
        log "error" "Sublime Text executable not found after extraction"
        return 1
    fi
    
    # Clean up
    rm -f "$sublime_zip"
}

# Function to install Notepad++
install_notepad_plus_plus() {
    log "info" "Installing Notepad++..."
    
    local npp_dir="$TOOLS_DIR/notepad++"
    local npp_zip="$TEMP_DIR/npp.zip"
    
    # Skip if already installed
    if [ -f "$npp_dir/notepad++.exe" ]; then
        log "success" "Notepad++ is already installed at $npp_dir"
        return 0
    fi
    
    # Download Notepad++
    download_file "$NOTEPAD_PLUS_PLUS_URL" "$npp_zip" || return 1
    
    # Extract Notepad++
    extract_zip "$npp_zip" "$npp_dir" || return 1
    
    # Create symlink in bin directory
    if [ -f "$npp_dir/notepad++.exe" ]; then
        ln -sf "$npp_dir/notepad++.exe" "$BIN_DIR/notepad++.exe"
        ln -sf "$npp_dir/notepad++.exe" "$BIN_DIR/npp.exe"
        log "success" "Notepad++ installed successfully"
    else
        log "error" "Notepad++ executable not found after extraction"
        return 1
    fi
    
    # Clean up
    rm -f "$npp_zip"
}

# Main function
main() {
    log "info" "Starting text editors installation..."
    
    # Create temporary directory
    create_temp_dir
    
    # Install Sublime Text
    install_sublime_text
    
    # Install Notepad++
    install_notepad_plus_plus
    
    # Clean up temp directory
    rm -rf "$TEMP_DIR"
    
    log "success" "Text editors installation complete"
}

# Run the main function
main
