#!/usr/bin/env bash

# Programming languages and package managers installation script

# Set strict error handling
set -euo pipefail

# Define paths
DEV_DIR="$HOME/dev"
TOOLS_DIR="$DEV_DIR/tools"
BIN_DIR="$TOOLS_DIR/bin"
TEMP_DIR="$TOOLS_DIR/temp"
OPTIONS_FILE=""

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define URLs for language distributions
SDKMAN_INIT_URL="https://get.sdkman.io"
RUSTUP_INIT_URL="https://win.rustup.rs/x86_64"
PYTHON_GET_PIP_URL="https://bootstrap.pypa.io/get-pip.py"

# Default Node.js versions and URLs
NODE_VERSIONS=(
    "18.16.1"
    "20.5.1"
)

NODE_URLS=(
    "https://nodejs.org/dist/v18.16.1/node-v18.16.1-win-x64.zip"
    "https://nodejs.org/dist/v20.5.1/node-v20.5.1-win-x64.zip"
)

# Default Python versions and URLs
PYTHON_VERSIONS=(
    "3.11.4"
    "3.9.13"
)

PYTHON_URLS=(
    "https://www.python.org/ftp/python/3.11.4/python-3.11.4-embed-amd64.zip"
    "https://www.python.org/ftp/python/3.9.13/python-3.9.13-embed-amd64.zip"
)

# Default options
OPTIONS='{
  "languages": {
    "install": true,
    "node": {
      "install": true,
      "versions": [
        {
          "version": "18.16.1",
          "default": true
        }
      ]
    },
    "python": {
      "install": true,
      "versions": [
        {
          "version": "3.11.4",
          "default": true
        }
      ]
    },
    "rust": {
      "install": true
    },
    "sdkman": {
      "install": true
    }
  }
}'

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --options-file=*)
            OPTIONS_FILE="${arg#*=}"
            shift
            ;;
        *)
            # Unknown option
            ;;
    esac
done

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

# Function to load options from file
load_options() {
    # Check if options file is provided and exists
    if [[ -n "$OPTIONS_FILE" && -f "$OPTIONS_FILE" ]]; then
        log "info" "Using options from $OPTIONS_FILE"
        OPTIONS=$(cat "$OPTIONS_FILE")
    else
        log "info" "Using default options"
    fi
    
    # Check if we have jq installed
    if ! command -v jq &> /dev/null; then
        log "warning" "jq is not available, some options may not be applied correctly"
    fi
}

# Function to get an option value
get_option() {
    local path="$1"
    local default_value="${2:-false}"
    
    # If jq is not available, return default
    if ! command -v jq &> /dev/null; then
        echo "$default_value"
        return
    fi
    
    # Try to get the value, return default if not found
    local value
    value=$(echo "$OPTIONS" | jq -r "$path // \"$default_value\"" 2>/dev/null)
    
    # Handle empty or null values
    if [[ -z "$value" || "$value" == "null" ]]; then
        echo "$default_value"
    else
        echo "$value"
    fi
}

