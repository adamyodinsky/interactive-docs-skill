#!/usr/bin/env bash
# scaffold.sh — Create a Vite + React + TypeScript docs project with all dependencies
# Input: $1 = project root, $2 = project name
# Output: Creates $1/$2-docs/, prints absolute path to stdout
# Exit: 0 on success, 1 on failure
set -euo pipefail

PROJECT_ROOT="${1:?Usage: scaffold.sh <project-root> <project-name>}"
PROJECT_NAME="${2:?Usage: scaffold.sh <project-root> <project-name>}"

DOCS_DIR="$PROJECT_ROOT/${PROJECT_NAME}-docs"

if [ -d "$DOCS_DIR" ]; then
  echo "Warning: $DOCS_DIR already exists, using existing directory" >&2
fi

# ============================================================
# Detect package manager
# ============================================================
if command -v yarn &>/dev/null; then
  PM="yarn"
  PM_ADD="yarn add"
  PM_ADD_DEV="yarn add -D"
  PM_CREATE="yarn create vite"
elif command -v npm &>/dev/null; then
  PM="npm"
  PM_ADD="npm install"
  PM_ADD_DEV="npm install -D"
  PM_CREATE="npm create vite@latest"
else
  echo "Error: Neither yarn nor npm found" >&2
  exit 1
fi

# ============================================================
# Create Vite project
# ============================================================
cd "$PROJECT_ROOT"

if [ ! -d "$DOCS_DIR" ]; then
  $PM_CREATE "${PROJECT_NAME}-docs" -- --template react-ts 2>&1 >&2
fi

cd "$DOCS_DIR"

# ============================================================
# Install dependencies
# ============================================================
$PM_ADD \
  react-router-dom \
  @xyflow/react \
  mermaid \
  framer-motion \
  lucide-react \
  react-markdown \
  rehype-highlight \
  react-json-view-lite \
  fuse.js \
  2>&1 >&2

$PM_ADD_DEV \
  tailwindcss@3 \
  autoprefixer \
  postcss \
  @tailwindcss/typography \
  2>&1 >&2

# ============================================================
# Install base dependencies if needed
# ============================================================
if [ "$PM" = "yarn" ]; then
  yarn install 2>&1 >&2
else
  npm install 2>&1 >&2
fi

# ============================================================
# Create directory structure
# ============================================================
mkdir -p src/{data,views,components/{layout,shared,nodes},hooks,utils,types}

# ============================================================
# Write tailwind.config.ts
# ============================================================
cat > tailwind.config.ts << 'TAILWINDEOF'
import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        background: 'var(--color-background)',
        surface: 'var(--color-surface)',
        elevated: 'var(--color-elevated)',
        border: 'var(--color-border)',
        foreground: 'var(--color-foreground)',
        muted: 'var(--color-muted)',
        accent: 'var(--color-accent)',
        success: 'var(--color-success)',
        warning: 'var(--color-warning)',
        error: 'var(--color-error)',
      },
      fontFamily: {
        display: ['Space Mono', 'monospace'],
        sans: ['Inter', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      },
    },
  },
  plugins: [require('@tailwindcss/typography')],
};

export default config;
TAILWINDEOF

# ============================================================
# Write postcss.config.js
# ============================================================
cat > postcss.config.js << 'POSTCSSEOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
POSTCSSEOF

# ============================================================
# Write vite.config.ts
# ============================================================
cat > vite.config.ts << 'VITEEOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  optimizeDeps: {
    include: ['mermaid'],
  },
});
VITEEOF

# ============================================================
# Write index.html
# ============================================================
cat > index.html << HTMLEOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>${PROJECT_NAME} - Interactive Docs</title>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500;600&family=Space+Mono:wght@400;700&display=swap" rel="stylesheet" />
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
HTMLEOF

# ============================================================
# Write src/index.css
# ============================================================
cat > src/index.css << 'CSSEOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --color-background: #0d0d0f;
  --color-surface: #141417;
  --color-elevated: #1c1c21;
  --color-border: #2a2a32;
  --color-foreground: #e2e8f0;
  --color-muted: #94a3b8;
  --color-accent: #7c6af7;
  --color-success: #3ecf8e;
  --color-warning: #f59e0b;
  --color-error: #ef4444;
}

