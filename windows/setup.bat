@echo off
REM Quick setup script for Windows PC
REM Run this as Administrator

echo ========================================
echo   Windows PC AI Agent - Quick Setup
echo ========================================
echo.

REM Check if running as admin
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [WARN] Please run as Administrator
    echo Right-click this file and select "Run as administrator"
    pause
    exit /b 1
)

REM Install Ollama
echo [INFO] Checking Ollama installation...
where ollama >nul 2>&1
if %errorLevel% neq 0 (
    echo [INFO] Downloading Ollama...
    curl -L https://ollama.com/download/OllamaSetup.exe -o "%TEMP%\OllamaSetup.exe"
    echo [INFO] Installing Ollama...
    "%TEMP%\OllamaSetup.exe" /S
) else (
    echo [OK] Ollama already installed
)

REM Configure environment variable
echo [INFO] Configuring Ollama for network access...
setx OLLAMA_HOST "0.0.0.0:11434"
echo [OK] OLLAMA_HOST set to 0.0.0.0:11434

REM Configure firewall
echo [INFO] Configuring Windows Firewall...
netsh advfirewall firewall add rule name="Ollama API" dir=in action=allow protocol=TCP localport=11434 >nul 2>&1
netsh advfirewall firewall add rule name="Termux Sync" dir=in action=allow protocol=TCP localport=8080 >nul 2>&1
echo [OK] Firewall rules configured

REM Get IP address
echo.
echo [INFO] Getting local IP address...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4" ^| findstr /v "169"') do (
    for /f "tokens=*" %%b in ("%%a") do (
        set PC_IP=%%b
        goto :found
    )
)
:found
echo [OK] PC IP Address: %PC_IP%

REM Pull default model
echo.
echo [INFO] Pulling default model (qwen2.5-coder:1.5b)...
ollama pull qwen2.5-coder:1.5b

echo.
echo ========================================
echo   Setup Complete!
echo ========================================
echo.
echo Your PC IP Address: %PC_IP%
echo.
echo On Termux, configure:
echo   - Ollama endpoint: http://%PC_IP%:11434
echo   - Run: ./termux-pc-sync.sh --setup
echo.
echo To start Ollama server:
echo   ollama serve
echo.
pause
