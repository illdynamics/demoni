# Demoni

**Production-grade Gemini CLI drop-in replacement routing to DeepSeek V4 models.**

Run `demoni` instead of `gemini`. Same flags, same interactive behavior, same tool calls. But your prompts go to DeepSeek V4 models via your `DEEPSEEK_API_KEY` — no Google account or API key needed.

<p align="center">
  <img src="./demoni.jpg" alt="Demoni" width="80%">
</p>

![CI](https://github.com/illdynamics/demoni/actions/workflows/ci.yml/badge.svg)

Current version: `v0.2.1` (from [`VERSION`](./VERSION)).

Release notes: [`RELEASE-NOTES.md`](./RELEASE-NOTES.md)

## Install

Demoni runs in **process mode** by default (`node` child process — no container needed). A Docker/Podman container image is also available. Pick your install method:

### Option 1: curl | bash (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/illdynamics/demoni/main/scripts/install.sh | bash
```

This downloads the latest release zip, extracts it, builds the container image, and installs the `demoni` command to `~/bin/demoni`. The `@google/gemini-cli` npm package is installed automatically.

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

- **Node.js 20+** (for process mode) **or** **Docker/Podman** (for container mode)
- **curl** and **unzip** — for the curl | bash installer
- **Linux** or **macOS** — Windows via WSL2 works too

## Model Selection

Demoni exposes exactly four models:

| Model | DeepSeek Backend | Thinking | Best For |
|-------|-----------------|----------|----------|
| `v4-flash` | `deepseek-v4-flash` | off | Fast daily coding, inspection |
| `v4-flash-thinking` | `deepseek-v4-flash` | on | Fast reasoning, debugging |
| `v4-pro` | `deepseek-v4-pro` | off | Heavy coding, reviews |
| `v4-pro-thinking` | `deepseek-v4-pro` | on | Deep architecture, hard bugs |

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

For a deep dive, see [`docs/architecture.md`](./docs/architecture.md).

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DEEPSEEK_API_KEY` | **Yes** | Your DeepSeek API key |
| `DEMONI_MODEL` | No | Default model (default: `v4-flash-thinking`) |
| `DEMONI_HOME` | No | Config directory (default: `~/.demoni`) |
| `DEMONI_BRIDGE_PORT` | No | Fixed bridge port (default: ephemeral / auto) |
| `DEMONI_BRIDGE_MODE` | No | Bridge launch mode: `auto`, `process`, `container`, `external` |
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

# Run test suite (144 tests, 7 skipped)
npm test

# Full preflight (build + typecheck + lint + test + pack + hygiene)
npm run preflight

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

For more troubleshooting, see [`docs/troubleshooting.md`](./docs/troubleshooting.md).

## CI / Release

Demoni uses GitHub Actions for continuous integration and automated releases.

- **CI workflow** (`.github/workflows/ci.yml`): Runs on every push and PR — static checks, build & test, package verification, Docker smoke tests.
- **Release workflow** (`.github/workflows/release.yml`): Triggers after CI and only runs on version tags (`v*`). Creates a GitHub Release with a zip archive.

A release is created automatically when a tag matching `v*` (e.g. `v0.2.2`) is pushed and all CI checks pass.

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
- [x] All 144 tests pass (151 total, 7 skipped)
- [x] Gemini CLI source is not modified

## License

Apache 2.0
