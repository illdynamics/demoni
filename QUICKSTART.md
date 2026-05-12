# Demoni Quickstart

## 1. Install

```bash
npm install -g demoni
```

Or from source:

```bash
git clone <repo-url> && cd demoni
npm install && cd bridge && npm install && cd ..
npm run build
npm link
```

## 2. Set Your DeepSeek API Key

```bash
export DEEPSEEK_API_KEY="sk-..."
```

That's it. No Google login. No Gemini API key. No Vertex setup.

## 3. Run Instead of `gemini`

```bash
# Interactive mode
demoni

# Quick prompt
demoni "explain this codebase"

# Choose a model
demoni -m v4-flash "quick question"
demoni -m v4-flash-thinking "think through this bug"
demoni -m v4-pro "refactor this file"
demoni -m v4-pro-thinking "design the new API"

# YOLO mode (auto-approve all tool actions)
demoni -y -m v4-pro-thinking "run tests and fix failures"
```

## Models

| Model | Description |
|-------|-------------|
| `v4-flash` | Fast DeepSeek V4 Flash, thinking off |
| `v4-flash-thinking` | DeepSeek V4 Flash with reasoning |
| `v4-pro` | Stronger DeepSeek V4 Pro, thinking off |
| `v4-pro-thinking` | DeepSeek V4 Pro with deep reasoning |

## What's Happening

```
demoni → starts local bridge → spawns gemini CLI → Gemini CLI talks to bridge → bridge talks to DeepSeek
```

The Gemini CLI source is never modified. Demoni wraps it.
