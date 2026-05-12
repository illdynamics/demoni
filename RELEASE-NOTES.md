# Demoni Release Notes

## v0.2.1 (2026-05-12)

### License Change
- **Apache 2.0**: Relicensed from MIT to Apache License 2.0; LICENSE file replaced, package.json and README.md updated

### Release Blockers Fixed
- **SSE streaming**: Removed `data: [DONE]` from Gemini SSE responses — real Gemini CLI no longer crashes with SyntaxError
- **Security**: `bin/demoni-print-config` no longer leaks raw `DEEPSEEK_API_KEY`; prints `<set (redacted)>` only

### Production Hardening
- **Source hygiene**: Removed `.env`, `.codeseeq/`, `.DS_Store` from repo; added `check:release-hygiene` script
- **Model policy**: Strict enforcement — only `v4-flash`, `v4-flash-thinking`, `v4-pro`, `v4-pro-thinking` accepted; provider aliases rejected
- **Bridge startup**: Server only auto-starts with `DEMONI_BRIDGE_AUTO_START=1` flag; safe for test imports
- **Graceful shutdown**: Fixed double `server.close()` with `shuttingDown` guard
- **Brave/Unstructured**: 501 stubs removed; tools disabled until fully implemented
- **LiteLLM**: Hidden from help/docs; experimental only
- **Lint**: ESLint configured; `npm run lint` passes with 0 errors
- **Preflight**: `npm run preflight` now includes build + typecheck + lint + test + pack + hygiene

### Distribution
- **curl | bash installer**: `install.sh` fetches the latest GitHub release zip, extracts it, and runs `./demoni install` — one command from zero to working demoni
- **Release workflow**: New `.github/workflows/release.yml` auto-creates GitHub releases with zip archives on `v*` tags via `git archive`
- **README overhaul**: Replaced npm install instructions with curl/git/manual install options; removed Docker section (now handled by `./demoni install`)

### Developer Experience
- **Bootstrap script**: Added `./demoni` bootstrap/installer — `./demoni build` builds the Docker/Podman image, `./demoni install` installs to ~/.config/demoni and ~/bin/demoni for direct PATH access
- **CI fixes**: Docker tests excluded from test job (no Docker daemon), bridge auto-start flag added to docker job

### Testing
- **Real Gemini CLI E2E**: Created `test/real-gemini-cli.integration.test.ts` — proves full flow: mock DeepSeek → bridge → real Gemini CLI, no Google auth, no `[DONE]` crash (gated: `DEMONI_RUN_REAL_GEMINI_TESTS=1`)
- **144 tests passing**, 7 skipped (6 Docker + 1 real Gemini E2E)

### Packaging
- **npm pack**: 25.8 kB, 20 files, clean — no secrets, no node_modules in package
- **Release hygiene**: `npm run check:release-hygiene` verifies no forbidden files or secret patterns

### Known Limitations
- Docker tests require Docker runtime (6 tests skipped otherwise)
- Real Gemini CLI E2E gated behind `DEMONI_RUN_REAL_GEMINI_TESTS=1`
- 39 ESLint warnings from `any` types in translation code (0 errors)

---

## v0.2.0 (initial)

Initial production-grade architecture:
- Custom TypeScript Gemini→DeepSeek translation bridge (Express)
- Process bridge mode (no Docker required)
- External bridge mode
- Container bridge mode (fallback)
- Four-model policy (v4-flash, v4-flash-thinking, v4-pro, v4-pro-thinking)
- `@google/gemini-cli` npm dependency
- Auth suppression (no Google OAuth)
- YOLO/dangerous mode pass-through
- Streaming SSE support
- Tool call translation with ID preservation
- countTokens (estimator)
- Dockerfile (Node.js 22 slim, no Postgres/Julep)
- CI workflow (GitHub Actions)