[data-theme="light"] {
  --color-background: #ffffff;
  --color-surface: #f8f9fa;
  --color-elevated: #f0f1f3;
  --color-border: #e2e4e8;
  --color-foreground: #1a1a2e;
  --color-muted: #64748b;
  --color-accent: #6c5ce7;
  --color-success: #2ecc71;
  --color-warning: #f39c12;
  --color-error: #e74c3c;
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Inter', sans-serif;
  background-color: var(--color-background);
  color: var(--color-foreground);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* React Flow overrides */
.react-flow__background {
  background-color: var(--color-background) !important;
}

.react-flow__minimap {
  background-color: var(--color-surface) !important;
  border: 1px solid var(--color-border) !important;
  border-radius: 8px !important;
}

.react-flow__controls {
  border: 1px solid var(--color-border) !important;
  border-radius: 8px !important;
  overflow: hidden;
}

.react-flow__controls-button {
  background-color: var(--color-surface) !important;
  color: var(--color-foreground) !important;
  border-bottom: 1px solid var(--color-border) !important;
}

.react-flow__controls-button:hover {
  background-color: var(--color-elevated) !important;
}

/* Mermaid overrides */
.mermaid {
  background: transparent !important;
}

/* Scrollbar styling */
::-webkit-scrollbar {
  width: 6px;
  height: 6px;
}

::-webkit-scrollbar-track {
  background: var(--color-background);
}

::-webkit-scrollbar-thumb {
  background: var(--color-border);
  border-radius: 3px;
}

::-webkit-scrollbar-thumb:hover {
  background: var(--color-muted);
}

/* Highlight animation for cross-link navigation */
@keyframes highlight-pulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(124, 106, 247, 0); }
  50% { box-shadow: 0 0 0 4px rgba(124, 106, 247, 0.3); }
}

.highlight-pulse {
  animation: highlight-pulse 1.5s ease-in-out 3;
}
CSSEOF

# ============================================================
# Write src/types/index.ts
# ============================================================
cat > src/types/index.ts << 'TYPESEOF'
// ==========================================
// VIEW IDS AND CROSS-LINKING
// ==========================================

export type ViewId =
  | 'overview'
  | 'components'
  | 'data-flow'
  | 'sequences'
  | 'erd'
  | 'state-machines'
  | 'api'
  | 'dependencies'
  | 'tech-stack'
  | 'adrs';

export interface CrossLink {
  targetView: ViewId;
  targetId: string;
  label: string;
}

// ==========================================
// src/data/metadata.ts
// ==========================================

export interface SiteMetadata {
  projectName: string;
  description: string;
  stats: {
    totalFiles: number;
    totalLines: number;
    languages: { name: string; percentage: number }[];
    componentCount: number;
    endpointCount: number;
    entityCount: number;
  };
  generatedAt: string;
}

// ==========================================
// src/data/architecture.ts (View 1)
// ==========================================

export interface ArchitectureData {
  layers: ArchLayer[];
  nodes: ArchNode[];
  edges: ArchEdge[];
}

export interface ArchLayer {
  id: string;
  label: string;
  y: number;
}

export interface ArchNode {
  id: string;
  label: string;
  type: 'service' | 'app' | 'database' | 'external-api' | 'third-party' | 'queue' | 'cache' | 'storage';
  layerId: string;
  description: string;
  filePaths: string[];
  crossLinks: CrossLink[];
}

export interface ArchEdge {
  id: string;
  source: string;
  target: string;
  label: string;
  animated: boolean;
}

// ==========================================
// src/data/components.ts (View 2)
// ==========================================

export interface ComponentGraphData {
  nodes: CompNode[];
  edges: CompEdge[];
  rootNodeIds: string[];
}

export interface CompNode {
  id: string;
  label: string;
  type: 'screen' | 'component' | 'hook' | 'service' | 'store' | 'utility' | 'module';
  parentId: string | null;
  childIds: string[];
  description: string;
  filePath: string;
  crossLinks: CrossLink[];
}

export interface CompEdge {
  id: string;
  source: string;
  target: string;
  label: string;
}

// ==========================================
// src/data/dataflow.ts (View 3)
// ==========================================

