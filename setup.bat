@echo off
setlocal enabledelayedexpansion

echo ======================================================
echo Windows Developer Environment Setup
echo ======================================================
echo This script will set up a complete developer environment
echo without requiring administrator privileges.
echo.
echo It will create the following structure:
echo \dev\tools\bin       - Single binary tools and symlinks
echo \dev\tools           - All installed tools (Git, Node, Python, etc.)
echo \dev\code\remote     - For cloned repositories
echo \dev\code\local      - For local projects
echo \dev\scripts         - For utility scripts
echo.
echo All tools will be installed to \dev\tools without admin rights
echo Git Bash will be configured as the default shell
echo.
echo You can customize which tools to install by setting options
echo in the file dev_setup_options.json after initial Git setup.
echo.
echo ======================================================

:: Check if running from an admin prompt (not required and potentially problematic)
net session >nul 2>&1
if %errorlevel% == 0 (
    echo WARNING: You are running this script as administrator.
    echo This script is designed to work without admin privileges.
    echo.
    echo Press Ctrl+C to abort or any key to continue anyway...
    pause >nul
)

:: Create base directory structure
echo Creating directory structure...
if not exist "%USERPROFILE%\dev" mkdir "%USERPROFILE%\dev"
if not exist "%USERPROFILE%\dev\tools" mkdir "%USERPROFILE%\dev\tools"
if not exist "%USERPROFILE%\dev\tools\bin" mkdir "%USERPROFILE%\dev\tools\bin"
if not exist "%USERPROFILE%\dev\code" mkdir "%USERPROFILE%\dev\code"
if not exist "%USERPROFILE%\dev\code\remote" mkdir "%USERPROFILE%\dev\code\remote"
if not exist "%USERPROFILE%\dev\code\local" mkdir "%USERPROFILE%\dev\code\local"
if not exist "%USERPROFILE%\dev\scripts" mkdir "%USERPROFILE%\dev\scripts"

:: Check if we have tools to download files
where curl >nul 2>&1
if %errorlevel% neq 0 (
    echo curl is not available, attempting to use PowerShell...
    where powershell >nul 2>&1
    if %errorlevel% neq 0 (
        echo Error: Neither curl nor PowerShell is available.
        echo Cannot download Git for Windows.
        goto :error
    )
)

:: Download and extract portable Git
echo Downloading Git for Windows portable...
set GIT_URL=https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/PortableGit-2.44.0-64-bit.7z.exe
set GIT_PORTABLE="%USERPROFILE%\dev\tools\PortableGit.7z.exe"

where curl >nul 2>&1
if %errorlevel% equ 0 (
    curl -L %GIT_URL% -o %GIT_PORTABLE%
) else (
    powershell -Command "& {Invoke-WebRequest -Uri '%GIT_URL%' -OutFile %GIT_PORTABLE%}"
)

if not exist %GIT_PORTABLE% (
    echo Failed to download Git for Windows
    goto :error
)

echo Extracting Git for Windows portable...
%GIT_PORTABLE% -y -o"%USERPROFILE%\dev\tools\git"
if %errorlevel% neq 0 (
    echo Failed to extract Git for Windows
    goto :error
)

:: Copy this batch file and all scripts to the dev\scripts directory
echo Copying scripts to dev\scripts directory...
copy "%~f0" "%USERPROFILE%\dev\scripts\" >nul

:: Copy the dev_setup.sh script to the appropriate location
set SCRIPT_DIR=%~dp0
if exist "%SCRIPT_DIR%dev_setup.sh" (
    copy "%SCRIPT_DIR%dev_setup.sh" "%USERPROFILE%\dev\scripts\" >nul
)

:: Copy tools directory if it exists
if exist "%SCRIPT_DIR%tools" (
    if not exist "%USERPROFILE%\dev\scripts\tools" mkdir "%USERPROFILE%\dev\scripts\tools"
    xcopy /E /Y "%SCRIPT_DIR%tools\*" "%USERPROFILE%\dev\scripts\tools\" >nul
)

:: Copy config directory if it exists
if exist "%SCRIPT_DIR%config" (
    if not exist "%USERPROFILE%\dev\scripts\config" mkdir "%USERPROFILE%\dev\scripts\config"
    xcopy /E /Y "%SCRIPT_DIR%config\*" "%USERPROFILE%\dev\scripts\config\" >nul
)

:: Set Git environment variables and launch Git Bash with the setup script
echo Launching Git Bash to continue setup...
set HOME=%USERPROFILE%
"%USERPROFILE%\dev\tools\git\bin\bash.exe" --login -i -c "cd '%USERPROFILE%/dev/scripts' && ./dev_setup.sh"

if %errorlevel% neq 0 (
    echo An error occurred during the bash setup script.
    goto :error
)

echo.
echo Setup completed successfully!
echo.
echo To use your new development environment:
echo 1. Launch Git Bash from the Start Menu
echo 2. All tools are installed in %USERPROFILE%\dev\tools
echo 3. Single executables are in %USERPROFILE%\dev\tools\bin
echo.
echo Enjoy your new development environment!
goto :end

:error
echo.
echo Setup failed. Please check the error messages above.
exit /b 1

:end
exit /b 0
