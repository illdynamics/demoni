#!/usr/bin/env bash
set -Eeuo pipefail
fail() { echo "[RELEASE-HYGIENE:FAIL] $*"; exit 1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Check forbidden files
for forbidden in .env .codeseeq .DS_Store __MACOSX; do
  if [ -e "$forbidden" ]; then
    fail "Forbidden file/dir present: $forbidden"
  fi
done

# Check no raw secrets in tracked files
if git rev-parse --git-dir >/dev/null 2>&1; then
  if git grep -l 'sk-[a-zA-Z0-9]\{20,\}' -- '*.ts' '*.js' '*.json' '*.sh' '*.md' 2>/dev/null; then
    fail "Possible secret patterns found in tracked files"
  fi
fi

# Check node_modules not in package
if [ -d node_modules ] && [ -f package.json ]; then
  if node -e "process.exit(JSON.parse(require("fs").readFileSync("package.json","utf8"))('./package.json'.files?.includes('node_modules/') ? 1 : 0)" 2>/dev/null; then
    fail "node_modules/ should not be in package.json files"
  fi
fi

echo "[RELEASE-HYGIENE:PASS] All checks passed"
