#!/usr/bin/env bash
# validate.sh — Run yarn build in the generated docs directory
# Input: $1 = absolute path to docs directory
# Output: "BUILD_SUCCESS" on success, full error output on failure
# Exit: 0 on success, 1 on failure
set -uo pipefail

DOCS_DIR="${1:?Usage: validate.sh <docs-directory>}"

if [ ! -d "$DOCS_DIR" ]; then
  echo "Error: Directory not found: $DOCS_DIR" >&2
  exit 1
fi

cd "$DOCS_DIR"

if [ ! -f "package.json" ]; then
  echo "Error: No package.json found in $DOCS_DIR" >&2
  exit 1
fi

# Detect package manager
if [ -f "yarn.lock" ] || command -v yarn &>/dev/null; then
  PM="yarn"
else
  PM="npm run"
fi

# Run build
OUTPUT=$($PM build 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "BUILD_SUCCESS"
  exit 0
else
  echo "$OUTPUT"
  exit 1
fi
