# Qwen Code Setup Guide

Qwen Code is Alibaba's AI coding assistant, available as a CLI tool.

## Installation

```bash
npm install -g @qwen-code/qwen-code
```

## Configuration

### Using Local Ollama (Free, Offline)

1. Install Ollama:
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

2. Pull the model:
```bash
ollama pull qwen2.5-coder:1.5b
```

3. Configure in `~/.qwen/settings.json`:
```json
{
  "modelProviders": {
    "openai": [
      {
        "id": "qwen2.5-coder:1.5b",
        "name": "Local Ollama - qwen2.5-coder:1.5b",
        "baseUrl": "http://localhost:11434/v1",
        "envKey": "BAILIAN_CODING_PLAN_API_KEY",
        "generationConfig": {
          "contextWindowSize": 32768
        }
      }
    ]
  }
}
```

### Using Cloud API (Paid, More Powerful)

Get API key from: https://dashscope.console.aliyun.com/

Add to `.env`:
```bash
export BAILIAN_CODING_PLAN_API_KEY="your-api-key"
```

Available models:
- `qwen3.5-plus` - Balanced performance
- `qwen3-coder-plus` - Optimized for coding
- `qwen3-coder-next` - Fast coding assistant
- `qwen3-max-2026-01-23` - Most powerful

## Usage

```bash
# Start interactive mode
qwen

# Run with specific prompt
qwen "explain this code"

# Use with Aider for pair programming
aider --model ollama/qwen2.5-coder:1.5b
```

## Settings

Key settings in `~/.qwen/settings.json`:

- `modelProviders.openai` - List of available models
- `tools.approvalMode` - Set to "yolo" for auto-approve, "auto" for manual
- `model.name` - Default model to use

## Troubleshooting

### Connection Error

Make sure Ollama is running:
```bash
ollama serve
```

### Model Not Found

Pull the model again:
```bash
ollama pull qwen2.5-coder:1.5b
```

### Rate Limits

If using cloud API, check your quota at https://dashscope.console.aliyun.com/
