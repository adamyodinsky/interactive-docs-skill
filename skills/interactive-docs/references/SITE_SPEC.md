# Generated Site Specification

This document defines exactly how the Site Builder subagent constructs the React application. Read [TYPES.md](./TYPES.md) first — it defines every type your components import.

---

## Project Structure

Write these files in the generated `<project-name>-docs/` directory. The scaffold script has already created the directory structure and installed dependencies.

```
src/
├── main.tsx                          # React DOM render + BrowserRouter
├── App.tsx                           # Route definitions + layout
├── index.css                         # Already written by scaffold.sh
├── types/
│   └── index.ts                      # Already written by scaffold.sh
├── data/                             # Already written by Diagram Architect
│   └── *.ts
├── hooks/
│   ├── useTheme.ts                   # Dark/light mode with localStorage
│   ├── useSearch.ts                  # Fuse.js search across all views
│   ├── useKeyboardShortcuts.ts       # Global keyboard shortcuts
│   └── useCrossLinks.ts             # Cross-link navigation
├── utils/
│   ├── searchIndex.ts               # Build Fuse.js index from all data files
│   └── idUtils.ts                   # ID resolution and view lookup
├── components/
│   ├── layout/
│   │   ├── Sidebar.tsx              # Navigation sidebar
│   │   ├── Topbar.tsx               # Project name + search + theme toggle
│   │   ├── DetailPanel.tsx          # Right-side detail panel
│   │   └── Breadcrumb.tsx           # View breadcrumb trail
│   ├── shared/
│   │   ├── ReactFlowCanvas.tsx      # Shared React Flow wrapper
│   │   ├── MermaidDiagram.tsx       # Shared Mermaid renderer
│   │   ├── SearchModal.tsx          # Cmd+K search modal
│   │   ├── CrossLinkChip.tsx        # Clickable cross-link badge
│   │   ├── EntityCard.tsx           # Reusable entity detail card
│   │   └── JsonTree.tsx             # Collapsible JSON viewer
│   └── nodes/
│       ├── ArchitectureNode.tsx     # System Overview custom node
│       ├── ComponentNode.tsx        # Component Graph custom node
│       ├── DataFlowNode.tsx         # Data Flow custom node
│       └── DependencyNode.tsx       # Dependency Graph custom node
└── views/
    ├── SystemOverview.tsx           # View 1: React Flow
    ├── ComponentGraph.tsx           # View 2: React Flow with drill-down
    ├── DataFlow.tsx                 # View 3: React Flow with animated edges
    ├── SequenceDiagrams.tsx         # View 4: Mermaid gallery
    ├── ERDView.tsx                  # View 5: Mermaid + entity cards
    ├── StateMachines.tsx            # View 6: Mermaid gallery
    ├── APIContracts.tsx             # View 7: Custom endpoint list
    ├── DependencyGraph.tsx          # View 8: React Flow
    ├── TechStack.tsx                # View 9: Card grid
    └── ADRTimeline.tsx              # View 10: Markdown timeline
```

---

## Writing Order

Write files in this order to avoid import errors:

1. `src/hooks/` (all 4 hooks)
2. `src/utils/` (both utilities)
3. `src/components/shared/` (all 6 shared components)
4. `src/components/nodes/` (all 4 custom nodes)
5. `src/components/layout/` (all 4 layout components)
6. `src/views/` (all 10 views)
7. `src/App.tsx`
8. `src/main.tsx`

---

## Layout Architecture

The app uses a CSS Grid layout:

```
┌──────────────────────────────────────────────────┐
│                    Topbar (56px)                  │
├─────────┬──────────────────────┬─────────────────┤
│         │                      │                  │
│ Sidebar │     Main Content     │  Detail Panel    │
│ (240px) │     (flexible)       │  (380px)         │
│         │                      │  (slide-in)      │
│         │                      │                  │
└─────────┴──────────────────────┴─────────────────┘
```

**App.tsx layout:**
```tsx
<div className="h-screen flex flex-col bg-background text-foreground">
  <Topbar />
  <div className="flex flex-1 overflow-hidden">
    <Sidebar />
    <main className="flex-1 overflow-auto">
      <Routes>
        {/* view routes */}
      </Routes>
    </main>
    <DetailPanel />
  </div>
</div>
```

The Sidebar is collapsible (toggled by button). When collapsed, it shows only icons (48px wide). The DetailPanel slides in from the right when an entity is selected, pushed by state — not by route.

---

## Routing

