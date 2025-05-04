#!/usr/bin/env bash

# Main development environment setup script
# This script orchestrates the setup of all developer tools

# Set strict error handling
set -euo pipefail

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define paths
DEV_DIR="$HOME/dev"
TOOLS_DIR="$DEV_DIR/tools"
BIN_DIR="$TOOLS_DIR/bin"
CODE_DIR="$DEV_DIR/code"
SCRIPTS_DIR="$DEV_DIR/scripts"
CONFIG_DIR="$SCRIPTS_DIR/config"
TOOLS_SCRIPTS_DIR="$SCRIPTS_DIR/tools"
OPTIONS_FILE="$CONFIG_DIR/dev_setup_options.json"

# Default options if the file doesn't exist
DEFAULT_OPTIONS='{
  "cli_tools": {
    "install": true
  },
  "languages": {
    "install": true,
    "node": {
      "install": true
    },
    "python": {
      "install": true
    },
    "rust": {
      "install": true
    },
    "sdkman": {
      "install": true
    }
  },
  "editors": {
    "install": true
  },
  "terminal": {
    "install": true
  },
  "git": {
    "configure": true
  }
}'

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

# Function to create the directory structure
create_directory_structure() {
    log "info" "Ensuring directory structure exists..."
    
    mkdir -p "$BIN_DIR"
    mkdir -p "$CODE_DIR/remote"
    mkdir -p "$CODE_DIR/local"
    mkdir -p "$SCRIPTS_DIR"
    
    log "success" "Directory structure created"
}

