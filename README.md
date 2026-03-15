# My Development Setup

A complete development environment configuration for Termux/Android, Windows PC, and Linux systems.

## Features

- **Sync Termux with Windows PC** - Use your PC's AI models from Termux
- **Complete backup solution** - Backup and restore entire Termux environment
- **AI Coding Assistants** - Qwen Code, Gemini CLI, Ollama
- **Development Tools** - Node.js, Go, Python, Metasploit, APK tools
- **Cross-platform** - Works on Termux, Windows, Kali, and Linux

## Quick Start

### For Termux (Android)

```bash
# Clone and setup
git clone https://github.com/YOUR_USERNAME/my-dev-setup.git
cd my-dev-setup
./setup-termux.sh
```

### For Windows PC (AI Server)

```powershell
# Run PowerShell as Administrator
cd my-dev-setup\windows
.\windows-pc-server.ps1 -Install
```

### For Kali Linux

```bash
git clone https://github.com/YOUR_USERNAME/my-dev-setup.git
cd my-dev-setup
./setup-kali.sh
```

## Termux-PC Sync

### Architecture

```
┌─────────────────┐         ┌─────────────────┐
│   Android       │         │   Windows 10 PC │
│   Termux        │◄───────►│   Ollama Server │
│                 │  SSH/   │                 │
│ - Qwen Code     │  HTTP   │ - AI Models     │
│ - Dev Tools     │         │ - SSH Server    │
└─────────────────┘         └─────────────────┘
```

### Setup Sync

1. **On Windows PC:**
```powershell
cd my-dev-setup\windows
.\windows-pc-server.ps1 -Install
```

2. **Enable SSH on Windows:**
```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
```

3. **On Termux:**
```bash
cd ~/my-dev-setup/sync
chmod +x termux-pc-sync.sh
./termux-pc-sync.sh --setup
./termux-pc-sync.sh --configure-ollama
```

### Use PC AI Models from Termux

```bash
# Create SSH tunnel
./sync/termux-pc-sync.sh --tunnel

# Use Qwen with PC models
qwen
```

## Tools Included

### AI Coding Assistants
| Tool | Description | Install |
|------|-------------|---------|
| **Qwen Code** | Alibaba AI coding assistant | `npm install -g @qwen-code/qwen-code` |
| **Gemini CLI** | Google AI coding assistant | `npm install -g @google/gemini-cli` |
| **Ollama** | Local LLM runner | See Windows setup |
| **Aider** | AI pair programming | `pip install aider-chat` |

### Development Tools
| Tool | Purpose |
|------|---------|
| **Node.js** (NVM) | JavaScript/TypeScript runtime |
| **Go** | Systems programming |
| **Python** | Scripting and automation |
| **ASDF** | Multi-language version manager |
| **Git** | Version control |

### Security & Android Tools
| Tool | Purpose |
|------|---------|
| **Metasploit** | Penetration testing |
| **APKTool** | APK reverse engineering |
| **JADX** | DEX to Java decompiler |
| **AAPT** | Android asset packaging |

## Directory Structure

```
my-dev-setup/
├── README.md                    # This file
├── setup.sh                     # Universal setup script
├── setup-termux.sh             # Termux setup
├── setup-kali.sh               # Kali Linux setup
├── setup-apktools.sh           # Android tools setup
├── .env.template               # Environment variables
├── configs/                    # Configuration files
│   ├── .bashrc
│   ├── .gitconfig
│   ├── .profile
│   ├── .aider.conf.yml
│   ├── .goterm.json
│   └── .qwen/settings.json
├── scripts/
│   ├── termux_cli_manager.py   # CLI manager
│   ├── android-optimizer.sh    # Hidden system optimizer
│   ├── log_analyzer.py         # Log analysis & auto-tune
│   └── install-optimizer.sh    # Optimizer installer
├── sync/                       # Termux-PC Sync
│   ├── termux-pc-sync.sh       # Main sync script
│   ├── backup-termux.sh        # Backup script
│   ├── setup-windows-ssh.sh    # SSH setup guide
│   └── README.md               # Sync documentation
├── windows/                    # Windows PC Setup
│   ├── windows-pc-server.ps1   # PowerShell setup
│   └── setup.bat               # CMD quick setup
└── docs/                       # Documentation
    ├── QUICKSTART.md           # 5-minute guide
    ├── QUICK_REFERENCE.md      # Command cheat sheet
    ├── qwen-code.md            # Qwen documentation
    ├── gemini-cli.md           # Gemini documentation
    ├── tools.md                # Tools reference
    ├── termux-pc-sync.md       # Sync guide
    ├── archer-ax1500-research.md  # Router research
    └── ANDROID_OPTIMIZER.md    # System optimizer guide
```

## Configuration

### Environment Variables

Set these in your `.env` file:

```bash
# API Keys
export GEMINI_API_KEY="your-gemini-api-key"
export BAILIAN_CODING_PLAN_API_KEY="your-bailian-key"

# Paths
export ANDROID_HOME=$HOME/android-sdk
export GOPATH=$HOME/go
export NVM_DIR="$HOME/.nvm"
```

### Ollama Setup

```bash
# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Pull the model
ollama pull qwen2.5-coder:1.5b
```

### Qwen Code Models

The setup includes these model configurations:
- qwen3.5-plus
- qwen3-coder-plus
- qwen3-coder-next
- qwen3-max-2026-01-23
- glm-4.7
- glm-5
- MiniMax-M2.5
- kimi-k2.5
- qwen2.5-coder:1.5b (local via Ollama)

## Tools Documentation

See the [docs/](docs/) directory for detailed documentation on each tool.

## Troubleshooting

### Common Issues

1. **npm install fails**
   - Try: `npm config set prefix ~/.npm-global`
   - Add to PATH: `export PATH=~/.npm-global/bin:$PATH`

2. **Ollama connection failed**
   - Ensure Ollama is running: `ollama serve`
   - Check endpoint in `.qwen/settings.json`

3. **Gemini CLI ripgrep issues**
   - Run: `python3 termux_cli_manager.py --fix-gemini`

## License

MIT License - Feel free to use and modify as needed.

## Author

- GitHub: [@mulfapoeding-gif](https://github.com/mulfapoeding-gif)
- Email: mulfapoeding@gmail.com