```tsx
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';

<BrowserRouter>
  <Routes>
    <Route path="/" element={<SystemOverview />} />
    <Route path="/components" element={<ComponentGraph />} />
    <Route path="/data-flow" element={<DataFlow />} />
    <Route path="/sequences" element={<SequenceDiagrams />} />
    <Route path="/erd" element={<ERDView />} />
    <Route path="/state-machines" element={<StateMachines />} />
    <Route path="/api" element={<APIContracts />} />
    <Route path="/dependencies" element={<DependencyGraph />} />
    <Route path="/tech-stack" element={<TechStack />} />
    <Route path="/adrs" element={<ADRTimeline />} />
    <Route path="*" element={<Navigate to="/" replace />} />
  </Routes>
</BrowserRouter>
```

---

## Theming

### CSS Custom Properties

The scaffold writes these to `src/index.css`. Components use them via Tailwind's `bg-background`, `text-foreground`, etc. or directly as `var(--color-background)`.

**Dark theme (default):**
```css
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
```

**Light theme:**
```css
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
```

### useTheme Hook
```typescript
// Manages dark/light mode, persists to localStorage
export function useTheme() {
  const [theme, setTheme] = useState<'dark' | 'light'>(() => {
    return (localStorage.getItem('theme') as 'dark' | 'light') || 'dark';
  });

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('theme', theme);
  }, [theme]);

  const toggle = () => setTheme(t => t === 'dark' ? 'light' : 'dark');

  return { theme, toggle };
}
```

### Typography

Loaded via Google Fonts in index.html (already done by scaffold):
- **Headings / node labels**: `'Space Mono', monospace`
- **Body / descriptions**: `'Inter', sans-serif`
- **Code / file paths / JSON**: `'JetBrains Mono', monospace`

Tailwind config maps these:
```js
fontFamily: {
  display: ['Space Mono', 'monospace'],
  sans: ['Inter', 'sans-serif'],
  mono: ['JetBrains Mono', 'monospace'],
}
```

---

## Component Specifications

### Sidebar.tsx

- Fixed left, 240px wide, collapsible to 48px (icon-only)
- Background: `var(--color-surface)`
- Border-right: `1px solid var(--color-border)`
- Shows project name at top (from metadata)
- 10 navigation items, one per view, each with:
  - Icon (from lucide-react): Layout (overview), GitBranch (components), Activity (data-flow), MessageSquare (sequences), Database (erd), Repeat (state-machines), Globe (api), Network (dependencies), Layers (tech-stack), FileText (adrs)
  - Label (hidden when collapsed)
  - Active state: accent background, accent text
- Uses `NavLink` from react-router-dom for active detection
- Collapse toggle button at bottom

### Topbar.tsx

- Fixed top, 56px height
- Background: `var(--color-surface)`
- Border-bottom: `1px solid var(--color-border)`
- Left: project name in `font-display` (links to /)
- Center: nothing (clean)
- Right: Search button (opens SearchModal), Theme toggle (Sun/Moon icons)
- Search button shows `Cmd+K` hint badge

### DetailPanel.tsx

- Slides in from right, 380px wide
- Background: `var(--color-surface)`
- Border-left: `1px solid var(--color-border)`
- Only visible when an entity is selected (managed via React state in App or a context)
- Close button (X) in top-right corner
- Content adapts to what's selected:
  - **Architecture node**: name, type badge, description, file paths, cross-links
  - **Component node**: name, type badge, description, file path, child count, cross-links
  - **Data flow node**: name, category badge, description, cross-links
  - **Entity**: name, source badge, all fields listed, relationships, cross-links
  - **API endpoint**: method badge (colored), path, description, request/response shapes (JsonTree), error codes, cross-links
  - **State machine**: entity name, states listed, transitions, cross-links
  - **Tech item**: name, version, category, role description, docs link, used-by cross-links
  - **ADR**: title, status badge, date, context/decision/consequences as markdown
- Cross-links section at the bottom: rendered as CrossLinkChip components
- Animated entrance: `framer-motion` slide from right, 200ms

### Breadcrumb.tsx

- Shows in views that support drill-down (Component Graph)
- Format: `Components > auth > AuthProvider`
- Each segment is clickable, navigates to that level
- Current segment is bold with accent color

### ReactFlowCanvas.tsx (Shared)

Wraps `@xyflow/react` with standard configuration for all 4 React Flow views.

**Props:**
```typescript
interface ReactFlowCanvasProps {
  nodes: Node[];
  edges: Edge[];
  nodeTypes: NodeTypes;
  onNodeClick?: (event: React.MouseEvent, node: Node) => void;
  onEdgeClick?: (event: React.MouseEvent, edge: Edge) => void;
  fitViewOnInit?: boolean;
}
```

