# Demoni Quickstart

Get up and running with Demoni in under a minute.

## 1. Install

```bash
curl -fsSL https://raw.githubusercontent.com/illdynamics/demoni/main/install.sh | bash
```

This downloads the latest release, builds the container image, installs `@google/gemini-cli` globally, and puts the `demoni` command in `~/bin/demoni`.

Or from source:

```bash
git clone https://github.com/illdynamics/demoni.git
cd demoni
npm install && cd bridge && npm install && cd ..
npm run build
./demoni install
```

## 2. Set Your DeepSeek API Key

```bash
export DEEPSEEK_API_KEY="sk-..."
```

That's it. No Google login. No Gemini API key. No Vertex setup.

## 3. Add to PATH

```bash
export PATH="${HOME}/bin:${PATH}"
```

Add that line to `~/.zshrc` or `~/.bashrc` to make it permanent.

## 4. Run Instead of `gemini`

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

## How It Works

```
demoni → starts local bridge → spawns gemini CLI → Gemini CLI talks to bridge → bridge talks to DeepSeek
```

The Gemini CLI source is never modified. Demoni wraps it with environment variables and a local HTTP translation bridge.

## Next Steps

- Full docs: [`README.md`](./README.md)
- Architecture: [`docs/architecture.md`](./docs/architecture.md)
- Troubleshooting: [`docs/troubleshooting.md`](./docs/troubleshooting.md)
