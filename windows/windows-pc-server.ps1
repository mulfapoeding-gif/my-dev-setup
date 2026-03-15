# Windows PC AI Agent Server
# Run this on your Windows 10 PC to expose AI agents to Termux

param(
    [string]$Port = "11434",
    [string]$SyncPort = "8080",
    [switch]$Install
)

$ErrorActionPreference = "Stop"

# Colors
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[OK] $args" -ForegroundColor Green }
function Write-Warn { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Error-Custom { Write-Host "[ERROR] $args" -ForegroundColor Red }

# Check if running as admin
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Install Ollama for Windows
function Install-Ollama {
    Write-Info "Downloading Ollama for Windows..."
    $installer = "$env:TEMP\OllamaSetup.exe"
    Invoke-WebRequest -Uri "https://ollama.com/download/OllamaSetup.exe" -OutFile $installer
    Write-Info "Installing Ollama..."
    Start-Process -FilePath $installer -Wait
    Write-Success "Ollama installed"
}

# Configure Ollama to listen on network
function Configure-Ollama-Network {
    Write-Info "Configuring Ollama for network access..."
    
    # Set OLLAMA_HOST environment variable
    $env:OLLAMA_HOST = "0.0.0.0:11434"
    [Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0:11434", "User")
    
    # Restart Ollama service
    Write-Info "Restarting Ollama service..."
    Stop-Process -Name "ollama" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Start-Process "ollama" -ArgumentList "serve"
    
    Write-Success "Ollama configured for network access"
}

# Pull models
function Pull-Models {
    param(
        [string[]]$Models = @("qwen2.5-coder:1.5b", "qwen2.5-coder:7b")
    )
    
    foreach ($model in $Models) {
        Write-Info "Pulling model: $model"
        ollama pull $model
    }
    Write-Success "Models pulled"
}

# Configure Windows Firewall
function Configure-Firewall {
    Write-Info "Configuring Windows Firewall..."
    
    # Allow Ollama port
    $ruleName = "Ollama API"
    if (-not (Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -LocalPort 11434 -Protocol TCP -Action Allow
        Write-Info "Firewall rule created for port 11434"
    }
    
    # Allow sync port
    $ruleName = "Termux Sync"
    if (-not (Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -LocalPort $SyncPort -Protocol TCP -Action Allow
        Write-Info "Firewall rule created for port $SyncPort"
    }
    
    Write-Success "Firewall configured"
}

# Get local IP address
function Get-LocalIP {
    $ip = Get-NetIPAddress -AddressFamily IPv4 | 
          Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -like "192.168.*" } |
          Select-Object -First 1 -ExpandProperty IPAddress
    if (-not $ip) {
        $ip = Get-NetIPAddress -AddressFamily IPv4 | 
              Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } |
              Select-Object -First 1 -ExpandProperty IPAddress
    }
    return $ip
}

# Create sync server (simple HTTP server for file sync)
function Start-SyncServer {
    param(
        [string]$Port = "8080",
        [string]$RootPath = "$env:USERPROFILE\termux-sync"
    )
    
    if (-not (Test-Path $RootPath)) {
        New-Item -ItemType Directory -Path $RootPath -Force
    }
    
    Write-Info "Starting sync server on port $Port..."
    Write-Info "Root path: $RootPath"
    
    # Create simple HTTP server script
    $serverScript = @"
using System;
using System.IO;
using System.Net;
using System.Threading.Tasks;

class SyncServer {
    static string rootPath = "$RootPath";
    static int port = $Port;
    
    static async Task Main() {
        var listener = new HttpListener();
        listener.Prefixes.Add($"http://+:{port}/");
        listener.Start();
        Console.WriteLine($"Sync server listening on http://*:{port}/");
        Console.WriteLine($"Root: {rootPath}");
        
        while (true) {
            var context = await listener.GetContextAsync();
            _ = HandleRequest(context);
        }
    }
    
    static async Task HandleRequest(HttpListenerContext context) {
        var request = context.Request;
        var response = context.Response;
        
        try {
            if (request.HttpMethod == "GET") {
                var filePath = Path.Combine(rootPath, request.Url.AbsolutePath.TrimStart('/'));
                if (File.Exists(filePath)) {
                    var content = await File.ReadAllBytesAsync(filePath);
                    response.ContentType = "application/octet-stream";
                    response.ContentLength64 = content.Length;
                    response.AddHeader("Content-Disposition", $"attachment; filename={Path.GetFileName(filePath)}");
                    await response.OutputStream.WriteAsync(content, 0, content.Length);
                } else {
                    response.StatusCode = 404;
                }
            } else if (request.HttpMethod == "POST") {
                var filePath = Path.Combine(rootPath, request.Url.AbsolutePath.TrimStart('/'));
                Directory.CreateDirectory(Path.GetDirectoryName(filePath));
                using (var fs = File.Create(filePath)) {
                    await request.InputStream.CopyToAsync(fs);
                }
                response.StatusCode = 200;
            }
        } catch (Exception ex) {
            response.StatusCode = 500;
            Console.WriteLine($"Error: {ex.Message}");
        }
        
        response.Close();
    }
}
"@
    
    Write-Warn "Sync server script created. Run manually or use alternative sync method."
}

# Generate SSH key for Termux
function Generate-SSHKey {
    Write-Info "Generating SSH key for Termux..."
    
    $sshDir = "$env:USERPROFILE\.ssh"
    if (-not (Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir -Force
    }
    
    $keyPath = "$sshDir\termux_id_rsa"
    
    if (Test-Path $keyPath) {
        Write-Warn "SSH key already exists"
        return
    }
    
    # Use ssh-keygen if available
    if (Get-Command ssh-keygen -ErrorAction SilentlyContinue) {
        ssh-keygen -t ed25519 -f $keyPath -N "" -C "termux@android"
        Write-Success "SSH key generated: $keyPath"
        Write-Info "Public key: $keyPath.pub"
        Write-Info "Copy this to Termux ~/.ssh/authorized_keys"
        Get-Content "$keyPath.pub"
    } else {
        Write-Warn "ssh-keygen not found. Install OpenSSH or use alternative method."
    }
}

# Main setup
function Main {
    Write-Host @"
========================================
  Windows PC AI Agent Server Setup
========================================

This will set up your Windows PC to:
1. Install Ollama for local AI models
2. Configure network access for Termux
3. Set up file sync server
4. Generate SSH keys

"@ -ForegroundColor Cyan

    if ($Install) {
        # Check admin rights
        if (-not (Test-Admin)) {
            Write-Warn "Please run as Administrator for full functionality"
        }
        
        # Install Ollama
        if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
            Install-Ollama
        } else {
            Write-Success "Ollama already installed"
        }
        
        # Configure network
        Configure-Ollama-Network
        
        # Configure firewall
        Configure-Firewall
        
        # Pull models
        Pull-Models
        
        # Generate SSH key
        Generate-SSHKey
        
        # Get IP
        $ip = Get-LocalIP
        Write-Host @"

========================================
  Setup Complete!
========================================

Your PC IP Address: $ip

Termux Configuration:
- Ollama endpoint: http://$ip`:11434
- Sync server: http://$ip`:8080

Add to Termux ~/.qwen/settings.json:
{
  "modelProviders": {
    "openai": [
      {
        "id": "pc-ollama",
        "name": "PC Ollama (Windows)",
        "baseUrl": "http://$ip`:11434/v1",
        "generationConfig": { "contextWindowSize": 32768 }
      }
    ]
  }
}

To start the server again, run:
  .\windows-pc-server.ps1

"@ -ForegroundColor Green
    } else {
        Write-Info "Run with -Install flag to set up: .\windows-pc-server.ps1 -Install"
        Write-Info "Or run: .\windows-pc-server.ps1 -Help for more options"
    }
}

Main
