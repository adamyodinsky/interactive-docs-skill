---
name: interactive-docs
description: Generate an interactive documentation website from any codebase. Produces a React + Vite + TypeScript app with 10 cross-linked views covering architecture, components, data flows, sequences, ERD, state machines, APIs, dependencies, tech stack, and ADRs.
argument-hint: [/path/to/project]
---

# Interactive Documentation Generator

Analyze a codebase and produce a fully interactive, locally-runnable documentation site. The output is a React + Vite + TypeScript app with 10 views, all populated from real project analysis. Run `yarn dev` to browse.

Execute the phases below in strict order. Do not skip or merge phases.

### Phase Gate System

Every phase is guarded by `gate.sh`. Before starting a phase, run the gate check. After completing a phase, mark it done. This enforces sequential execution and validates prerequisites.

```bash
# Before starting Phase N:
bash "$SKILL_DIR/scripts/gate.sh" check N "$PROJECT_ROOT" "$DOCS_DIR"
# Must output "READY" — if "BLOCKED", stop and fix the issue.

# After completing Phase N:
bash "$SKILL_DIR/scripts/gate.sh" mark N "$PROJECT_ROOT"
```

**Never skip a gate check. Never mark a phase complete before it actually succeeds.**

---

## Phase 0 — Resolve Project Root

Determine the project to document:

1. If `$ARGUMENTS` is non-empty, use it as the project path. Resolve relative paths against the current working directory.
2. If `$ARGUMENTS` is empty, use the current working directory.
3. Validate the path exists and is a directory. If not, tell the user and stop.

Store the resolved absolute path as `PROJECT_ROOT`.

Store the directory containing this SKILL.md as `SKILL_DIR` — all script and reference paths below are relative to it.

Mark complete: `bash "$SKILL_DIR/scripts/gate.sh" mark 0 "$PROJECT_ROOT"`

---

## Phase 1 — Static Analysis

Gate check: `bash "$SKILL_DIR/scripts/gate.sh" check 1 "$PROJECT_ROOT"`

Run the static analysis script:

```bash
bash "$SKILL_DIR/scripts/analyze.sh" "$PROJECT_ROOT"
```

Capture stdout as `STATIC_ANALYSIS_JSON`. If the script exits non-zero, report the error to the user and stop.

Extract `PROJECT_NAME` from the JSON's `projectName` field.

This JSON contains: file tree, detected languages, frameworks, dependencies, entry points, LOC per directory, env keys, config files, schema files, and optional madge dependency graph output.

Mark complete: `bash "$SKILL_DIR/scripts/gate.sh" mark 1 "$PROJECT_ROOT"`

---

## Phase 2 — Explorer Subagent

Gate check: `bash "$SKILL_DIR/scripts/gate.sh" check 2 "$PROJECT_ROOT"`

Launch an Agent to deeply read the project source and produce a structured `ProjectAnalysis` JSON.

Use the Agent tool with this prompt (substitute the actual values for the placeholders):

```
You are the Explorer subagent for interactive-docs. Your job is to deeply read source files in a software project and produce a structured ProjectAnalysis JSON object.

**Project root**: <PROJECT_ROOT>

**Static analysis data** (from Phase 1):
<STATIC_ANALYSIS_JSON>

**Your instructions**:
1. Read the methodology file at: <SKILL_DIR>/references/ANALYSIS.md — follow it exactly.
2. Read the type definitions at: <SKILL_DIR>/references/TYPES.md — your output must conform to the ProjectAnalysis interface defined there.
3. Read source files in the project as directed by ANALYSIS.md (priority tiers, max 200 files, skip tests/node_modules/build outputs).
4. Write the complete ProjectAnalysis as a JSON file to: <PROJECT_ROOT>/project-analysis.json

The JSON must contain real data extracted from the actual codebase. No placeholders. No fabricated names. If something cannot be determined, omit it — do not invent it.
```

After the Agent returns, validate the file exists and contains valid JSON:

```bash
node -e "JSON.parse(require('fs').readFileSync('$PROJECT_ROOT/project-analysis.json','utf8')); console.log('OK')"
```

Mark complete: `bash "$SKILL_DIR/scripts/gate.sh" mark 2 "$PROJECT_ROOT"`

---

## Phase 3 — Scaffold the Site

Gate check: `bash "$SKILL_DIR/scripts/gate.sh" check 3 "$PROJECT_ROOT"`