# Function to install a specific version of Node.js
install_nodejs_version() {
    local version="$1"
    local is_default="${2:-false}"
    local node_base_dir="$TOOLS_DIR/nodejs"
    local node_dir="$node_base_dir/node-v$version"
    local node_zip="$TEMP_DIR/node-v$version.zip"
    local node_url="https://nodejs.org/dist/v$version/node-v$version-win-x64.zip"
    
    log "info" "Installing Node.js v$version..."
    
    # Skip if already installed
    if [ -f "$node_dir/node.exe" ]; then
        log "success" "Node.js v$version is already installed at $node_dir"
        
        # Create symlinks if this is the default version
        if [ "$is_default" == "true" ]; then
            log "info" "Setting Node.js v$version as the default version"
            ln -sf "$node_dir/node.exe" "$BIN_DIR/node.exe"
            ln -sf "$node_dir/npm.cmd" "$BIN_DIR/npm.cmd"
            ln -sf "$node_dir/npx.cmd" "$BIN_DIR/npx.cmd"
        fi
        
        return 0
    fi
    
    # Create base directory if it doesn't exist
    mkdir -p "$node_base_dir"
    
    # Download Node.js
    download_file "$node_url" "$node_zip" || return 1
    
    # Extract Node.js
    extract_zip "$node_zip" "$TEMP_DIR/node_extracted" || return 1
    
    # Move to final location
    local extracted_dir=$(find "$TEMP_DIR/node_extracted" -maxdepth 1 -type d -name "node-*" | head -1)
    
    if [ -z "$extracted_dir" ]; then
        log "error" "Could not find extracted Node.js directory"
        return 1
    fi
    
    # Create version-specific directory
    mkdir -p "$node_dir"
    cp -r "$extracted_dir"/* "$node_dir/"
    
    # Create version-specific symlinks
    ln -sf "$node_dir/node.exe" "$BIN_DIR/node-v$version.exe"
    
    # Create default symlinks if this is the default version
    if [ "$is_default" == "true" ]; then
        log "info" "Setting Node.js v$version as the default version"
        ln -sf "$node_dir/node.exe" "$BIN_DIR/node.exe"
        ln -sf "$node_dir/npm.cmd" "$BIN_DIR/npm.cmd"
        ln -sf "$node_dir/npx.cmd" "$BIN_DIR/npx.cmd"
    fi
    
    # Install yarn globally for the default version
    if [ "$is_default" == "true" ]; then
        log "info" "Installing Yarn for Node.js v$version..."
        "$node_dir/npm.cmd" install --global yarn
        
        # Create yarn symlink if it was installed
        if [ -f "$node_dir/yarn.cmd" ]; then
            ln -sf "$node_dir/yarn.cmd" "$BIN_DIR/yarn.cmd"
            log "success" "Yarn installed successfully"
        else
            log "warning" "Yarn installation may have failed"
        fi
    fi
    
    # Clean up
    rm -f "$node_zip"
    rm -rf "$TEMP_DIR/node_extracted"
    
    log "success" "Node.js v$version installed successfully"
}

# Function to install Node.js with version selection from options
install_nodejs() {
    log "info" "Installing Node.js..."
    
    # Check if Node.js installation is enabled
    if [[ "$(get_option ".languages.node.install")" != "true" ]]; then
        log "info" "Node.js installation is disabled in options, skipping"
        return 0
    fi
    
    # Get node versions from options
    local versions_json=$(get_option ".languages.node.versions")
    
    # If jq is not available or versions not found, use defaults
    if [[ -z "$versions_json" || "$versions_json" == "false" || ! -x "$(command -v jq)" ]]; then
        log "info" "Using default Node.js versions"
        
        # Install default Node.js version
        install_nodejs_version "${NODE_VERSIONS[0]}" "true"
        
        return 0
    fi
    
    # Count versions
    local version_count=$(echo "$versions_json" | jq '. | length')
    
    # Install each specified version
    for ((i = 0; i < version_count; i++)); do
        local version=$(echo "$versions_json" | jq -r ".[$i].version")
        local is_default=$(echo "$versions_json" | jq -r ".[$i].default // false")
        
        if [[ -n "$version" && "$version" != "null" ]]; then
            install_nodejs_version "$version" "$is_default"
        fi
    done
}

# Function to install a specific version of Python
install_python_version() {
    local version="$1"
    local is_default="${2:-false}"
    local python_base_dir="$TOOLS_DIR/python"
    local version_dir_name="Python${version//./}"  # Convert 3.11.4 to Python3114
    local python_dir="$python_base_dir/$version_dir_name"
    local python_zip="$TEMP_DIR/python-$version.zip"
    local python_url="https://www.python.org/ftp/python/$version/python-$version-embed-amd64.zip"
    local get_pip_py="$TEMP_DIR/get-pip.py"
    
    log "info" "Installing Python $version..."
    
    # Skip if already installed
    if [ -f "$python_dir/python.exe" ]; then
        log "success" "Python $version is already installed at $python_dir"
        
        # Create symlinks if this is the default version
        if [ "$is_default" == "true" ]; then
            log "info" "Setting Python $version as the default version"
            ln -sf "$python_dir/python.exe" "$BIN_DIR/python.exe"
            ln -sf "$python_dir/python.exe" "$BIN_DIR/python3.exe"
            
            # Update pip symlinks if available
            if [ -f "$python_dir/Scripts/pip.exe" ]; then
                ln -sf "$python_dir/Scripts/pip.exe" "$BIN_DIR/pip.exe"
                ln -sf "$python_dir/Scripts/pip.exe" "$BIN_DIR/pip3.exe"
            fi
        fi
        
        return 0
    fi
    
    # Create base directory if it doesn't exist
    mkdir -p "$python_base_dir"
    mkdir -p "$python_dir"
    
    # Download Python
    download_file "$python_url" "$python_zip" || return 1
    
    # Extract Python
    extract_zip "$python_zip" "$python_dir" || return 1
    
    # Download get-pip.py
    download_file "$PYTHON_GET_PIP_URL" "$get_pip_py" || return 1
    
    # Determine Python version-specific _pth file
    local pth_file="python${version//./}_pth"
    if [ ! -f "$python_dir/$pth_file" ]; then
        # Try to find the _pth file
        pth_file=$(find "$python_dir" -name "*.pth" | head -1)
        
        # If still not found, use a default naming scheme
        if [ -z "$pth_file" ]; then
            pth_file="$python_dir/python${version%%.*}${version#*.}.pth"
        else
            pth_file=$(basename "$pth_file")
        fi
    fi
    
    # Enable site-packages for embedded Python
    echo "import site" > "$python_dir/$pth_file"
    echo "." >> "$python_dir/$pth_file"
    echo "./Lib/site-packages" >> "$python_dir/$pth_file"
    
    # Create Lib/site-packages directory
    mkdir -p "$python_dir/Lib/site-packages"
    
    # Install pip
    log "info" "Installing pip for Python $version..."
    "$python_dir/python.exe" "$get_pip_py" --no-warn-script-location
    
    # Create version-specific symlinks
    ln -sf "$python_dir/python.exe" "$BIN_DIR/python$version.exe"
    
    # Create default symlinks if this is the default version
    if [ "$is_default" == "true" ]; then
        log "info" "Setting Python $version as the default version"
        ln -sf "$python_dir/python.exe" "$BIN_DIR/python.exe"
        ln -sf "$python_dir/python.exe" "$BIN_DIR/python3.exe"
    fi
    
    # Create pip symlinks
    if [ -f "$python_dir/Scripts/pip.exe" ]; then
        ln -sf "$python_dir/Scripts/pip.exe" "$BIN_DIR/pip$version.exe"
        
        # Create default pip symlinks if this is the default version
        if [ "$is_default" == "true" ]; then
            ln -sf "$python_dir/Scripts/pip.exe" "$BIN_DIR/pip.exe"
            ln -sf "$python_dir/Scripts/pip.exe" "$BIN_DIR/pip3.exe"
        fi
        
        log "success" "pip installed successfully for Python $version"
    else
        log "warning" "pip installation may have failed for Python $version"
    fi
    
    # Clean up
    rm -f "$python_zip"
    
    log "success" "Python $version installed successfully"
}

# Function to install Python with version selection from options
install_python() {
    log "info" "Installing Python..."
    
    # Check if Python installation is enabled
    if [[ "$(get_option ".languages.python.install")" != "true" ]]; then
        log "info" "Python installation is disabled in options, skipping"
        return 0
    fi
    
    # Get python versions from options
    local versions_json=$(get_option ".languages.python.versions")
    
    # If jq is not available or versions not found, use defaults
    if [[ -z "$versions_json" || "$versions_json" == "false" || ! -x "$(command -v jq)" ]]; then
        log "info" "Using default Python versions"
        
        # Install default Python version
        install_python_version "${PYTHON_VERSIONS[0]}" "true"
        
        return 0
    fi
    
    # Count versions
    local version_count=$(echo "$versions_json" | jq '. | length')
    
    # Download get-pip.py once
    local get_pip_py="$TEMP_DIR/get-pip.py"
    download_file "$PYTHON_GET_PIP_URL" "$get_pip_py" || return 1
    
    # Install each specified version
    for ((i = 0; i < version_count; i++)); do
        local version=$(echo "$versions_json" | jq -r ".[$i].version")
        local is_default=$(echo "$versions_json" | jq -r ".[$i].default // false")
        
        if [[ -n "$version" && "$version" != "null" ]]; then
            install_python_version "$version" "$is_default"
        fi
    done
    
    # Clean up
    rm -f "$get_pip_py"
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

# Update Rust installation to check options
install_rust() {
    log "info" "Installing Rust..."
    
    # Check if Rust installation is enabled
    if [[ "$(get_option ".languages.rust.install")" != "true" ]]; then
        log "info" "Rust installation is disabled in options, skipping"
        return 0
    fi
    
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

# Update SDKMAN installation to check options
install_sdkman() {
    log "info" "Installing SDKMAN!..."
    
    # Check if SDKMAN installation is enabled
    if [[ "$(get_option ".languages.sdkman.install")" != "true" ]]; then
        log "info" "SDKMAN installation is disabled in options, skipping"
        return 0
    fi
    
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
        
        # Check if Java installation is enabled
        local java_version=$(get_option ".languages.sdkman.java.version")
        local install_java=$(get_option ".languages.sdkman.java.install")
        
        if [[ "$install_java" == "true" && -n "$java_version" && "$java_version" != "null" ]]; then
            log "info" "Installing Java $java_version via SDKMAN..."
            sdk install java "$java_version"
        fi
        
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

# Main function
main() {
    log "info" "Starting programming languages installation..."
    
    # Create directories
    mkdir -p "$BIN_DIR"
    create_temp_dir
    
    # Load options
    load_options
    
    # Check if language installation is enabled
    if [[ "$(get_option ".languages.install")" != "true" ]]; then
        log "info" "Programming languages installation is disabled in options, skipping"
        return 0
    fi
    
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
