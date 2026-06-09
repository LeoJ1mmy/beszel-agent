@echo off
setlocal EnableDelayedExpansion
title Beszel Agent Installer

echo ============================================
echo   Beszel Agent Installer
echo ============================================
echo.

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This installer requires Administrator privileges.
    echo Please right-click and select "Run as administrator".
    echo.
    pause
    exit /b 1
)

set INSTALL_DIR=%ProgramFiles%\beszel-agent
set BIN=%INSTALL_DIR%\beszel-agent.exe
set ENV_FILE=%INSTALL_DIR%\beszel-agent.env
set SERVICE_NAME=beszel-agent

:: Collect configuration
echo Please enter the following values from your Beszel Hub:
echo (Settings -> Add System)
echo.

set /p HUB_URL="Hub URL (e.g. https://monitor.example.com): "
if "!HUB_URL!"=="" (
    echo [ERROR] Hub URL cannot be empty.
    pause
    exit /b 1
)

set /p TOKEN="Token: "
if "!TOKEN!"=="" (
    echo [ERROR] Token cannot be empty.
    pause
    exit /b 1
)

set /p KEY="Public Key: "
if "!KEY!"=="" (
    echo [ERROR] Public Key cannot be empty.
    pause
    exit /b 1
)

echo.
echo Installing to: %INSTALL_DIR%
echo.

:: Create install directory
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

:: Copy binary
if not exist "beszel-agent.exe" (
    echo [ERROR] beszel-agent.exe not found. Make sure install.bat is in the same folder as beszel-agent.exe
    pause
    exit /b 1
)
copy /y "beszel-agent.exe" "%BIN%" >nul

:: Write env file
(
    echo HUB_URL=%HUB_URL%
    echo TOKEN=%TOKEN%
    echo KEY=%KEY%
) > "%ENV_FILE%"

:: Remove existing service if present
sc query %SERVICE_NAME% >nul 2>&1
if %errorLevel% equ 0 (
    echo Stopping existing service...
    sc stop %SERVICE_NAME% >nul 2>&1
    timeout /t 2 /nobreak >nul
    sc delete %SERVICE_NAME% >nul 2>&1
    timeout /t 1 /nobreak >nul
)

:: Create Windows service using NSSM if available, otherwise use sc.exe with a wrapper
where nssm >nul 2>&1
if %errorLevel% equ 0 (
    echo Installing service via NSSM...
    nssm install %SERVICE_NAME% "%BIN%"
    nssm set %SERVICE_NAME% AppEnvironmentExtra "HUB_URL=%HUB_URL%" "TOKEN=%TOKEN%" "KEY=%KEY%"
    nssm set %SERVICE_NAME% Description "Beszel monitoring agent"
    nssm set %SERVICE_NAME% Start SERVICE_AUTO_START
) else (
    echo Installing service via sc.exe...
    :: Create a launcher script that loads env vars
    set LAUNCHER=%INSTALL_DIR%\launch.bat
    (
        echo @echo off
        echo for /f "tokens=1,2 delims==" %%%%a in ^("%ENV_FILE%"^) do set "%%%%a=%%%%b"
        echo "%BIN%"
    ) > "!LAUNCHER!"

    :: Use sc.exe to create the service
    sc create %SERVICE_NAME% binPath= "cmd.exe /c \"%INSTALL_DIR%\launch.bat\"" start= auto DisplayName= "Beszel Agent"
    sc description %SERVICE_NAME% "Beszel monitoring agent"
)

:: Start the service
echo.
echo Starting service...
sc start %SERVICE_NAME% >nul 2>&1
timeout /t 2 /nobreak >nul

sc query %SERVICE_NAME% | find "RUNNING" >nul 2>&1
if %errorLevel% equ 0 (
    echo.
    echo [SUCCESS] Beszel Agent installed and running!
    echo.
    echo Service name : %SERVICE_NAME%
    echo Install path : %INSTALL_DIR%
    echo Config file  : %ENV_FILE%
    echo.
    echo To check status : sc query beszel-agent
    echo To stop         : sc stop beszel-agent
    echo To uninstall    : sc stop beszel-agent ^&^& sc delete beszel-agent
) else (
    echo.
    echo [WARNING] Service installed but may not be running yet.
    echo Check Windows Event Viewer or run: sc query beszel-agent
)

echo.
pause