Run the scaffold script to create the Vite project:

```bash
bash "$SKILL_DIR/scripts/scaffold.sh" "$PROJECT_ROOT" "$PROJECT_NAME"
```

Capture stdout as `DOCS_DIR` (the absolute path to the created docs directory, typically `<PROJECT_ROOT>/<PROJECT_NAME>-docs/`).

If the script exits non-zero, report the error and stop. Common failure: `yarn` or `npm` not installed.

Mark complete: `bash "$SKILL_DIR/scripts/gate.sh" mark 3 "$PROJECT_ROOT"`

---

## Phase 4 — Diagram Architect + Site Builder (Parallel)

Gate check: `bash "$SKILL_DIR/scripts/gate.sh" check 4 "$PROJECT_ROOT" "$DOCS_DIR"`

Launch **two** Agent calls **simultaneously** in a single message. They write to different paths within `DOCS_DIR` and do not conflict.

### Phase 4A — Diagram Architect

```
You are the Diagram Architect subagent for interactive-docs. Your job is to transform a ProjectAnalysis JSON into 11 typed data files for a React documentation site.

**Docs directory**: <DOCS_DIR>

**Your instructions**:
1. Read the ProjectAnalysis JSON from: <PROJECT_ROOT>/project-analysis.json
2. Read the diagram rules at: <SKILL_DIR>/references/DIAGRAMS.md — follow them exactly.
3. Read the type definitions at: <SKILL_DIR>/references/TYPES.md — every file you write must use these types.
4. Write all 11 data files to <DOCS_DIR>/src/data/:
   - metadata.ts, architecture.ts, components.ts, dataflow.ts, sequences.ts, erd.ts, stateMachines.ts, apiContracts.ts, dependencies.ts, techStack.ts, adrs.ts
5. Each file must: import types from '../types', export a default constant, contain only real project data.
6. Cross-links must be bidirectional — if A links to B, B must link to A.
7. Follow the ID prefix conventions in TYPES.md (arch-*, comp-*, df-*, seq-*, entity-*, sm-*, api-*, dep-*, tech-*, adr-*).

No placeholder data. Every node, entity, and endpoint must come from the ProjectAnalysis.
```

### Phase 4B — Site Builder

```
You are the Site Builder subagent for interactive-docs. Your job is to write all React components, views, hooks, and utilities for an interactive documentation site.

**Docs directory**: <DOCS_DIR>

**Your instructions**:
1. Read the site specification at: <SKILL_DIR>/references/SITE_SPEC.md — follow it exactly.
2. Read the type definitions at: <SKILL_DIR>/references/TYPES.md — all components must use these types.
3. Write files in the order specified in SITE_SPEC.md to avoid import errors:
   - Hooks (src/hooks/): useTheme, useSearch, useKeyboardShortcuts, useCrossLinks
   - Utils (src/utils/): searchIndex.ts, idUtils.ts
   - Shared components (src/components/shared/): ReactFlowCanvas, MermaidDiagram, SearchModal, CrossLinkChip, EntityCard, JsonTree
   - Custom nodes (src/components/nodes/): ArchitectureNode, ComponentNode, DataFlowNode, DependencyNode
   - Layout components (src/components/layout/): Sidebar, Topbar, DetailPanel, Breadcrumb
   - Views (src/views/): all 10 view components
   - App.tsx and main.tsx
4. Components are generic and data-driven. They import from '../data/' but contain NO project-specific content.
5. Every view must handle empty data gracefully with a contextual message.

Do NOT write any src/data/ files — the Diagram Architect handles those.
```

Wait for both Agents to complete before proceeding.

Mark complete: `bash "$SKILL_DIR/scripts/gate.sh" mark 4 "$PROJECT_ROOT"`

---

## Phase 5 — Build Validation

Gate check: `bash "$SKILL_DIR/scripts/gate.sh" check 5 "$PROJECT_ROOT" "$DOCS_DIR"`

Run the build validation:

```bash
bash "$SKILL_DIR/scripts/validate.sh" "$DOCS_DIR"
```

If stdout contains `BUILD_SUCCESS`, proceed to Phase 6.

If the build fails:

1. Read the error output from stderr.
2. Parse TypeScript errors for file paths and line numbers.
3. Read the failing files.
4. Fix the errors — common issues:
   - Missing `export default` on data or view files
   - Type mismatches between data files and type definitions
   - Missing imports (types, React hooks, libraries)
   - Incorrect import paths (`../types` vs `../../types`)
   - Mermaid string syntax issues
