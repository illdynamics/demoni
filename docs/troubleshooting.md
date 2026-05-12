# Troubleshooting

## `DEEPSEEK_API_KEY` Not Set

**Symptoms:**
- `demoni` exits immediately with "DEEPSEEK_API_KEY is required"
- Any prompt or interactive mode fails at launch

**Fix:**
```bash
export DEEPSEEK_API_KEY="sk-..."
```

Add this to `~/.zshrc` or `~/.bashrc` to make it permanent.

## Gemini CLI Asks for Google Login

Demoni should suppress Google OAuth entirely. If the browser opens for login:

**Check the bridge is running:**
```bash
demoni --help
# ^ should work without prompting for Google login
```

**Verify environment variables are correct:**
```bash
# Check the config
demoni doctor  # if available, otherwise inspect env
echo $GOOGLE_GEMINI_BASE_URL  # should not be set manually
```

**Expected behavior:**
- `GEMINI_API_KEY` is set internally to a local proxy key (random UUID)
- `GOOGLE_GEMINI_BASE_URL` points to `http://127.0.0.1:<ephemeral-port>`
- `GEMINI_CLI_HOME` is isolated to `~/.demoni/gemini-cli-home/`
- Google auth env vars (`GOOGLE_APPLICATION_CREDENTIALS`, `GOOGLE_CLOUD_PROJECT`) are unset

**If it still happens:**
```bash
DEMONI_DEBUG=1 demoni "test" 2>&1 | head -50
```

File an issue with the debug output.

## Port Conflict

**Symptom:** Bridge fails to start with EADDRINUSE error.

**Fix:** Demoni uses ephemeral ports by default (automatically finds a free port). If you have conflicting software on port 7654:

```bash
# Set a specific port
export DEMONI_BRIDGE_PORT=8765

# Or let it auto-assign (default)
unset DEMONI_BRIDGE_PORT
```

## DeepSeek 401 / Authentication Failed

**Symptom:** Bridge starts but API calls return 401.

**Fix:**
```bash
# Check your key is set
echo "${DEEPSEEK_API_KEY:0:10}..."  # should show first 10 chars

# Verify it works directly
curl -s https://api.deepseek.com/v1/models \
  -H "Authorization: Bearer $DEEPSEEK_API_KEY" | head -5

# If empty response, your key is invalid or has no credits
```

## Model Not Found / "Unsupported Demoni Model"

**Symptom:** `demoni -m <model>` gives an error about unsupported model.

**Fix:** Only these four models are supported:

| Model | Description |
|-------|-------------|
| `v4-flash` | Fast, thinking off |
| `v4-flash-thinking` | Fast with reasoning |
| `v4-pro` | Stronger, thinking off |
| `v4-pro-thinking` | Stronger with deep reasoning |

```bash
# Use one of the above
demoni -m v4-flash "hello"
```

## Bridge Fails to Start

**Symptom:** `demoni` hangs or exits early with bridge-related errors.

**Fix:**
```bash
# Check if Node.js is available
node --version  # needs 20+

# Check if bridge dependencies are built
ls bridge/dist/server.js  # should exist

# Rebuild if needed
cd bridge && npm install && npx tsc && cd ..

# Try process mode explicitly
DEMONI_BRIDGE_MODE=process DEMONI_DEBUG=1 demoni --help
```

## Container Mode Issues

If you're using container bridge mode (not the default process mode):

**Podman SELinux:**
```bash
./demoni build  # uses podman or docker automatically
```

If you build manually with Podman and get permission errors:
```bash
# Use :Z on bind mounts
docker run --rm -it -v "$PWD:/workspace:Z" demoni:latest "test"
```

**Rootless Podman networking:**
```bash
# Keep bridge host at 127.0.0.1 inside container
export DEMONI_BRIDGE_HOST=127.0.0.1
```

## Streaming Stops Early

**Symptom:** Long responses cut off mid-stream.

**Fix:**
```bash
# Increase the stream idle timeout (default is usually sufficient)
export DEMONI_STREAM_IDLE_TIMEOUT_MS=1200000  # 20 minutes
```

## Debugging

Enable debug logging for detailed output:

```bash
DEMONI_DEBUG=1 demoni "test prompt"
```

Log files are stored in:
```
~/.demoni/log/demoni.log    # Wrapper logs
~/.demoni/log/bridge.log    # Bridge logs
```

## GitHub Issues

If none of the above helps, file an issue at:

https://github.com/illdynamics/demoni/issues

Include:
- Output of `node --version`
- Output of `demoni --version` (if it gets that far)
- Debug output with `DEMONI_DEBUG=1`
- Your OS and container runtime (if applicable)
