#!/usr/bin/env bash

# CLI tools installation script

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

# Define URLs for tools
JQ_URL="https://github.com/stedolan/jq/releases/download/jq-1.6/jq-win64.exe"
YQ_URL="https://github.com/mikefarah/yq/releases/download/v4.35.1/yq_windows_amd64.exe"
KUBECTL_URL="https://dl.k8s.io/release/v1.27.4/bin/windows/amd64/kubectl.exe"
K9S_URL="https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_Windows_amd64.zip"
AGE_URL="https://github.com/FiloSottile/age/releases/download/v1.1.1/age-v1.1.1-windows-amd64.zip"
DIVE_URL="https://github.com/wagoodman/dive/releases/download/v0.10.0/dive_0.10.0_windows_amd64.zip"
GH_URL="https://github.com/cli/cli/releases/download/v2.30.0/gh_2.30.0_windows_amd64.zip"
KIND_URL="https://kind.sigs.k8s.io/dl/v0.20.0/kind-windows-amd64"
PANDOC_URL="https://github.com/jgm/pandoc/releases/download/3.1.2/pandoc-3.1.2-windows-x86_64.zip"
BAT_URL="https://github.com/sharkdp/bat/releases/download/v0.23.0/bat-v0.23.0-x86_64-pc-windows-msvc.zip"
FD_URL="https://github.com/sharkdp/fd/releases/download/v8.7.0/fd-v8.7.0-x86_64-pc-windows-msvc.zip"
RIPGREP_URL="https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/ripgrep-13.0.0-x86_64-pc-windows-msvc.zip"
FZF_URL="https://github.com/junegunn/fzf/releases/download/0.42.0/fzf-0.42.0-windows_amd64.zip"
HELM_URL="https://get.helm.sh/helm-v3.12.3-windows-amd64.zip"

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

# Function to install single binary tools
install_single_binary() {
    local name=$1
    local url=$2
    local output_file="$BIN_DIR/$name"
    
    # Skip if already installed
    if [ -f "$output_file" ]; then
        log "success" "$name is already installed"
        return 0
    fi
    
    # Download the binary
    download_file "$url" "$output_file" || return 1
    
    # Make it executable
    chmod +x "$output_file"
    
    log "success" "$name installed successfully"
}

# Function to install tools that come in zip archives
install_from_zip() {
    local name=$1
    local url=$2
    local bin_name=$3
    local extract_dir="$TEMP_DIR/$name"
    local zip_file="$TEMP_DIR/$name.zip"
    
    # Skip if already installed
    if [ -f "$BIN_DIR/$bin_name" ]; then
        log "success" "$name is already installed"
        return 0
    fi
    
    # Download the zip
    download_file "$url" "$zip_file" || return 1
    
    # Extract the zip
    extract_zip "$zip_file" "$extract_dir" || return 1
    
    # Find the binary in the extracted directory
    local binary_path=""
    if [ -f "$extract_dir/$bin_name" ]; then
        binary_path="$extract_dir/$bin_name"
    else
        # Search for the binary recursively
        binary_path=$(find "$extract_dir" -name "$bin_name" -type f | head -1)
        
        if [ -z "$binary_path" ]; then
            log "error" "Could not find $bin_name in extracted files"
            return 1
        fi
    fi
    
    # Copy to bin directory
    cp "$binary_path" "$BIN_DIR/$bin_name"
    chmod +x "$BIN_DIR/$bin_name"
    
    # Clean up
    rm -f "$zip_file"
    rm -rf "$extract_dir"
    
    log "success" "$name installed successfully"
}

# Install jq
install_jq() {
    log "info" "Installing jq..."
    install_single_binary "jq.exe" "$JQ_URL"
}

# Install yq
install_yq() {
    log "info" "Installing yq..."
    install_single_binary "yq.exe" "$YQ_URL"
}

# Install kubectl
install_kubectl() {
    log "info" "Installing kubectl..."
    install_single_binary "kubectl.exe" "$KUBECTL_URL"
}

# Install k9s
install_k9s() {
    log "info" "Installing k9s..."
    install_from_zip "k9s" "$K9S_URL" "k9s.exe"
}