5. Re-run `validate.sh`.
6. Repeat up to **5 iterations**. If still failing after 5 attempts, report the remaining errors to the user with the specific files and line numbers that need attention.

You may also run `validate-write.sh` manually on individual files during fixing:

```bash
bash "$SKILL_DIR/scripts/validate-write.sh" "<file_path>"
```

Mark complete (only after BUILD_SUCCESS): `bash "$SKILL_DIR/scripts/gate.sh" mark 5 "$PROJECT_ROOT"`

---

## Phase 6 — Visual Validation

Gate check: `bash "$SKILL_DIR/scripts/gate.sh" check 6 "$PROJECT_ROOT"`

After the build passes, validate that the site actually renders correctly using Playwright.

Run the visual validation:

```bash
bash "$SKILL_DIR/scripts/validate-visual.sh" "$DOCS_DIR"
```

This script:
1. Installs Playwright in the docs project if not present
2. Starts the dev server
3. Visits all 10 views and checks for rendering issues
4. Takes screenshots to `<DOCS_DIR>/screenshots/`
5. Kills the dev server
6. Outputs JSON results to stdout

Parse the JSON output. For each view with issues:

1. Read the specific issue (Mermaid error, missing React Flow canvas, empty content, etc.)
2. Read the relevant source files (data file + view component)
3. Fix the root cause:
   - **Mermaid errors**: Fix syntax in the data file (escape special chars, use camelCase for names, check size limits)
   - **Missing React Flow canvas**: Check the view imports ReactFlowCanvas and passes valid nodes/edges
   - **Empty content**: Check the data file exports actual data, not empty arrays
   - **Sidebar issues**: Check App.tsx routing and Sidebar component
4. Re-run `validate-visual.sh`
5. Repeat up to **3 iterations**

Review the screenshots in `<DOCS_DIR>/screenshots/` to assess overall quality before proceeding.

Mark complete: `bash "$SKILL_DIR/scripts/gate.sh" mark 6 "$PROJECT_ROOT"`

---

## Phase 7 — Design Polish

Gate check: `bash "$SKILL_DIR/scripts/gate.sh" check 7 "$PROJECT_ROOT"`

This phase uses a **fresh Agent** to polish the site's visual design. The Agent gets a clean context window, which is important because prior phases will have consumed significant context.

Launch an Agent with this prompt:

```
You are the Design Polish subagent for interactive-docs. Your job is to elevate the visual design of a generated documentation site from functional to polished and distinctive.

**Docs directory**: <DOCS_DIR>

**Your instructions**:

1. Read the design methodology at: <SKILL_DIR>/references/SITE_SPEC.md — understand the existing component structure and theming system.

2. Apply these design principles to guide your polish work:
   - Prefer depth and dimension over flat surfaces (subtle gradients, layered shadows, glass-morphism where appropriate)
   - Use accent color purposefully — it should draw the eye to interactive elements, not overwhelm
   - Typography hierarchy must be immediately clear: headings distinct from body, code distinct from prose
   - Motion should be functional (guide attention, confirm interaction), never purely decorative
   - Information density should be high but never cluttered — use whitespace as a structural element
   - Dark mode should feel crafted, not just "inverted colors" — adjust contrast ratios, shadow intensity, and surface colors independently
   - Consistency over flair: every spacing, radius, and color choice should come from the design system, not ad-hoc values

3. Look at the Playwright screenshots in <DOCS_DIR>/screenshots/ to assess the current visual state of each view.

4. Improve the site's visual design by editing ONLY styling and layout files. Focus on:

   **Typography & Hierarchy**
   - Ensure heading/body/code font pairing creates clear visual hierarchy
   - Fine-tune font sizes, weights, line-heights, letter-spacing
   - Make sure node labels in diagrams are legible and well-spaced

   **Color & Theme**
   - Refine the dark theme for depth and contrast (not flat gray boxes)
   - Ensure accent colors are used consistently and purposefully
   - Add subtle gradients or texture to surfaces for visual interest
   - Make sure the light theme is equally polished

   **Motion & Interaction**
   - Add smooth transitions on view changes and panel open/close
   - Ensure hover states feel responsive on sidebar items, cards, and nodes
   - Add subtle entrance animations on page load (staggered fade-in)
   - Make React Flow node selection feel tactile (scale, shadow, glow)

   **Spatial Composition**
   - Refine padding/margins for breathing room
   - Ensure diagram views use available space well (not cramped, not lost)
   - Polish the sidebar/topbar/panel proportions
   - Make card layouts (Mermaid gallery, tech stack, ADRs) visually consistent

   **Visual Polish**
   - Add subtle shadows, borders, or gradients to distinguish surfaces
   - Ensure empty states look designed, not broken
   - Polish the search modal appearance
   - Refine cross-link chips to be compact but readable

5. Files you MAY edit:
   - src/index.css (global styles, CSS variables, theme)
   - src/components/layout/*.tsx (Sidebar, Topbar, DetailPanel, Breadcrumb)
   - src/components/shared/*.tsx (shared components styling)
   - src/components/nodes/*.tsx (custom node styling)
   - src/views/*.tsx (view-level layout/styling only)
   - tailwind.config.ts (theme extensions)

6. Files you MUST NOT edit:
   - src/data/*.ts (data files — never change project-specific content)
   - src/types/index.ts (type definitions)

7. After making changes, run the build to verify nothing breaks:
   bash <SKILL_DIR>/scripts/validate.sh <DOCS_DIR>

The goal is a site that looks intentionally designed — not like generic scaffolded output. Think developer tool aesthetic: clean, information-dense, but with craft.
```

