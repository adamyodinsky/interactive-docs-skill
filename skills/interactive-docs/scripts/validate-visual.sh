#!/usr/bin/env bash
# validate-visual.sh — Start dev server, run Playwright visual tests, report results
# Input: $1 = docs directory
# Output: JSON test results to stdout, screenshots to <docs-dir>/screenshots/
# Exit: 0 if all views pass, 1 if issues found
set -uo pipefail

DOCS_DIR="${1:?Usage: validate-visual.sh <docs-directory>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCREENSHOTS_DIR="$DOCS_DIR/screenshots"
PORT=5173
DEV_PID=""

cleanup() {
  [[ -n "$DEV_PID" ]] && kill "$DEV_PID" 2>/dev/null && wait "$DEV_PID" 2>/dev/null
  rm -f "$DOCS_DIR/visual-tests.mjs"
}
trap cleanup EXIT

if [[ ! -d "$DOCS_DIR" ]]; then
  echo '{"passed":false,"error":"Docs directory not found: '"$DOCS_DIR"'","views":[]}'
  exit 1
fi

cd "$DOCS_DIR"

# ── Install Playwright if needed ──────────────────────
if ! node -e "require('playwright')" 2>/dev/null; then
  echo "Installing playwright..." >&2
  if command -v yarn &>/dev/null; then
    yarn add -D playwright 2>&1 >&2
  else
    npm install -D playwright 2>&1 >&2
  fi
  npx playwright install chromium 2>&1 >&2

  # Verify installation
  if ! node -e "const{chromium}=require('playwright');chromium.launch({headless:true}).then(b=>b.close())" 2>/dev/null; then
    echo '{"passed":false,"error":"Playwright chromium installation failed","views":[]}'
    exit 1
  fi
fi

# ── Start dev server ──────────────────────────────────
if command -v yarn &>/dev/null; then
  yarn dev --port "$PORT" &
else
  npm run dev -- --port "$PORT" &
fi
DEV_PID=$!

echo "Waiting for dev server on port $PORT..." >&2
for i in $(seq 1 30); do
  curl -s "http://localhost:$PORT" > /dev/null 2>&1 && break
  kill -0 "$DEV_PID" 2>/dev/null || { echo '{"passed":false,"error":"Dev server crashed","views":[]}'; exit 1; }
  sleep 1
done

if ! curl -s "http://localhost:$PORT" > /dev/null 2>&1; then
  echo '{"passed":false,"error":"Dev server did not respond after 30s","views":[]}'
  exit 1
fi
echo "Dev server ready." >&2

# ── Run visual tests (copy script to docs dir for ESM resolution) ──
mkdir -p "$SCREENSHOTS_DIR"
cp "$SCRIPT_DIR/visual-tests.mjs" "$DOCS_DIR/visual-tests.mjs"
node "$DOCS_DIR/visual-tests.mjs" "http://localhost:$PORT" "$SCREENSHOTS_DIR"
exit $?
