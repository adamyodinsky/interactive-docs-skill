#!/usr/bin/env bash
# gate.sh — Phase gate: enforce sequential phase execution
#
# Check prerequisites:  gate.sh check <phase> <project-root> [docs-dir]
# Mark phase complete:  gate.sh mark  <phase> <project-root> [docs-dir]
#
# State file: <project-root>/.interactive-docs-state
# Output: "READY" / "MARKED" on success, "BLOCKED: <reason>" on failure
# Exit: 0 on success, 1 on blocked/error
set -uo pipefail

ACTION="${1:?Usage: gate.sh <check|mark> <phase> <project-root> [docs-dir]}"
PHASE="${2:?Usage: gate.sh <check|mark> <phase> <project-root> [docs-dir]}"
PROJECT_ROOT="${3:?Usage: gate.sh <check|mark> <phase> <project-root> [docs-dir]}"
DOCS_DIR="${4:-}"

STATE_FILE="$PROJECT_ROOT/.interactive-docs-state"

completed_phase() {
  if [[ -f "$STATE_FILE" ]]; then
    local val
    val=$(sed -n 's/^completed_phase=\([0-9]*\)/\1/p' "$STATE_FILE" 2>/dev/null | head -1)
    echo "${val:--1}"
  else
    echo "-1"
  fi
}

# ── MARK ──────────────────────────────────────────────
if [[ "$ACTION" == "mark" ]]; then
  echo "completed_phase=$PHASE" > "$STATE_FILE"
  echo "completed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$STATE_FILE"
  echo "MARKED: Phase $PHASE complete"
  exit 0
fi

# ── CHECK ─────────────────────────────────────────────
if [[ "$ACTION" != "check" ]]; then
  echo "ERROR: Unknown action '$ACTION'. Use 'check' or 'mark'."
  exit 1
fi

COMPLETED=$(completed_phase)

# Phase 0: no prerequisites
if [[ "$PHASE" -eq 0 ]]; then
  echo "READY"
  exit 0
fi

# All other phases: previous phase must be complete
REQUIRED=$((PHASE - 1))
if [[ "$COMPLETED" -lt "$REQUIRED" ]]; then
  echo "BLOCKED: Phase $REQUIRED not completed (current: $COMPLETED). Run phases in order."
  exit 1
fi

# Phase-specific artifact checks
case "$PHASE" in
  4)
    # Phase 4 needs scaffold artifacts
    if [[ -z "$DOCS_DIR" || ! -d "$DOCS_DIR" ]]; then
      echo "BLOCKED: Docs directory does not exist. Run Phase 3 first."
      exit 1
    fi
    for f in package.json src/types/index.ts; do
      if [[ ! -f "$DOCS_DIR/$f" ]]; then
        echo "BLOCKED: $DOCS_DIR/$f missing. Scaffold incomplete."
        exit 1
      fi
    done
    ;;

  5)
    # Phase 5 needs data files + view files from Phase 4
    if [[ -z "$DOCS_DIR" || ! -d "$DOCS_DIR" ]]; then
      echo "BLOCKED: Docs directory does not exist."
      exit 1
    fi
    MISSING=""
    for f in metadata.ts architecture.ts components.ts dataflow.ts sequences.ts erd.ts stateMachines.ts apiContracts.ts dependencies.ts techStack.ts adrs.ts; do
      [[ ! -f "$DOCS_DIR/src/data/$f" ]] && MISSING="$MISSING src/data/$f"
    done
    [[ ! -f "$DOCS_DIR/src/App.tsx" ]] && MISSING="$MISSING src/App.tsx"
    [[ ! -f "$DOCS_DIR/src/main.tsx" ]] && MISSING="$MISSING src/main.tsx"
    if [[ -n "$MISSING" ]]; then
      echo "BLOCKED: Missing artifacts:$MISSING"
      exit 1
    fi
    ;;

  6|7|8)
    # Later phases just need sequential completion (already checked above)
    ;;
esac

echo "READY"
exit 0
