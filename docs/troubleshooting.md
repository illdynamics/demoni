# Troubleshooting

## `DEEPSEEK_API_KEY` Missing

Symptoms:

- `demoni:dev ping` fails immediately.
- Prompt/interactive mode exits before launch.

Fix:

```bash
export DEEPSEEK_API_KEY='sk-...'
```

## Gemini CLI Asks for Google Login

Demoni should not use Google login.

Check:

```bash
podman run --rm -it -e DEEPSEEK_API_KEY="$DEEPSEEK_API_KEY" -v "$PWD:/workspace:Z" -w /workspace demoni:dev config
```

Expected:

- `GEMINI_CLI_HOME=/home/demoni/.demoni-gemini`
- `GEMINI_API_KEY=demoni-local-placeholder`
- `GOOGLE_GEMINI_BASE_URL=http://127.0.0.1:7654`

If not, remove custom overrides and re-run with defaults.

## Demoni Using Real `~/.gemini`

Demoni-supported paths must not use host `~/.gemini`.

Check `config` output and ensure:

- `DEMONI_GEMINI_HOME=/home/demoni/.demoni-gemini`
- `SETTINGS_PATH=/home/demoni/.demoni-gemini/settings.json`

## Bridge Start Command Cannot Be Detected

Set an explicit command:

```bash
podman run ... -e DEMONI_BRIDGE_CMD='node /opt/demoni/bridge/dist/server.js' demoni:dev doctor
```

## Wrong Bridge Port

Set both host and port explicitly:

```bash
podman run ... \
  -e DEMONI_BRIDGE_HOST=127.0.0.1 \
  -e DEMONI_BRIDGE_PORT=8765 \
  demoni:dev doctor
```

## Gemini CLI Hits Wrong Endpoint

Ensure `GOOGLE_GEMINI_BASE_URL` points at the local bridge URL shown by `config`.

## Unsupported Gemini GenerateContent Request Shape

If upstream Gemini request formats change, bridge translation may fail with 4xx/5xx.

Run:

```bash
podman run ... demoni:dev doctor
podman run ... demoni:dev ping
```

Then inspect bridge logs inside container at `/var/log/demoni/bridge.log`.

## Model Unsupported by Bridge / Non-DeepSeek Model Rejected

Demoni only supports:

- `deepseek-v4-flash`
- `deepseek-v4-flash-thinking`
- `deepseek-v4-pro`
- `deepseek-v4-pro-thinking`

Any other model ID is rejected.

## Model Menu Not Fully Restrictable

Gemini CLI upstream model menu UI cannot be fully restricted without forking Gemini CLI.

Current behavior:

1. Demoni-generated catalog is DeepSeek-only.
2. Wrapper-level model switching is DeepSeek-only.
3. Bridge rejects non-DeepSeek model IDs.
4. `doctor` prints a warning documenting this upstream limitation.

## Thinking Mode Backend Limitations

Demoni maps logical thinking aliases to DeepSeek `thinking.type=enabled` with `reasoning_effort=high|max`.

If a model/backend path does not honor thinking reliably, use non-thinking aliases:

- `deepseek-v4-flash`
- `deepseek-v4-pro`

## Thinking + Tool Calls (`reasoning_content`) Errors

DeepSeek thinking+tool loops may require strict reasoning context replay.

If you see repeated 400 errors in tool loops, run with non-thinking mode first to isolate:

```bash
podman run ... demoni:dev --model deepseek-v4-flash "..."
```

## Podman SELinux Volume Issues

Use `:Z` on bind mounts:

```bash
-v "$PWD:/workspace:Z"
```

## Rootless Podman Networking Weirdness

If localhost routing behaves unexpectedly in your environment:

1. Keep bridge host at `127.0.0.1` inside container.
2. Avoid host network mode.
3. Re-test with `demoni:dev doctor` and `demoni:dev ping`.

## Dangerous Mode Not Fully Supported by Installed Gemini CLI

Demoni requests `--approval-mode yolo` by default.

If your installed Gemini CLI changes approval/sandbox semantics, Demoni falls back to the closest supported behavior and `doctor` output should be reviewed.
