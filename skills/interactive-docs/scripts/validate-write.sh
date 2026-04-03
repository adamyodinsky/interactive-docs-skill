#!/usr/bin/env bash
# validate-write.sh — PostToolUse hook: validate TypeScript files after write
# Input: $1 = absolute path to written file
# Output: warning messages to stdout (empty if OK)
# Exit: always 0 (warnings only, not blocking)

FILE="$1"

# Fast-path: skip non-TypeScript files
[[ -z "$FILE" ]] && exit 0
[[ "$FILE" != *.ts && "$FILE" != *.tsx ]] && exit 0
[[ ! -f "$FILE" ]] && exit 0

BASENAME=$(basename "$FILE")
WARNINGS=""

warn() {
  WARNINGS="${WARNINGS}WARNING: $1\n"
}

# Check: file is empty
if [[ ! -s "$FILE" ]]; then
  warn "File is empty: $BASENAME"
  printf "%b" "$WARNINGS"
  exit 0
fi

# Determine file role from path
IS_DATA=false
IS_VIEW=false
IS_COMPONENT=false
IS_TSX=false

[[ "$FILE" == */src/data/*.ts ]] && IS_DATA=true
[[ "$FILE" == */src/views/*.tsx ]] && IS_VIEW=true
[[ "$FILE" == */src/components/*.tsx || "$FILE" == */src/components/**/*.tsx ]] && IS_COMPONENT=true
[[ "$FILE" == *.tsx ]] && IS_TSX=true

# Check: missing default export on data files
if $IS_DATA; then
  if ! grep -q 'export default' "$FILE"; then
    warn "Missing 'export default' in data file: $BASENAME"
  fi
fi

# Check: missing default export on view files
if $IS_VIEW; then
  if ! grep -q 'export default' "$FILE"; then
    warn "Missing 'export default' in view file: $BASENAME"
  fi
fi

# Check: uses type names but missing type import
if $IS_DATA || $IS_COMPONENT || $IS_VIEW; then
  if grep -qE 'CrossLink|ViewId|ArchNode|CompNode|DFNode|ERDData|APIContractData|SequenceDiagram|StateMachine|TechStack|ADRRecord|SiteMetadata|ArchitectureData|ComponentGraphData|DataFlowData|DependencyGraphData' "$FILE"; then
    if ! grep -qE "from.*['\"].*types" "$FILE"; then
      warn "Uses type names but missing import from types: $BASENAME"
    fi
  fi
fi

# Check: TSX uses React hooks but missing React import
if $IS_TSX; then
  if grep -qE 'useState|useEffect|useMemo|useCallback|useRef|useContext' "$FILE"; then
    if ! grep -qE "from.*['\"]react['\"]" "$FILE"; then
      warn "Uses React hooks but missing import from 'react': $BASENAME"
    fi
  fi
fi

# Print any warnings
if [[ -n "$WARNINGS" ]]; then
  printf "%b" "$WARNINGS"
fi

exit 0