# Function to ensure scripts are executable
ensure_executable() {
    if [[ -d "$TOOLS_SCRIPTS_DIR" ]]; then
        chmod +x "$TOOLS_SCRIPTS_DIR"/*.sh
    fi
    chmod +x "$SCRIPTS_DIR/dev_setup.sh"
}

# Function to update .bashrc
setup_bashrc() {
    log "info" "Setting up .bashrc..."
    
    if [[ -f "$CONFIG_DIR/bashrc.template" ]]; then
        # Backup existing .bashrc if it exists
        if [[ -f "$HOME/.bashrc" ]]; then
            cp "$HOME/.bashrc" "$HOME/.bashrc.backup.$(date +%Y%m%d%H%M%S)"
            log "info" "Backed up existing .bashrc"
        fi
        
        # Create or update .bashrc
        cp "$CONFIG_DIR/bashrc.template" "$HOME/.bashrc"
        log "success" "Updated .bashrc"
    else
        log "error" "bashrc.template not found in $CONFIG_DIR"
    fi
}

# Function to update .gitconfig
setup_gitconfig() {
    log "info" "Setting up Git config..."
    
    # Check if Git configuration is enabled
    if [[ "$(get_option ".git.configure")" != "true" ]]; then
        log "info" "Git configuration is disabled in options, skipping"
        return 0
    fi
    
    if [[ -f "$CONFIG_DIR/gitconfig.template" ]]; then
        # Get stored values if available
        local git_user_name="$(get_option ".git.user.name")"
        local git_user_email="$(get_option ".git.user.email")"
        
        # Ask for user input if not stored
        if [[ -z "$git_user_name" ]]; then
            echo "Please enter your Git user name:"
            read -r git_user_name
        fi
        
        if [[ -z "$git_user_email" ]]; then
            echo "Please enter your Git email:"
            read -r git_user_email
        fi
        
        # Replace placeholders in the template
        sed -e "s/{{GIT_USER_NAME}}/$git_user_name/g" \
            -e "s/{{GIT_USER_EMAIL}}/$git_user_email/g" \
            "$CONFIG_DIR/gitconfig.template" > "$HOME/.gitconfig"
        
        log "success" "Git configuration complete"
    else
        log "warning" "gitconfig.template not found, skipping Git config setup"
    fi
}

# Function to load options from file
load_options() {
    log "info" "Loading configuration options..."
    
    # Check if options file exists
    if [[ -f "$OPTIONS_FILE" ]]; then
        log "info" "Using options from $OPTIONS_FILE"
        OPTIONS="$(cat "$OPTIONS_FILE")"
    else
        log "warning" "Options file not found, using default options"
        OPTIONS="$DEFAULT_OPTIONS"
        
        # Create options file with default options
        mkdir -p "$(dirname "$OPTIONS_FILE")"
        echo "$DEFAULT_OPTIONS" > "$OPTIONS_FILE"
        log "info" "Created default options file at $OPTIONS_FILE"
    fi
    
    # Verify we have jq installed
    if ! command -v jq &> /dev/null; then
        log "info" "jq is not available, loading default options"
        return
    fi
    
    # Validate JSON format
    if ! echo "$OPTIONS" | jq '.' &> /dev/null; then
        log "warning" "Invalid JSON in options file, using default options"
        OPTIONS="$DEFAULT_OPTIONS"
    fi
}

# Function to get an option value using jq
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

# Function to update PATH in the current session
update_path() {
    log "info" "Updating PATH for the current session..."
    
    # Define directories to add to PATH
    paths_to_add=(
        "$BIN_DIR"
        "$TOOLS_DIR/git/bin"
        "$TOOLS_DIR/sublime_text"
        "$TOOLS_DIR/notepad++"
        "$TOOLS_DIR/node/bin"
        "$TOOLS_DIR/python"
        "$TOOLS_DIR/python/Scripts"
    )
    
    # Add each directory to PATH if it exists
    for dir in "${paths_to_add[@]}"; do
        if [[ -d "$dir" && ! ":$PATH:" == *":$dir:"* ]]; then
            export PATH="$dir:$PATH"
        fi
    done
    
    log "success" "PATH updated for current session"
}

# Function to verify installed tools
verify_installations() {
    log "info" "Verifying installed tools..."
    
    # Check for Git
    if command -v git &> /dev/null; then
        log "success" "Git installed: $(git --version)"
    else
        log "error" "Git installation failed"
    fi
    
    # Check for CLI tools
    log "info" "Checking CLI tools..."
    cli_tools=(
        "jq"
        "yq"
        "kubectl"
        "k9s"
        "age"
        "dive"
        "gh"
        "kind"
        "pandoc"
        "bat"
        "fd"
        "rg"
        "fzf"
        "helm"
    )
    
    for tool in "${cli_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log "success" "$tool installed and in PATH"
        else
            log "warning" "$tool not found in PATH"
        fi
    done
    
    # Check for programming languages
    log "info" "Checking programming languages..."
    lang_tools=(
        "node"
        "npm"
        "yarn"
        "python"
        "pip"
        "rustc"
        "cargo"
        "rustup"
    )
    
    for tool in "${lang_tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log "success" "$tool installed: $($tool --version 2>&1 | head -n 1)"
        else
            log "warning" "$tool not found in PATH"
        fi
    done
    
    # Check for editors
    log "info" "Checking text editors..."
    editors=(
        "sublime_text"
        "notepad++"
    )
    
    for editor in "${editors[@]}"; do
        if [ -f "$TOOLS_DIR/$editor/$editor.exe" ]; then
            log "success" "$editor installed at $TOOLS_DIR/$editor/$editor.exe"
        else
            log "warning" "$editor not found"
        fi
    done
    
    # Check SDKMAN
    if [ -f "$TOOLS_DIR/sdkman/bin/sdkman-init.sh" ]; then
        log "success" "SDKMAN installed at $TOOLS_DIR/sdkman"
    else
        log "warning" "SDKMAN not found"
    fi
    
    # Check PATH setup
    log "info" "Checking PATH environment..."
    if [[ ":$PATH:" == *":$BIN_DIR:"* ]]; then
        log "success" "bin directory is in PATH"
    else
        log "warning" "bin directory is not in PATH"
    fi
}

# Check if required scripts exist before proceeding
check_required_scripts() {
    local missing_scripts=0
    
    if [[ ! -f "$TOOLS_SCRIPTS_DIR/install_git.sh" ]]; then
        log "error" "Missing script: install_git.sh"
        missing_scripts=$((missing_scripts + 1))
    fi
    
    if [[ ! -f "$TOOLS_SCRIPTS_DIR/install_editors.sh" ]]; then
        log "error" "Missing script: install_editors.sh"
        missing_scripts=$((missing_scripts + 1))
    fi
    
    if [[ ! -f "$TOOLS_SCRIPTS_DIR/install_cli_tools.sh" ]]; then
        log "error" "Missing script: install_cli_tools.sh"
        missing_scripts=$((missing_scripts + 1))
    fi
    
    if [[ ! -f "$TOOLS_SCRIPTS_DIR/install_languages.sh" ]]; then
        log "error" "Missing script: install_languages.sh"
        missing_scripts=$((missing_scripts + 1))
    fi
    
    if [[ ! -f "$TOOLS_SCRIPTS_DIR/install_terminal.sh" ]]; then
        log "error" "Missing script: install_terminal.sh"
        missing_scripts=$((missing_scripts + 1))
    fi
    
    if [[ $missing_scripts -gt 0 ]]; then
        log "error" "Missing $missing_scripts required script(s). Cannot continue."
        exit 1
    fi
}

# Main setup function
main() {
    log "info" "Starting developer environment setup..."
    
    # Create directories
    create_directory_structure
    
    # Make all scripts executable
    ensure_executable
    
    # Check for required scripts
    check_required_scripts
    
    # Load options
    load_options
    
    # Git is already installed via portable Git, but run the script for additional config
    log "info" "Running Git setup and configuration..."
    bash "$TOOLS_SCRIPTS_DIR/install_git.sh" --options-file="$OPTIONS_FILE"
    
    # Install Windows Terminal if enabled
    if [[ "$(get_option ".terminal.install")" == "true" ]]; then
        log "info" "Installing Windows Terminal..."
        bash "$TOOLS_SCRIPTS_DIR/install_terminal.sh" --options-file="$OPTIONS_FILE"
    else
        log "info" "Terminal installation disabled in options, skipping"
    fi
    
    # Install text editors if enabled
    if [[ "$(get_option ".editors.install")" == "true" ]]; then
        log "info" "Installing text editors..."
        bash "$TOOLS_SCRIPTS_DIR/install_editors.sh" --options-file="$OPTIONS_FILE"
    else
        log "info" "Editors installation disabled in options, skipping"
    fi
    
    # Install CLI tools if enabled
    if [[ "$(get_option ".cli_tools.install")" == "true" ]]; then
        log "info" "Installing CLI tools..."
        bash "$TOOLS_SCRIPTS_DIR/install_cli_tools.sh" --options-file="$OPTIONS_FILE"
    else
        log "info" "CLI tools installation disabled in options, skipping"
    fi
    
    # Install programming languages and package managers if enabled
    if [[ "$(get_option ".languages.install")" == "true" ]]; then
        log "info" "Installing programming languages and package managers..."
        bash "$TOOLS_SCRIPTS_DIR/install_languages.sh" --options-file="$OPTIONS_FILE"
    else
        log "info" "Languages installation disabled in options, skipping"
    fi
    
    # Set up .bashrc and .gitconfig
    setup_bashrc
    setup_gitconfig
    
    # Update PATH for the current session
    update_path
    
    # Verify all installations
    verify_installations
    
    # Inform user about options file
    log "info" "Setup complete! To customize tool installations, edit $OPTIONS_FILE"
    log "info" "And then run this script again to apply changes."
    
    log "success" "Developer environment setup complete!"
    log "info" "Please start a new Git Bash session to use your new environment."
}

# Run the main function
main