**Features:**
- Scroll to zoom, drag to pan
- Minimap in bottom-right corner (always visible)
- Controls in bottom-left: zoom in, zoom out, fit view
- Background: dots pattern on `var(--color-background)`
- Default edge style: stroke `var(--color-border)`, animated edges use accent color
- Double-click background: fit all nodes to screen
- `fitView` on initial render

**Import:**
```tsx
import { ReactFlow, MiniMap, Controls, Background, useNodesState, useEdgesState } from '@xyflow/react';
import '@xyflow/react/dist/style.css';
```

### MermaidDiagram.tsx (Shared)

Renders a Mermaid diagram string with interactive controls.

**Props:**
```typescript
interface MermaidDiagramProps {
  id: string;
  source: string;    // Mermaid source string
  title?: string;
  className?: string;
}
```

**Features:**
- Lazy rendering: only renders when the component is visible (use IntersectionObserver)
- Renders using `mermaid.render()` API
- Zoom: CSS transform-based zoom with mouse wheel
- Fullscreen button: opens diagram in a modal overlay
- "Copy Source" button: copies raw Mermaid string to clipboard
- Error handling: if Mermaid fails to render, show the source string in a code block with an error message
- Theme: use Mermaid's `dark` theme, customize with CSS variables

**Mermaid initialization:**
```typescript
import mermaid from 'mermaid';

mermaid.initialize({
  startOnLoad: false,
  theme: 'dark',
  themeVariables: {
    primaryColor: '#7c6af7',
    primaryTextColor: '#e2e8f0',
    primaryBorderColor: '#2a2a32',
    lineColor: '#94a3b8',
    secondaryColor: '#1c1c21',
    tertiaryColor: '#141417',
  },
  securityLevel: 'loose',
});
```

### SearchModal.tsx

- Opens with Cmd+K (Mac) or Ctrl+K (Windows/Linux)
- Overlay: dark semi-transparent backdrop
- Modal: centered, 600px wide, max-height 500px
- Search input at top with magnifying glass icon
- Results below, grouped by type (Architecture, Components, Entities, APIs, etc.)
- Each result: name (bold), type badge, one-line description
- Keyboard navigation: arrow keys to move, Enter to select, Esc to close
- Click result: navigate to the view and highlight the entity (via URL param `?highlight=<id>`)
- Uses `fuse.js` with the search index built from all data files

### CrossLinkChip.tsx

- Small badge/pill that represents a cross-link
- Shows: icon (by target view type) + label
- Color-coded by target view
- Clickable: navigates to target view with `?highlight=<targetId>`
- Hover: shows tooltip with target view name

### EntityCard.tsx

Reusable card for displaying entity details (used in ERD view below diagram, and in DetailPanel).

**Props:**
```typescript
interface EntityCardProps {
  entity: EntityDetail;
  onCrossLinkClick: (link: CrossLink) => void;
}
```

- Shows: entity name, source badge, field list (name, type, PK/FK badges), cross-links

### JsonTree.tsx

Collapsible JSON tree viewer for API request/response shapes.

**Props:**
```typescript
interface JsonTreeProps {
  data: Record<string, unknown> | null;
  label?: string;
}
```

- Uses `react-json-view-lite` or a custom recursive renderer
- Collapsible nodes (expanded by default for top level, collapsed for nested)
- Themed to match the app's dark/light mode

---

## Custom React Flow Nodes

All custom nodes share these conventions:
- Background: `var(--color-elevated)`
- Border: `1px solid var(--color-border)`
- Border-radius: 8px
- Padding: 12px 16px
- Font: `font-display` for labels
- Hover: border changes to `var(--color-accent)`, slight shadow

### ArchitectureNode.tsx

For System Overview nodes.

- Type badge in top-left (colored by type: service=accent, database=success, external=warning)
- Label in center, `font-display`, 14px
- Description below label in `font-sans`, 12px, muted color
- Icon by type: Server (service), Database (database), Cloud (external-api), Box (third-party)
- Min-width: 180px

### ComponentNode.tsx

For Component Graph nodes.

