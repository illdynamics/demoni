# Tools

Demoni runs Gemini CLI against a local bridge and can use Gemini CLI tool capabilities as configured by Gemini settings.

Demoni's supported state path is isolated:

- `/home/demoni/.demoni-gemini/settings.json` by default
- Never the operator's host `~/.gemini`

If you add MCP servers, keep secrets out of generated config files whenever possible.