After the Agent completes, run build validation again to confirm the site still compiles:

```bash
bash "$SKILL_DIR/scripts/validate.sh" "$DOCS_DIR"
```

If the build fails, fix the issues introduced by the design polish.

Mark complete: `bash "$SKILL_DIR/scripts/gate.sh" mark 7 "$PROJECT_ROOT"`

---

## Phase 8 — Report

Gate check: `bash "$SKILL_DIR/scripts/gate.sh" check 8 "$PROJECT_ROOT"`

Print a summary for the user:

```
## Documentation Generated

**Location**: <DOCS_DIR>
**Run**: cd <DOCS_DIR> && yarn dev

### Views
- System Overview: N nodes
- Component Graph: N components
- Data Flow: N flows
- Sequence Diagrams: N diagrams
- Entity-Relationship: N entities
- State Machines: N machines
- API Contracts: N endpoints
- Dependency Graph: N modules
- Tech Stack: N technologies
- ADRs: N records

### Screenshots
See <DOCS_DIR>/screenshots/ for a visual preview of each view.
```

Include any warnings about empty views or sections where data could not be extracted.

---

## Error Handling

| Phase | Failure | Action |
|-------|---------|--------|
| 1 — Static Analysis | `analyze.sh` exits non-zero | Report error. Ask if the user wants to specify a different project root. |
| 2 — Explorer | Subagent fails or returns invalid JSON | Report what happened. If partial JSON is available, attempt to proceed with what exists. |
| 3 — Scaffold | `scaffold.sh` exits non-zero | Usually missing `yarn`/`npm`. Report the specific error. |
| 4 — Subagents | Either subagent fails | Report which one failed. The other subagent's output is still valid — you can fix the failed one's files manually. |
| 5 — Build | Build fails after 5 fix iterations | List remaining errors with file paths and line numbers. Tell the user which files need manual attention. |
| 6 — Visual | Playwright fails to install or run | Skip visual validation, warn the user, proceed to design polish. The build already passed — visual issues can be caught manually. |
| 7 — Design Polish | Design agent introduces build errors | Run build validation again and fix. The design agent only touches styling files, so errors are typically import-related. |

---

## Quality Rules (Non-Negotiable)

1. **No placeholder content.** Every diagram node, entity, and data point comes from real analysis. If undetermined, omit — never fabricate.
2. **Every diagram is interactive.** Zoomable, pannable, clickable. No static images.
3. **Cross-links are mandatory.** Every entity that relates to something in another view must link to it.
4. **The site must build cleanly.** `yarn build` passes with zero TypeScript errors before reporting completion.
5. **Data files are the source of truth.** No project-specific data in component files. All data lives in `src/data/*.ts`.
6. **Universal project support.** Never refuse a project. Adapt analysis to whatever languages and patterns exist.
7. **Performance.** Mermaid diagrams lazy-rendered. React Flow graphs with 50+ nodes use virtualization. Site loads in under 3 seconds on localhost.
