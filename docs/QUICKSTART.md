# Quick Start Guide

Get up and running in 5 minutes!

## For Termux (Android)

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/my-dev-setup.git
cd my-dev-setup

# 2. Run the Termux setup
./setup-termux.sh

# 3. Add your API keys (optional)
cp .env.template .env
nano .env  # Edit with your keys

# 4. Reload shell
source ~/.bashrc

# 5. Start using AI tools
qwen     # Qwen Code
gemini   # Gemini CLI
```

## For Kali Linux

```bash
# 1. Clone the repo
git clone https://github.com/YOUR_USERNAME/my-dev-setup.git
cd my-dev-setup

# 2. Run the Kali setup
./setup-kali.sh

# 3. Add your API keys (optional)
cp .env.template .env
nano .env  # Edit with your keys

# 4. Reload shell
source ~/.bashrc

# 5. Start using AI tools
qwen     # Qwen Code
gemini   # Gemini CLI
```

## Verify Installation

```bash
# Check Node.js
node --version
npm --version

# Check Go
go version

# Check AI tools
qwen --version
gemini --version

# Check Ollama (if installed)
ollama --version
ollama list
```

## Common Commands

### AI Assistants
```bash
qwen                    # Start Qwen Code interactive
gemini                  # Start Gemini CLI interactive
aider                   # Start Aider pair programming
```

### APK Tools (if installed)
```bash
apktool d app.apk       # Decompile APK
jadx app.apk            # Decompile to Java
apkmod -i app.apk       # Inject payload
```

### Version Management
```bash
nvm install 20          # Install Node.js 20
nvm use 20              # Switch to Node.js 20
nvm list                # List installed versions
```

## Next Steps

1. **Configure API Keys**: Edit `.env` with your API keys for cloud models
2. **Install Ollama Models**: `ollama pull qwen2.5-coder:1.5b`
3. **Customize Configs**: Edit `~/.bashrc`, `~/.gitconfig` to your preferences
4. **Explore Docs**: Check `docs/` folder for detailed guides

## Troubleshooting

### Command Not Found
```bash
source ~/.bashrc
```

### Permission Denied
```bash
chmod +x setup*.sh
```

### API Key Issues
```bash
echo $GEMINI_API_KEY    # Check if set
export GEMINI_API_KEY="your-key"  # Set temporarily
```

For more help, see [docs/tools.md](docs/tools.md)
