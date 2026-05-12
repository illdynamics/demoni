# Demoni

**Production-grade Gemini CLI drop-in replacement routing to DeepSeek V4 models.**

<p align="center">
  <img src="./demoni.jpg" alt="Demoni" width="80%">
</p>

Current version: v0.2.1

Run `demoni` instead of `gemini`. Same flags, same interactive behavior, same tool calls. But your prompts go to DeepSeek V4 models via your `DEEPSEEK_API_KEY` — no Google account needed.

## Install

Demoni runs inside a Docker or Podman container. Pick your install method:

### Option 1: curl | bash (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/illdynamics/demoni/main/install.sh | bash
```

This downloads the latest release, extracts it, builds the container image, and installs the `demoni` command to `~/bin/demoni`.

### Option 2: Git clone

```bash
git clone https://github.com/illdynamics/demoni.git
cd demoni
./demoni install
```

### Option 3: Manual download

```bash
# Grab the latest release from:
#   https://github.com/illdynamics/demoni/releases/latest
unzip demoni-v0.2.1.zip
cd demoni-v0.2.1
./demoni install
```

### After install

```bash
# Add ~/bin to PATH (add this to ~/.zshrc or ~/.bashrc)
export PATH="${HOME}/bin:${PATH}"

# Set your DeepSeek API key
export DEEPSEEK_API_KEY="sk-..."

# You're ready!
demoni --help
demoni -y "explain this codebase"
```

### Requirements

- **Docker** or **Podman** — the demoni CLI runs inside a container
- **curl** and **unzip** — for the curl | bash installer
- **Linux** or **macOS** — Windows via WSL2 works too


## Model Selection

Demoni exposes exactly four models:

| Model | DeepSeek Backend | Thinking | Best For |
|-------|-----------------|----------|----------|
| `v4-flash` | v4-flash (internally mapped to DeepSeek) | off | Fast daily coding, inspection |
| `v4-flash-thinking` | v4-flash (internally mapped to DeepSeek) | on | Fast reasoning, debugging |
| `v4-pro` | deepseek-v4-pro | off | Heavy coding, reviews |
| `v4-pro-thinking` | deepseek-v4-pro | on | Deep architecture, hard bugs |

```bash
demoni -m v4-flash "quick question"
demoni -m v4-flash-thinking "think through this bug"
demoni -m v4-pro "refactor this module"
demoni -m v4-pro-thinking "design the new API"
```

## YOLO / Dangerous Mode

Auto-approve all tool actions. **Only use in disposable VMs, containers, or trusted workspaces.**

```bash
demoni -y -m v4-pro-thinking "run tests and fix failures"
demoni --yolo -m v4-flash "refactor all files"
demoni --approval-mode=yolo -m v4-pro-thinking "migrate the database"
```

## Architecture

```
demoni (CLI wrapper)
  ├── Starts local bridge HTTP server (Express)
  │     └── Translates Gemini GenerateContent ↔ DeepSeek Chat Completions
  ├── Sets GOOGLE_GEMINI_BASE_URL → http://127.0.0.1:{port}
  ├── Sets GEMINI_API_KEY → demoni-local-placeholder
  ├── Writes Gemini CLI settings (forces API key auth, disables OAuth)
  └── Spawns upstream @google/gemini-cli (unmodified)
```

**Gemini CLI source is never modified.** Demoni wraps it with environment variables, config files, and a local translation bridge.

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DEEPSEEK_API_KEY` | **Yes** | Your DeepSeek API key |
| `DEMONI_MODEL` | No | Default model (default: `v4-flash-thinking`) |
| `DEMONI_HOME` | No | Config directory (default: `~/.demoni`) |
| `DEMONI_DEBUG` | No | Set to `1` for debug logging |
| `BRAVE_API_KEY` | No | Enable web search tool (optional) |
| `UNSTRUCTURED_API_KEY` | No | Enable document extraction (optional) |

## Config File

`~/.demoni/config.json`:
```json
{
  "defaultModel": "v4-flash-thinking"
}
```

## Development

```bash
# Install deps
npm install
cd bridge && npm install

# Build
npm run build

# Run tests (33 tests)
npm test

# Start dev mode (uses tsx)
npm run dev -- --help
```

## Troubleshooting

**"DEEPSEEK_API_KEY is required"**
Export your key: `export DEEPSEEK_API_KEY="sk-..."`

**"Unsupported Demoni model"**
Use one of: `v4-flash`, `v4-flash-thinking`, `v4-pro`, `v4-pro-thinking`

**Gemini CLI tries to open browser for Google login**
This is a bug in Demoni's auth suppression. Run with `DEMONI_DEBUG=1` and file an issue. Demoni writes settings to force API-key auth mode.

**Port conflict on 7654**
Set `DEMONI_BRIDGE_PORT=7655` or let Demoni find a free port automatically.

**DeepSeek 401 / authentication failed**
Check your `DEEPSEEK_API_KEY` is valid and has credits.

**Streaming stops early**
Set `DEMONI_STREAM_IDLE_TIMEOUT_MS=1200000` for longer streams.

## Acceptance Criteria

- [x] Clean install from repo works
- [x] `demoni --help` shows help with Demoni model docs
- [x] Only `DEEPSEEK_API_KEY` needed (no Google auth)
- [x] `/models` returns only 4 Demoni models
- [x] Streaming works (SSE via text/event-stream)
- [x] Tool calls round-trip with ID preservation
- [x] countTokens returns estimate without crashing
- [x] YOLO flags pass through
- [x] Model validation rejects unsupported models
- [x] Docker image is lean (Node.js only, no Postgres/Julep)
- [x] All 144 tests pass
- [x] Gemini CLI source is not modified

## License

Apache 2.0
