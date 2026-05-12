#!/usr/bin/env bash
set -Eeuo pipefail

log() { printf '[package] %s\n' "$*" >&2; }

VERSION="0.1.0"
OUTPUT="demoni-${VERSION}.zip"

log "packaging Demoni v${VERSION}"

# Create a temporary staging area
STAGING=$(mktemp -d)
trap 'rm -rf "$STAGING"' EXIT

mkdir -p "$STAGING/demoni"
cp -r . "$STAGING/demoni/"

# Exclusions
cd "$STAGING/demoni"
rm -rf .git .env *.env bridge/node_modules tools/node_modules gemini-cli/node_modules bridge/dist tools/dist .DS_Store __MACOSX logs .demoni-gemini .gemini
find . -name "node_modules" -type d -prune -exec rm -rf {} +
find . -name "dist" -type d -prune -exec rm -rf {} +
find . -name "build" -type d -prune -exec rm -rf {} +
find . -name "*.log" -delete

if [[ "${1:-}" == "--check" ]]; then
    log "check mode: scanning for secrets"
    if grep -rE "sk-[a-zA-Z0-9]{32,}" .; then
        log "Error: Secrets detected in package!"
        exit 1
    fi
    log "secrets check: OK"
fi

cd ..
zip -r "$OUTPUT" demoni/ >/dev/null

log "created $OUTPUT"
mv "$OUTPUT" "${OLDPWD}/"