# Install age
install_age() {
    log "info" "Installing age..."
    
    local age_dir="$TEMP_DIR/age"
    local age_zip="$TEMP_DIR/age.zip"
    
    # Skip if already installed
    if [ -f "$BIN_DIR/age.exe" ] && [ -f "$BIN_DIR/age-keygen.exe" ]; then
        log "success" "age is already installed"
        return 0
    fi
    
    # Download the zip
    download_file "$AGE_URL" "$age_zip" || return 1
    
    # Extract the zip
    extract_zip "$age_zip" "$age_dir" || return 1
    
    # Find the binaries in the extracted directory
    local age_exe=$(find "$age_dir" -name "age.exe" -type f | head -1)
    local age_keygen_exe=$(find "$age_dir" -name "age-keygen.exe" -type f | head -1)
    
    if [ -z "$age_exe" ] || [ -z "$age_keygen_exe" ]; then
        log "error" "Could not find age executables in extracted files"
        return 1
    fi
    
    # Copy to bin directory
    cp "$age_exe" "$BIN_DIR/age.exe"
    cp "$age_keygen_exe" "$BIN_DIR/age-keygen.exe"
    chmod +x "$BIN_DIR/age.exe"
    chmod +x "$BIN_DIR/age-keygen.exe"
    
    # Clean up
    rm -f "$age_zip"
    rm -rf "$age_dir"
    
    log "success" "age installed successfully"
}

# Install dive
install_dive() {
    log "info" "Installing dive..."
    install_from_zip "dive" "$DIVE_URL" "dive.exe"
}

# Install GitHub CLI
install_gh() {
    log "info" "Installing GitHub CLI..."
    install_from_zip "gh" "$GH_URL" "gh.exe"
}

# Install kind
install_kind() {
    log "info" "Installing kind..."
    install_single_binary "kind.exe" "$KIND_URL"
}

# Install pandoc
install_pandoc() {
    log "info" "Installing pandoc..."
    
    local pandoc_dir="$TEMP_DIR/pandoc"
    local pandoc_zip="$TEMP_DIR/pandoc.zip"
    
    # Skip if already installed
    if [ -f "$BIN_DIR/pandoc.exe" ]; then
        log "success" "pandoc is already installed"
        return 0
    fi
    
    # Download the zip
    download_file "$PANDOC_URL" "$pandoc_zip" || return 1
    
    # Extract the zip
    extract_zip "$pandoc_zip" "$pandoc_dir" || return 1
    
    # Find the binary in the extracted directory
    local pandoc_exe=$(find "$pandoc_dir" -name "pandoc.exe" -type f | head -1)
    
    if [ -z "$pandoc_exe" ]; then
        log "error" "Could not find pandoc.exe in extracted files"
        return 1
    fi
    
    # Copy to bin directory
    cp "$pandoc_exe" "$BIN_DIR/pandoc.exe"
    chmod +x "$BIN_DIR/pandoc.exe"
    
    # Clean up
    rm -f "$pandoc_zip"
    rm -rf "$pandoc_dir"
    
    log "success" "pandoc installed successfully"
}

# Install bat (better cat)
install_bat() {
    log "info" "Installing bat..."
    install_from_zip "bat" "$BAT_URL" "bat.exe"
}

# Install fd (better find)
install_fd() {
    log "info" "Installing fd..."
    install_from_zip "fd" "$FD_URL" "fd.exe"
}

# Install ripgrep (better grep)
install_ripgrep() {
    log "info" "Installing ripgrep..."
    install_from_zip "ripgrep" "$RIPGREP_URL" "rg.exe"
}

# Install fzf (fuzzy finder)
install_fzf() {
    log "info" "Installing fzf..."
    install_from_zip "fzf" "$FZF_URL" "fzf.exe"
}

# Install Helm
install_helm() {
    log "info" "Installing Helm..."
    install_from_zip "helm" "$HELM_URL" "helm.exe"
}

# Main function
main() {
    log "info" "Starting CLI tools installation..."
    
    # Create directories
    mkdir -p "$BIN_DIR"
    create_temp_dir
    
    # Install tools
    install_jq
    install_yq
    install_kubectl
    install_k9s
    install_age
    install_dive
    install_gh
    install_kind
    install_pandoc
    install_bat
    install_fd
    install_ripgrep
    install_fzf
    install_helm
    
    # Clean up temp directory
    rm -rf "$TEMP_DIR"
    
    log "success" "CLI tools installation complete"
}

# Run the main function
main
