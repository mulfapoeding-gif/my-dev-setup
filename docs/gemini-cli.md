# Gemini CLI Setup Guide

Google's Gemini AI coding assistant for the command line.

## Installation

```bash
npm install -g @google/gemini-cli
```

## Configuration

### Get API Key

1. Visit: https://makersuite.google.com/app/apikey
2. Create a new API key
3. Add to your `.env` file:

```bash
export GEMINI_API_KEY="your-gemini-api-key-here"
```

## Usage

```bash
# Start interactive mode
gemini

# Run with specific prompt
gemini "explain this code"

# Run with file context
gemini "fix this bug" path/to/file.py
```

## Termux/Android Patch

On Termux, Gemini CLI needs a patch to use system ripgrep:

```bash
# Run the auto-patcher
python3 termux_cli_manager.py --fix-gemini

# Or manually patch
# See scripts/gemini-auto-patch.js
```

## Settings

Configuration is stored in:
- `~/.gemini-cli/config.json` - User settings
- `~/.gemini-cli/` - Cache and data directory

## Tips

1. **Use context efficiently**: Gemini works best with relevant file context
2. **Be specific**: Clear prompts get better results
3. **Review changes**: Always review AI-generated code before accepting

## Troubleshooting

### ripgrep Error

If you see ripgrep-related errors on Android:
```bash
pkg install ripgrep
python3 termux_cli_manager.py --fix-gemini
```

### API Quota Exceeded

Gemini API has rate limits. If exceeded:
- Wait a few minutes
- Upgrade your API plan
- Switch to local Ollama model

### Authentication Failed

Check your API key:
```bash
echo $GEMINI_API_KEY
```

Ensure it's set in your shell environment.
