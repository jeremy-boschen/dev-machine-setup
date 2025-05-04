# Windows Developer Environment Setup

A comprehensive, non-admin Windows developer environment setup script that installs all tools to `\dev\tools\` without requiring administrator privileges. This project standardizes development tools and configurations using portable software and custom installation paths.

## Features

- **Zero Administrator Privileges Required**: All tools install to user-accessible directories
- **Standardized Directory Structure**: Organized folders for tools, code, and scripts
- **Multi-Version Language Support**: Install and manage multiple versions of Node.js, Python, etc.
- **Customizable Installation**: Configure which tools to install via a simple JSON file
- **Git Bash Integration**: Pre-configured Git Bash as the primary terminal with useful aliases and functions
- **Portable Design**: Tools are installed in portable mode wherever possible

## Directory Structure

The script creates the following directory structure:

```
\dev
  \tools         - All installed developer tools
    \bin         - Symlinks to executables for PATH integration
    \nodejs      - Multiple Node.js versions
      \node-v18.16.1
      \node-v20.5.1
    \python      - Multiple Python versions
      \Python3114
      \Python3913
    \git         - Git installation
    \sublime_text - Sublime Text (if selected)
    \notepad++   - Notepad++ (if selected)
    \rust        - Rust installation (if selected)
    \sdkman      - SDKMAN! for Java tools (if selected)
  \code
    \remote      - For cloned repositories
    \local       - For local projects
  \scripts       - Utility scripts
```

## Installed Tools

### CLI Tools (Customizable)

- **Git**: Version control with pre-configured aliases and settings
- **Core Utils**: jq, yq, bat, fd, ripgrep, fzf
- **Kubernetes**: kubectl, k9s, kind, helm
- **Other**: age, dive, gh (GitHub CLI), pandoc

### Programming Languages (Customizable)

- **Node.js**: Multiple versions (configurable)
- **Python**: Multiple versions (configurable)
- **Rust**: Latest version via rustup
- **Java**: Via SDKMAN! (version configurable)

### Text Editors (Customizable)

- **Sublime Text**: Portable installation
- **Notepad++**: Portable installation

### Terminal

- **Git Bash**: Pre-configured with useful aliases and functions
- **Windows Terminal**: Optional installation (requires manual setup)

## Quick Start

1. **Download the Setup Files**:
   - Clone this repository or download as a ZIP file

2. **Run the Setup Script**:
   - Double-click `setup.bat` in the project folder
   - The script will install Git, then launch Git Bash to complete the setup

3. **Customize Your Installation** (Optional):
   - After Git is installed, the script creates `dev_setup_options.json`
   - Edit this file to select which tools to install
   - Re-run `dev_setup.sh` in Git Bash to apply changes

4. **Use Your New Environment**:
   - Launch Git Bash from the Start Menu
   - All tools are available in your PATH

## Customization Options

Edit the `dev_setup_options.json` file to customize your installation:

```json
{
  "cli_tools": {
    "install": true,
    "tools": {
      "jq": true,
      "yq": true,
      "kubectl": true,
      "k9s": true,
      "age": true,
      "dive": true,
      "gh": true,
      "kind": true,
      "pandoc": true,
      "bat": true,
      "fd": true,
      "ripgrep": true,
      "fzf": true,
      "helm": true
    }
  },
  "languages": {
    "install": true,
    "node": {
      "install": true,
      "versions": [
        {
          "version": "18.16.1",
          "default": true
        },
        {
          "version": "20.5.1",
          "default": false
        }
      ]
    },
    "python": {
      "install": true,
      "versions": [
        {
          "version": "3.11.4",
          "default": true
        },
        {
          "version": "3.9.13",
          "default": false
        }
      ]
    },
    "rust": {
      "install": true
    },
    "sdkman": {
      "install": true,
      "java": {
        "install": true,
        "version": "17.0.7-tem"
      }
    }
  },
  "editors": {
    "install": true,
    "sublime_text": true,
    "notepad_plus_plus": true,
    "vscode": false
  },
  "terminal": {
    "install": true,
    "windows_terminal": true
  },
  "git": {
    "user": {
      "name": "",
      "email": ""
    },
    "configure": true
  }
}
```

## Included Shell Aliases and Functions

The environment comes pre-configured with many useful aliases and functions:

### Git Aliases
- `g` - git
- `gs` - git status
- `ga` - git add
- `gc` - git commit
- `gp` - git push
- `gl` - git pull
- `glog` - pretty git log
- `gd` - git diff

### Navigation Aliases
- `..`, `...`, `....` - navigate up directories
- `dev` - cd to dev directory
- `code` - cd to code directory
- `tools` - cd to tools directory

### Development Aliases
- `nr` - npm run
- `ni` - npm install
- `pi` - pip install
- `k` - kubectl
- `py` - python
- `tf` - terraform
- `serve` - start a simple HTTP server

### Utility Functions
- `mkcd` - create directory and cd into it
- `extract` - extract various archive formats
- `findfile` - find file by pattern
- `findtext` - search for text in files
- `backup` - create a backup of a file
- `gitnew` - initialize a new git repository
- `clone` - clone a repository and cd into it
- `project` - create a new project structure (node/python/web)

## Manual Installations

Some tools require manual steps after the script runs:

- **Windows Terminal**: The script downloads the MSIX package, but you need to install it manually
- **VS Code**: Currently not supported (planned for future)

## Requirements

- Windows 10 or 11
- Internet connection
- No administrator privileges needed

## Troubleshooting

### Common Issues

1. **Download Failures**: Check your internet connection or try running the script again
2. **Path Too Long**: Windows has path length limitations; try installing to a shorter base path
3. **Tool Not Found**: Make sure to start a new Git Bash session after installation

### Log Files

The script creates log files in the `dev/scripts` directory that can help diagnose issues:
- `dev_setup.log` - Main setup log
- `tools_install.log` - Individual tool installation logs

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- Git for Windows
- MSYS2/MinGW
- All the amazing open-source projects that make this possible