- Type badge in top-left (colored by type)
- Label in center
- If has children: stacked-card shadow effect (2 layers), child count badge in bottom-right ("5 inside")
- If leaf: flat, code icon (`</>`) in bottom-right
- Different border colors by type:
  - screen: accent
  - component: default border
  - hook: success
  - service: warning
  - store: a teal/cyan (#06b6d4)
  - utility: muted

### DataFlowNode.tsx

For Data Flow nodes.

- Shape varies by category:
  - source: rounded left edge (pill-like left side)
  - process: standard rectangle
  - store: cylinder-like (rounded top and bottom)
  - sink: rounded right edge
- Color by category: source=accent, process=default, store=success, sink=warning
- Label centered, category badge on top

### DependencyNode.tsx

For Dependency Graph nodes.

- Size proportional to `linesOfCode` (min 80px, max 200px width)
- Color by directory (hash the directory name to a hue)
- If `isCircular`: red border (var(--color-error)), pulsing animation
- Label: file name (not full path), with directory shown as muted text below
- LOC count in bottom-right corner

---

## View Specifications

### SystemOverview.tsx (View 1)

- Uses ReactFlowCanvas with ArchitectureNode
- Nodes positioned by layer (use `layerId` to set y position, index within layer for x)
- Layer labels rendered as non-interactive horizontal bands behind nodes
- On node click: open DetailPanel with node details + cross-links
- Edge labels visible at midpoint

### ComponentGraph.tsx (View 2)

- Uses ReactFlowCanvas with ComponentNode
- **Drill-down behavior:**
  - Initial view: show only `rootNodeIds` nodes
  - Click a non-leaf node: transition to showing that node's children
  - Breadcrumb updates on each drill-down
  - "Back" navigates to parent level
- Track current parent ID in state
- Filter nodes/edges to current level on each render
- Use `dagre` or manual layout for node positioning at each level

### DataFlow.tsx (View 3)

- If multiple flows: tab selector at top to switch between flows
- Uses ReactFlowCanvas with DataFlowNode
- All edges animated (dots flowing along the edge)
- Edge labels show data shape
- Left-to-right layout: source → process → store → sink
- On node click: open DetailPanel

### SequenceDiagrams.tsx (View 4)

- Gallery layout: cards in a responsive grid (1-2 columns)
- Each card: title, description, MermaidDiagram component
- Cards are expandable to fullscreen
- Below each diagram: related component and entity chips (CrossLinkChip)

### ERDView.tsx (View 5)

- Top section: full ERD MermaidDiagram
- Bottom section: EntityCard grid for each entity
- If `erd.mermaid` is empty: show "No data models detected" message
- Entity cards are clickable: open DetailPanel with entity details

### StateMachines.tsx (View 6)

- Gallery layout: cards in a responsive grid
- Each card: title, entity name, MermaidDiagram component
- Related component chips below each diagram
- If `machines` is empty: show "No state machines detected" message

### APIContracts.tsx (View 7)

- Grouped by API group (collapsible sections)
- Each endpoint card:
  - Method badge (colored: GET=success, POST=accent, PUT=warning, PATCH=warning, DELETE=error)
  - Path in `font-mono`
  - Auth badge (lock icon if auth required)
  - Description
  - Expandable sections: Request Body (JsonTree), Response (JsonTree), Errors (list)
  - Cross-link chips at bottom
- If `groups` is empty: show "No API endpoints detected" message

### DependencyGraph.tsx (View 8)

- Uses ReactFlowCanvas with DependencyNode
- Toolbar above the graph:
  - Directory filter dropdown
  - Module type filter dropdown
  - "Show only circular deps" toggle
- Circular dependency edges: red color, thicker stroke
- Circular dependency nodes: red border, pulsing
- Legend showing what colors represent which directories

### TechStack.tsx (View 9)

- Card grid grouped by category
- Category headers as section dividers
- Each card:
  - Technology icon (use first letter as fallback if no icon)
  - Name and version badge
  - Role description
  - "Docs" link button (opens in new tab)
  - "Used by" cross-link chips
- Responsive: 1 col on small, 2 cols on medium, 3 cols on large

### ADRTimeline.tsx (View 10)

- Vertical timeline layout: line on the left, cards branching right
- Each card:
  - Number badge (ADR-001)
  - Title
  - Status badge (Accepted=success, Proposed=accent, Deprecated=muted)
  - Date (if available)
  - Expandable sections: Context, Decision, Consequences (rendered as Markdown via react-markdown)
  - Related component chips
- If `records` is empty: show "No architecture decisions recorded" message

---

## Keyboard Shortcuts

Implement in `useKeyboardShortcuts.ts`:

| Key | Action |
|-----|--------|
| `Cmd+K` / `Ctrl+K` | Open search modal |
| `[` | Navigate to previous view |
| `]` | Navigate to next view |
| `F` | Fit diagram to screen (React Flow views only) |
| `Esc` | Close detail panel or search modal |
| `D` | Toggle dark/light mode |

View order for `[`/`]`: overview → components → data-flow → sequences → erd → state-machines → api → dependencies → tech-stack → adrs (wraps around).

---

## Search Implementation

### searchIndex.ts

Builds a unified Fuse.js index from all data files:

```typescript
import Fuse from 'fuse.js';
import type { SearchEntry } from '../types';

// Import all data files and flatten into SearchEntry[]
// Architecture nodes, component nodes, entities, API endpoints,
// sequence diagrams, state machines, tech items, ADRs

export function buildSearchIndex(entries: SearchEntry[]): Fuse<SearchEntry> {
  return new Fuse(entries, {
    keys: ['name', 'description'],
    threshold: 0.3,
    includeScore: true,
  });
}
```

### useSearch.ts

```typescript
export function useSearch() {
  const [query, setQuery] = useState('');
  const [isOpen, setIsOpen] = useState(false);
  const [results, setResults] = useState<SearchEntry[]>([]);
  // ... Fuse.js search logic
  return { query, setQuery, isOpen, setIsOpen, results };
}
```

---

## Cross-Link Navigation

### idUtils.ts

Maps entity IDs to their view routes:

```typescript
export function getViewForId(id: string): ViewId {
  if (id.startsWith('arch-')) return 'overview';
  if (id.startsWith('comp-')) return 'components';
  if (id.startsWith('df-')) return 'data-flow';
  if (id.startsWith('seq-')) return 'sequences';
  if (id.startsWith('entity-')) return 'erd';
  if (id.startsWith('sm-')) return 'state-machines';
  if (id.startsWith('api-')) return 'api';
  if (id.startsWith('dep-')) return 'dependencies';
  if (id.startsWith('tech-')) return 'tech-stack';
  if (id.startsWith('adr-')) return 'adrs';
  return 'overview';
}

export function getRouteForView(view: ViewId): string {
  const routes: Record<ViewId, string> = {
    'overview': '/',
    'components': '/components',
    'data-flow': '/data-flow',
    'sequences': '/sequences',
    'erd': '/erd',
    'state-machines': '/state-machines',
    'api': '/api',
    'dependencies': '/dependencies',
    'tech-stack': '/tech-stack',
    'adrs': '/adrs',
  };
  return routes[view];
}
```

### useCrossLinks.ts

```typescript
import { useNavigate } from 'react-router-dom';
import { getRouteForView } from '../utils/idUtils';
import type { CrossLink } from '../types';

export function useCrossLinks() {
  const navigate = useNavigate();

  const navigateTo = (link: CrossLink) => {
    const route = getRouteForView(link.targetView);
    navigate(`${route}?highlight=${link.targetId}`);
  };

  return { navigateTo };
}
```

Views read the `highlight` search param on mount and scroll to / highlight the matching entity.

---

## Performance Rules

1. **Mermaid lazy rendering**: Only call `mermaid.render()` when the diagram is visible (IntersectionObserver). This prevents slow initial loads when all Mermaid views are mounted.

2. **React.memo for nodes**: All custom React Flow nodes must be wrapped in `React.memo` to prevent unnecessary re-renders during pan/zoom.

3. **Virtualization**: If a React Flow view has more than 100 nodes, enable React Flow's built-in node virtualization by not setting `nodesDraggable={false}`.

4. **Code splitting**: Use `React.lazy` for view components if the bundle size becomes an issue. Not required for initial implementation.

---

## Empty State Handling

Every view must handle the case where its data is empty. Show a centered message:

```tsx
function EmptyState({ message }: { message: string }) {
  return (
    <div className="flex items-center justify-center h-full text-muted">
      <p className="text-lg font-sans">{message}</p>
    </div>
  );
}
```

Messages by view:
- System Overview: "No architecture data available"
- Component Graph: "No components detected"
- Data Flow: "No data flows identified"
- Sequence Diagrams: "No sequence diagrams generated"
- ERD: "No data models detected in this project"
- State Machines: "No state machines detected"
- API Contracts: "No API endpoints detected in this project"
- Dependency Graph: "No dependency data available"
- Tech Stack: "No technologies detected"
- ADRs: "No architecture decisions recorded"

---

## Final Checklist

Before finishing, verify:

- [ ] All files written in the correct order
- [ ] Every component imports types from '../types'
- [ ] Every view imports its data from '../data/*'
- [ ] ReactFlowCanvas is used by all 4 React Flow views (not duplicated)
- [ ] MermaidDiagram is used by all 3 Mermaid views (not duplicated)
- [ ] CrossLinkChip is used everywhere cross-links appear
- [ ] DetailPanel adapts to different entity types
- [ ] Search indexes all entities across all views
- [ ] Keyboard shortcuts are registered
- [ ] Theme toggle works with localStorage persistence
- [ ] Empty states are handled for every view
- [ ] Run `npx tsc --noEmit` in the docs directory — fix any type errors
