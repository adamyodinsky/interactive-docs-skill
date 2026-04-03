# Interactive Docs Skill

A Claude Code skill/plugin that generates interactive documentation websites from any codebase.

## Structure

- `skills/interactive-docs/SKILL.md` - Main skill definition (8-phase pipeline)
- `skills/interactive-docs/references/` - Supporting docs consumed by subagents
- `skills/interactive-docs/scripts/` - Shell scripts for analysis, scaffolding, and validation
- `.claude-plugin/` - Plugin distribution metadata

## Key Conventions

- All script paths are resolved relative to the script's own directory (`SCRIPT_DIR`)
- SKILL.md instructs Claude to store its own directory as `$SKILL_DIR` in Phase 0
- All scripts receive absolute paths as arguments
- Scripts use `set -euo pipefail` for strict error handling
- The skill generates a standalone React + Vite + TypeScript project in the target project's directory

## Testing Changes

Run `/interactive-docs /path/to/any/project` and verify all 8 phases complete successfully.