export interface DataFlowData {
  flows: DataFlowEntry[];
}

export interface DataFlowEntry {
  id: string;
  title: string;
  description: string;
  nodes: DFNode[];
  edges: DFEdge[];
}

export interface DFNode {
  id: string;
  label: string;
  category: 'source' | 'process' | 'store' | 'sink';
  description: string;
  crossLinks: CrossLink[];
}

export interface DFEdge {
  id: string;
  source: string;
  target: string;
  label: string;
  animated: true;
}

// ==========================================
// src/data/sequences.ts (View 4)
// ==========================================

export interface SequenceDiagramData {
  diagrams: SequenceDiagram[];
}

export interface SequenceDiagram {
  id: string;
  title: string;
  description: string;
  mermaid: string;
  relatedComponents: CrossLink[];
  relatedEntities: CrossLink[];
}

// ==========================================
// src/data/erd.ts (View 5)
// ==========================================

export interface ERDData {
  mermaid: string;
  entities: EntityDetail[];
}

export interface EntityDetail {
  id: string;
  name: string;
  source: 'prisma' | 'sql' | 'typescript' | 'graphql' | 'protobuf' | 'inferred';
  fields: { name: string; type: string; isPrimary: boolean; isRelation: boolean }[];
  description: string;
  crossLinks: CrossLink[];
}

// ==========================================
// src/data/stateMachines.ts (View 6)
// ==========================================

export interface StateMachineData {
  machines: StateMachine[];
}

export interface StateMachine {
  id: string;
  title: string;
  entity: string;
  description: string;
  mermaid: string;
  relatedComponents: CrossLink[];
}

// ==========================================
// src/data/apiContracts.ts (View 7)
// ==========================================

export interface APIContractData {
  groups: APIGroup[];
}

export interface APIGroup {
  id: string;
  name: string;
  endpoints: APIEndpoint[];
}

export interface APIEndpoint {
  id: string;
  method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  path: string;
  description: string;
  auth: boolean;
  requestShape: Record<string, unknown> | null;
  responseShape: Record<string, unknown> | null;
  errorCodes: { code: number; message: string }[];
  crossLinks: CrossLink[];
}

// ==========================================
// src/data/dependencies.ts (View 8)
// ==========================================

export interface DependencyGraphData {
  nodes: DepNode[];
  edges: DepEdge[];
  circularDeps: string[][];
}

export interface DepNode {
  id: string;
  label: string;
  filePath: string;
  directory: string;
  linesOfCode: number;
  moduleType: string;
  isCircular: boolean;
}

export interface DepEdge {
  id: string;
  source: string;
  target: string;
  isCircular: boolean;
}

// ==========================================
// src/data/techStack.ts (View 9)
// ==========================================

export interface TechStackData {
  categories: TechCategory[];
}

export interface TechCategory {
  name: string;
  technologies: TechItem[];
}

export interface TechItem {
  id: string;
  name: string;
  category: 'Frontend' | 'Backend' | 'Database' | 'Auth' | 'Payments' | 'Monitoring' | 'AI' | 'DevOps' | 'Testing' | 'Tooling';
  version: string | null;
  roleInProject: string;
  docsUrl: string;
  usedBy: CrossLink[];
}

// ==========================================
// src/data/adrs.ts (View 10)
// ==========================================

export interface ADRData {
  records: ADR[];
}

export interface ADR {
  id: string;
  number: number;
  title: string;
  status: 'Accepted' | 'Proposed' | 'Deprecated';
  date: string;
  context: string;
  decision: string;
  consequences: string;
  relatedComponents: CrossLink[];
}

// ==========================================
// SEARCH
// ==========================================

export interface SearchEntry {
  id: string;
  name: string;
  type: 'architecture' | 'component' | 'data-flow' | 'sequence' | 'entity' | 'state-machine' | 'api-endpoint' | 'dependency' | 'technology' | 'adr';
  description: string;
  view: ViewId;
}
TYPESEOF

# ============================================================
# Remove default Vite boilerplate
# ============================================================
rm -f src/App.css src/App.tsx src/main.tsx src/assets/react.svg public/vite.svg 2>/dev/null || true

# ============================================================
# Output
# ============================================================
echo "$DOCS_DIR"
