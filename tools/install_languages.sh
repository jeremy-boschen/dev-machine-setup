#!/usr/bin/env bash

# Programming languages and package managers installation script

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

# Define URLs for language distributions
NODE_URL="https://nodejs.org/dist/v18.16.1/node-v18.16.1-win-x64.zip"
PYTHON_URL="https://www.python.org/ftp/python/3.11.4/python-3.11.4-embed-amd64.zip"
PYTHON_GET_PIP_URL="https://bootstrap.pypa.io/get-pip.py"
SDKMAN_INIT_URL="https://get.sdkman.io"
RUSTUP_INIT_URL="https://win.rustup.rs/x86_64"

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

# Function to install Node.js
install_nodejs() {
    log "info" "Installing Node.js..."
    
    local node_dir="$TOOLS_DIR/node"
    local node_zip="$TEMP_DIR/node.zip"
    
    # Skip if already installed
    if [ -f "$node_dir/node.exe" ]; then
        log "success" "Node.js is already installed at $node_dir"
        return 0
    fi
    
    # Download Node.js
    download_file "$NODE_URL" "$node_zip" || return 1
    
    # Extract Node.js
    extract_zip "$node_zip" "$TEMP_DIR/node_extracted" || return 1
    
    # Move to final location
    local extracted_dir=$(find "$TEMP_DIR/node_extracted" -maxdepth 1 -type d -name "node-*" | head -1)
    
    if [ -z "$extracted_dir" ]; then
        log "error" "Could not find extracted Node.js directory"
        return 1
    fi
    
    mkdir -p "$node_dir"
    cp -r "$extracted_dir"/* "$node_dir/"
    
    # Create symlinks in bin directory
    ln -sf "$node_dir/node.exe" "$BIN_DIR/node.exe"
    ln -sf "$node_dir/npm.cmd" "$BIN_DIR/npm.cmd"
    ln -sf "$node_dir/npx.cmd" "$BIN_DIR/npx.cmd"
    
    # Install yarn globally
    log "info" "Installing Yarn..."
    "$node_dir/npm.cmd" install --global yarn
    
    # Create yarn symlink if it was installed
    if [ -f "$node_dir/yarn.cmd" ]; then
        ln -sf "$node_dir/yarn.cmd" "$BIN_DIR/yarn.cmd"
        log "success" "Yarn installed successfully"
    else
        log "warning" "Yarn installation may have failed"
    fi
    
    # Clean up
    rm -f "$node_zip"
    rm -rf "$TEMP_DIR/node_extracted"
    
    log "success" "Node.js installed successfully"
}

# Function to install Python
install_python() {
    log "info" "Installing Python..."
    
    local python_dir="$TOOLS_DIR/python"
    local python_zip="$TEMP_DIR/python.zip"
    local get_pip_py="$TEMP_DIR/get-pip.py"
    
    # Skip if already installed
    if [ -f "$python_dir/python.exe" ]; then
        log "success" "Python is already installed at $python_dir"
        return 0
    fi
    
    # Download Python
    download_file "$PYTHON_URL" "$python_zip" || return 1
    
    # Extract Python
    mkdir -p "$python_dir"
    extract_zip "$python_zip" "$python_dir" || return 1
    
    # Download get-pip.py
    download_file "$PYTHON_GET_PIP_URL" "$get_pip_py" || return 1
    
    # Enable site-packages for embedded Python
    echo "import site" > "$python_dir/python311._pth"
    echo "." >> "$python_dir/python311._pth"
    echo "./Lib/site-packages" >> "$python_dir/python311._pth"
    
    # Create Lib/site-packages directory
    mkdir -p "$python_dir/Lib/site-packages"
    
    # Install pip
    log "info" "Installing pip..."
    "$python_dir/python.exe" "$get_pip_py" --no-warn-script-location
    
    # Create symlinks in bin directory
    ln -sf "$python_dir/python.exe" "$BIN_DIR/python.exe"
    ln -sf "$python_dir/python.exe" "$BIN_DIR/python3.exe"
    
    # Create pip symlinks if pip was installed
    if [ -f "$python_dir/Scripts/pip.exe" ]; then
        ln -sf "$python_dir/Scripts/pip.exe" "$BIN_DIR/pip.exe"
        ln -sf "$python_dir/Scripts/pip.exe" "$BIN_DIR/pip3.exe"
        log "success" "pip installed successfully"
    else
        log "warning" "pip installation may have failed"
    fi
    
    # Clean up
    rm -f "$python_zip"
    rm -f "$get_pip_py"
    
    log "success" "Python installed successfully"
}

# Function to install SDKMAN
install_sdkman() {
    log "info" "Installing SDKMAN!..."
    
    local sdkman_dir="$TOOLS_DIR/sdkman"
    
    # Skip if already installed
    if [ -d "$sdkman_dir" ] && [ -f "$sdkman_dir/bin/sdkman-init.sh" ]; then
        log "success" "SDKMAN! is already installed at $sdkman_dir"
        return 0
    fi
    
    # Set SDKMAN_DIR
    export SDKMAN_DIR="$sdkman_dir"
    
    # Create sdkman directory
    mkdir -p "$sdkman_dir"
    
    # Download and install SDKMAN!
    log "info" "Downloading and running SDKMAN! installer..."
    curl -s "$SDKMAN_INIT_URL" | bash
    
    if [ -f "$sdkman_dir/bin/sdkman-init.sh" ]; then
        # Source SDKMAN!
        source "$sdkman_dir/bin/sdkman-init.sh"
        
        # Configure SDKMAN!
        sdk selfupdate force
        
        log "success" "SDKMAN! installed successfully"
    else
        log "error" "SDKMAN! installation failed"
        return 1
    fi
    
    # Update .bashrc with SDKMAN! initialization
    if grep -q "SDKMAN_DIR=" "$HOME/.bashrc"; then
        log "info" "SDKMAN! already initialized in .bashrc"
    else
        log "info" "Adding SDKMAN! initialization to .bashrc..."
        echo '' >> "$HOME/.bashrc"
        echo '# SDKMAN! initialization' >> "$HOME/.bashrc"
        echo 'export SDKMAN_DIR="$HOME/dev/tools/sdkman"' >> "$HOME/.bashrc"
        echo '[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"' >> "$HOME/.bashrc"
    fi
}

# Function to install Rust
install_rust() {
    log "info" "Installing Rust..."
    
    local rust_dir="$TOOLS_DIR/rust"
    local rustup_init="$TEMP_DIR/rustup-init.exe"
    
    # Skip if already installed
    if [ -f "$rust_dir/bin/rustc.exe" ]; then
        log "success" "Rust is already installed at $rust_dir"
        return 0
    fi
    
    # Create rust directory
    mkdir -p "$rust_dir"
    
    # Download rustup-init
    download_file "$RUSTUP_INIT_URL" "$rustup_init" || return 1
    
    # Make executable
    chmod +x "$rustup_init"
    
    # Install Rust without prompting
    log "info" "Running Rust installer..."
    RUSTUP_HOME="$rust_dir" CARGO_HOME="$rust_dir" "$rustup_init" -y --no-modify-path
    
    if [ -f "$rust_dir/bin/rustc.exe" ]; then
        # Create symlinks in bin directory
        ln -sf "$rust_dir/bin/rustc.exe" "$BIN_DIR/rustc.exe"
        ln -sf "$rust_dir/bin/cargo.exe" "$BIN_DIR/cargo.exe"
        ln -sf "$rust_dir/bin/rustup.exe" "$BIN_DIR/rustup.exe"
        
        log "success" "Rust installed successfully"
    else
        log "error" "Rust installation failed"
        return 1
    fi
    
    # Update .bashrc with Rust initialization
    if grep -q "CARGO_HOME=" "$HOME/.bashrc"; then
        log "info" "Rust already initialized in .bashrc"
    else
        log "info" "Adding Rust initialization to .bashrc..."
        echo '' >> "$HOME/.bashrc"
        echo '# Rust initialization' >> "$HOME/.bashrc"
        echo 'export RUSTUP_HOME="$HOME/dev/tools/rust"' >> "$HOME/.bashrc"
        echo 'export CARGO_HOME="$HOME/dev/tools/rust"' >> "$HOME/.bashrc"
        echo 'export PATH="$CARGO_HOME/bin:$PATH"' >> "$HOME/.bashrc"
    fi
    
    # Clean up
    rm -f "$rustup_init"
}

# Main function
main() {
    log "info" "Starting programming languages installation..."
    
    # Create directories
    mkdir -p "$BIN_DIR"
    create_temp_dir
    
    # Install languages
    install_nodejs
    install_python
    install_sdkman
    install_rust
    
    # Clean up temp directory
    rm -rf "$TEMP_DIR"
    
    log "success" "Programming languages installation complete"
}

# Run the main function
main
