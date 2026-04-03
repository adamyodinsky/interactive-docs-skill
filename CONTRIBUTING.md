# Contributing to Interactive Docs Skill

Thanks for your interest in contributing! This guide will help you get started.

## Getting Started

1. Fork and clone the repository:

   ```bash
   git clone https://github.com/<your-username>/interactive-docs-skill.git
   ```

2. Install the skill locally for testing:

   ```bash
   ln -s "$(pwd)/skills/interactive-docs" ~/.claude/skills/interactive-docs
   ```

3. Make your changes and test them by running:

   ```
   /interactive-docs /path/to/any/project
   ```

## Project Structure

```
skills/interactive-docs/
├── SKILL.md            # Main skill definition (8-phase pipeline)
├── references/         # Supporting docs consumed by subagents
│   ├── ANALYSIS.md     # Explorer subagent methodology
│   ├── DIAGRAMS.md     # Diagram Architect transformation rules
│   ├── SITE_SPEC.md    # React site component specification
│   └── TYPES.md        # Canonical TypeScript type definitions
└── scripts/            # Shell scripts for analysis and validation
    ├── analyze.sh      # Static codebase analysis
    ├── gate.sh         # Phase gate enforcement
    ├── scaffold.sh     # Vite + React project scaffolding
    ├── validate.sh     # Build validation
    ├── validate-write.sh   # Post-write TypeScript checks
    ├── validate-visual.sh  # Playwright visual testing
    └── visual-tests.mjs    # Visual test runner
```

## How the Skill Works

The skill runs through 8 sequential phases, each gated by `gate.sh`:

0. **Resolve** - Validate project path, set up variables
1. **Analyze** - Run `analyze.sh` for static analysis (languages, frameworks, deps)
2. **Explore** - Subagent reads source code, produces `ProjectAnalysis` JSON
3. **Scaffold** - Run `scaffold.sh` to create Vite + React + TypeScript project
4. **Build** - Parallel subagents: Diagram Architect (data files) + Site Builder (components)
5. **Validate** - Run `validate.sh` to check TypeScript compilation
6. **Visual Test** - Run `validate-visual.sh` with Playwright
7. **Polish** - Subagent applies design polish to styling
8. **Report** - Output summary with file locations

## Conventions

- Shell scripts use `set -euo pipefail` for strict error handling
- Scripts receive absolute paths as arguments
- `$SKILL_DIR` is resolved at runtime in Phase 0 (directory containing SKILL.md)
- All generated content comes from actual codebase analysis - never use placeholder data
- Keep SKILL.md under 500 lines; use `references/` for detailed docs

## Pull Request Process

1. Create a feature branch from `main`
2. Test your changes against at least one real project
3. Ensure all scripts remain executable (`chmod +x scripts/*.sh`)
4. Submit a PR with a clear description of what changed and why
