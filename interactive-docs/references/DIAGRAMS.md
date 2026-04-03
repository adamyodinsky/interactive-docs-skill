# Diagram Generation Rules

This document defines exactly how the Diagram Architect subagent transforms `ProjectAnalysis` data into the 11 data files consumed by the generated documentation site. Each section covers one view.

Read [TYPES.md](./TYPES.md) first — it defines the exact TypeScript types you must export.

---

## General Rules

1. **Every data file** must `import type` from `'../types'` and `export default` a typed constant.
2. **Every ID** must use the correct prefix from TYPES.md (arch-, comp-, df-, etc.).
3. **Cross-links must be bidirectional.** If entity-user links to api-get-users, then api-get-users must link back to entity-user.
4. **No placeholder data.** Every node, entity, endpoint must come from the ProjectAnalysis. If a section is empty, export an empty structure (e.g., `{ flows: [] }`).
5. **Mermaid strings must be valid.** Follow the Mermaid safety rules at the bottom of this document.

---

## View 1: System Overview (`src/data/architecture.ts`)

**Type**: `ArchitectureData`
**Renderer**: React Flow

### How to Derive

1. **Identify layers.** Group the project's components into horizontal bands:
   - **Client Layer** (y: 0): Frontend apps, mobile apps, CLI tools
   - **API Layer** (y: 200): API servers, edge functions, gateways, BFF
   - **Service Layer** (y: 400): Business logic services, workers, queues, background jobs
   - **Data Layer** (y: 600): Databases, caches, file storage, search engines
   - **External Layer** (y: 800): Third-party APIs, SaaS services, payment providers

   Not every project has all layers. Use only those that exist. Adjust y values proportionally.

2. **Create nodes.** For each major system component:
   - Derive from: `modules` (top-level only), `externalServices`, `techStack` (databases, caches)
   - One node per service/app/database/external service — NOT one per file
   - Choose `type` based on what it is: service, app, database, external-api, third-party, queue, cache, storage
   - Description: 1-2 sentences about its role
   - filePaths: the main files that implement this component
   - crossLinks: link to related components (comp-), entities (entity-), API groups (api-)

3. **Create edges.** For each communication channel between nodes:
   - Label with protocol AND data type: "REST + JSON", "SQL queries", "WebSocket events", "gRPC + Protobuf", "Redis pub/sub"
   - Set `animated: true` for real-time connections (WebSocket, pub/sub, streaming)
   - Set `animated: false` for request-response connections (REST, SQL)

### Layout Rules
- Nodes within the same layer are spaced horizontally with 250px gaps
- Layers are spaced vertically with 200px gaps
- Center-align nodes within each layer
- Keep the total number of nodes between 4-15 (merge small services into logical groups if needed)

---

## View 2: Component/Module Graph (`src/data/components.ts`)

**Type**: `ComponentGraphData`
**Renderer**: React Flow with drill-down

### How to Derive

1. **Build the hierarchy.** From `modules` and `components`:
   - Top level (rootNodeIds): major directories or conceptual modules (auth, api, ui, data, utils)
   - Second level: files/components within each module
   - Third level (if applicable): sub-components or methods within complex files

2. **Create nodes.** For each module/component:
   - `parentId`: the ID of the containing module (null for root nodes)
   - `childIds`: IDs of children (empty for leaf nodes)
   - `type`: screen, component, hook, service, store, utility, module
   - crossLinks: link to sequences it appears in (seq-), APIs it calls (api-), entities it uses (entity-)

3. **Create edges.** For import/usage relationships between nodes at the SAME level:
   - Label: "imports", "uses", "provides", "extends"
   - Only create edges between nodes that are siblings (same parent) or between root nodes
   - Do NOT create edges between nodes at different hierarchy levels — the parent-child relationship handles that

### Node Type Visual Hints (for the Site Builder)
- `screen`: represents a page/route — most prominent
- `component`: UI building block
- `hook`: logic encapsulation (React hooks, composables)
- `service`: data fetching / business logic
- `store`: state container
- `utility`: helper functions
- `module`: directory-level grouping

---

## View 3: Data Flow (`src/data/dataflow.ts`)

**Type**: `DataFlowData`
**Renderer**: React Flow with animated edges

### How to Derive

1. **Select flows.** Choose the 2-3 most important data flows from `keyFlows`:
   - The primary user action (what the app mainly does)
   - Authentication/authorization (if present)
   - Data persistence (how data gets saved)

2. **For each flow, create nodes:**
   - **Source** (category: 'source'): where data originates — user input, external trigger, webhook, cron
   - **Process** (category: 'process'): validation, transformation, business logic steps
   - **Store** (category: 'store'): database write, cache update, state mutation
   - **Sink** (category: 'sink'): UI render, API response, notification, email

3. **Create edges** between nodes in sequence:
   - Label with the data shape being passed: `{ email, password }`, `{ userId, token, expiresAt }`
   - ALL edges must have `animated: true` (this is a data flow diagram)
   - Use real field names from the ProjectAnalysis entities and API shapes

### Layout Rules
- Flows go left-to-right: source → process → store → sink
- Each flow is a separate entry in the `flows` array
- Nodes within a flow are spaced 200px apart horizontally
- Keep each flow to 4-8 nodes (merge trivial steps)

---

## View 4: Sequence Diagrams (`src/data/sequences.ts`)

**Type**: `SequenceDiagramData`
**Renderer**: Mermaid

### How to Derive

1. **One diagram per key flow** from `keyFlows`. Typical diagrams:
   - Authentication flow
   - Core feature action
   - Data sync / refresh
   - Error handling
   - Payment / subscription (if applicable)

2. **Convert each flow to Mermaid syntax:**

```
sequenceDiagram
    participant A as ActorName
    participant B as ServiceName
    A->>B: action description
    activate B
    B->>C: next step
    C-->>B: response
    deactivate B
    B-->>A: final response
    alt Error case
        B-->>A: error response
    end
```

3. **Rules:**
   - Use REAL actor names from the project (component names, service names), not generic "Client" / "Server"
   - Include `activate`/`deactivate` for async operations
   - Include `alt` blocks for error paths
   - Include `Note` blocks for important context
   - Maximum 15 participants per diagram
   - Maximum 30 messages per diagram (split complex flows into multiple diagrams)

4. **Cross-links:**
   - `relatedComponents`: link to comp- IDs for each actor that is a component
   - `relatedEntities`: link to entity- IDs for data models mentioned in the flow

---

## View 5: Entity-Relationship Diagram (`src/data/erd.ts`)

**Type**: `ERDData`
**Renderer**: Mermaid

### How to Derive

1. **Build the Mermaid erDiagram string** from `entities`:

```
erDiagram
    User {
        string id PK
        string email
        string name
        datetime createdAt
    }
    Post {
        string id PK
        string title
        string content
        string authorId FK
    }
    User ||--o{ Post : "has many"
```

2. **Cardinality notation:**
   - `||--||` : one-to-one
   - `||--o{` : one-to-many
   - `}o--o{` : many-to-many

3. **Field formatting:**
   - Include type and field name
   - Mark primary keys with `PK`
   - Mark foreign keys with `FK`
   - Limit to the most important fields (max 8 per entity to keep diagram readable)

4. **Entity detail cards** (the `entities` array):
   - Include ALL fields (not just the ones in the diagram)
   - crossLinks: link to API endpoints that expose this entity (api-), components that display it (comp-), state machines for it (sm-)

---

## View 6: State Machines (`src/data/stateMachines.ts`)

**Type**: `StateMachineData`
**Renderer**: Mermaid

### How to Derive

1. **One diagram per state model** from `stateModels`:

```
stateDiagram-v2
    [*] --> Idle
    Idle --> Loading : fetch()
    Loading --> Success : data received
    Loading --> Error : request failed
    Error --> Loading : retry()
    Success --> [*]
```

2. **Rules:**
   - Always include `[*] -->` for initial state
   - Include `--> [*]` for terminal states
   - Include error states and loading states — not just happy-path
   - State names must not contain spaces (use PascalCase: `LoggedIn`, `FetchingData`)
   - Transition labels should name the trigger (function name, event name, user action)

3. **Cross-links:**
   - `relatedComponents`: components that drive these state transitions

---

## View 7: API Contracts (`src/data/apiContracts.ts`)

**Type**: `APIContractData`
**Renderer**: Custom React component

### How to Derive

1. **Group endpoints** by resource domain:
   - Group by the first path segment after the base: `/auth/*` → "Authentication", `/users/*` → "Users"
   - If no clear grouping, group by related entity

2. **For each endpoint:**
   - `id`: `api-<method>-<path-kebab>` (e.g., `api-post-auth-login`, `api-get-users-id`)
   - `method`: HTTP method
   - `path`: full path including parameters (`:id`, `{id}`)
   - `auth`: whether authentication is required
   - `requestShape`: actual field names and types as a JSON object (or null for GET)
   - `responseShape`: actual response structure as a JSON object
   - `errorCodes`: known error responses with codes and messages
   - crossLinks: link to entities (entity-), components that call this (comp-)

3. **requestShape and responseShape format:**
   - Use simple JSON with type annotations as values: `{ "email": "string", "password": "string" }`
   - For nested objects: `{ "user": { "id": "string", "name": "string" }, "token": "string" }`
   - For arrays: `{ "users": "[User]", "total": "number" }`

---

## View 8: Dependency Graph (`src/data/dependencies.ts`)

**Type**: `DependencyGraphData`
**Renderer**: React Flow

### How to Derive

1. **Create nodes** from `dependencyGraph` entries and `modules`:
   - `id`: `dep-<kebab-file-path>` (e.g., `dep-src-services-auth`)
   - `linesOfCode`: from the module's LOC data
   - `directory`: the top-level directory (src/services, src/components, etc.)
   - `moduleType`: from the module's type field
   - `isCircular`: true if this node participates in any cycle

2. **Create edges** from import relationships:
   - `source`: the importing file's node ID
   - `target`: the imported file's node ID
   - `isCircular`: true if this edge is part of a cycle

3. **Detect circular dependencies:**
   - Run a DFS-based cycle detection on the import graph
   - Store each cycle as an array of node IDs in `circularDeps`
   - Mark all nodes and edges in cycles with `isCircular: true`

4. **Node sizing** (for the Site Builder):
   - The Site Builder will size nodes proportionally to `linesOfCode`
   - Include this data accurately

### Filtering metadata
- The `directory` field enables filtering by directory in the UI
- The `moduleType` field enables filtering by type (component, service, etc.)

---

## View 9: Tech Stack (`src/data/techStack.ts`)

**Type**: `TechStackData`
**Renderer**: Custom card grid

### How to Derive

1. **Group by category** from `techStack` entries:
   - Frontend, Backend, Database, Auth, Payments, Monitoring, AI, DevOps, Testing, Tooling
   - Only include categories that have entries

2. **For each technology:**
   - `id`: `tech-<kebab-name>` (e.g., `tech-react`, `tech-prisma`)
   - `version`: from package manifest
   - `roleInProject`: specific to THIS project, not generic ("Handles JWT-based authentication and session management", not "Auth library")
   - `docsUrl`: official documentation URL
   - `usedBy`: crossLinks to components that import/use this technology

### Common docsUrl mappings
- React: https://react.dev
- Next.js: https://nextjs.org/docs
- Vue: https://vuejs.org/guide
- Svelte: https://svelte.dev/docs
- Express: https://expressjs.com
- Prisma: https://www.prisma.io/docs
- Tailwind: https://tailwindcss.com/docs
- TypeScript: https://www.typescriptlang.org/docs

For less common libraries, construct from the npm/PyPI package name.

---

## View 10: Architecture Decision Records (`src/data/adrs.ts`)

**Type**: `ADRData`
**Renderer**: Markdown timeline

### How to Derive

1. **Convert each `adrSuggestion`** into a full ADR:
   - `id`: `adr-<number>-<kebab-title>` (number starting at 001)
   - `number`: sequential, starting at 1
   - `status`: "Accepted" for decisions clearly in use, "Proposed" for patterns that seem experimental
   - `date`: attempt to infer from git history or package.json. If unknown, use "unknown"
   - `context`, `decision`, `consequences`: expand the suggestion's fields into full Markdown paragraphs

2. **Standard ADRs to always generate** (if evidence exists):
   - ADR-001: Framework choice (why React/Vue/Svelte/etc.)
   - ADR-002: State management approach (why Redux/Zustand/Context/etc.)
   - ADR-003: Database/backend choice (why Postgres/Supabase/Firebase/etc.)
   - ADR-004: Auth strategy (why JWT/sessions/OAuth/etc.)

3. **Additional ADRs** for any non-obvious patterns:
   - Monorepo structure and tooling choice
   - API design (REST vs GraphQL vs tRPC)
   - Styling approach (Tailwind vs CSS modules vs styled-components)
   - Deployment target (Vercel, AWS, self-hosted)
   - Any architectural pattern that a new developer would question

4. **Cross-links:**
   - `relatedComponents`: link to comp- IDs for components most affected by this decision

---

## Metadata (`src/data/metadata.ts`)

**Type**: `SiteMetadata`

### How to Derive

Directly from `ProjectAnalysis.metadata`:
- `projectName`: from metadata.name
- `description`: from metadata.description
- `stats`: aggregate from metadata + count entities/endpoints/components
- `generatedAt`: current ISO date string

---

## Cross-Linking Strategy

Cross-links are what make this a documentation **portal** instead of 10 separate pages. Every entity that appears in multiple views must link to its counterparts.

### Mandatory Cross-Link Patterns

| Source | Target | When |
|--------|--------|------|
| arch-* node | comp-* nodes | When the architecture component contains these modules |
| arch-* node | entity-* | When the architecture component owns these data models |
| comp-* node | api-* endpoints | When the component calls these APIs |
| comp-* node | entity-* | When the component displays/modifies these entities |
| comp-* node | seq-* diagrams | When the component appears as an actor in the sequence |
| comp-* node | sm-* machines | When the component drives these state transitions |
| entity-* | api-* endpoints | When the entity is exposed/modified by these endpoints |
| entity-* | comp-* nodes | When the entity is displayed by these components |
| entity-* | sm-* machines | When the entity has a state machine |
| api-* endpoint | entity-* | When the endpoint involves these entities |
| api-* endpoint | comp-* nodes | When these components call this endpoint |
| seq-* diagram | comp-* nodes | When these components are actors in the sequence |
| sm-* machine | comp-* nodes | When these components drive the state transitions |
| tech-* item | comp-* nodes | When these components use this technology |
| adr-* record | comp-* nodes | When these components are most affected by this decision |

### Cross-Link Validation

Before writing data files, verify:
- Every crossLink references an ID that exists in another data file
- Links are bidirectional (if A→B exists, B→A must exist)
- No self-links
- No links to non-existent IDs

---

## Mermaid Safety Rules

Mermaid syntax is fragile. Follow these rules to avoid rendering failures.

### Character Escaping
- **Quotes in labels**: Use HTML entities or remove quotes entirely
- **Special characters** in entity/state names: Avoid `(`, `)`, `[`, `]`, `{`, `}`, `#`, `;`, `:` in names
- **Spaces in names**: Use camelCase or PascalCase for state names. For sequence diagram participants, use the `participant X as "Display Name"` syntax
- **Colons in labels**: Mermaid uses `:` as a delimiter. If your label contains a colon, wrap the entire label in quotes

### Sequence Diagram Safety
```
# GOOD
participant Auth as AuthService
Auth->>DB: Query user by email

# BAD - will break
participant Auth Service    # spaces in participant name
Auth->>DB: Query: user      # colon in message without quotes
```

### ERD Safety
```
# GOOD
User {
    string id PK
    string email
}

# BAD - will break
User Profile {              # spaces in entity name
    string "email address"  # quotes in field name
}
```

### State Diagram Safety
```
# GOOD
stateDiagram-v2
    [*] --> Idle
    Idle --> Loading : fetch
    Loading --> Error : fail

# BAD - will break
stateDiagram-v2
    [*] --> idle state     # spaces in state name
    idle --> loading : fetch()  # parentheses in trigger label can cause issues in some versions
```

### Size Limits
- **ERD**: Max 20 entities per diagram. If more, split into domain-specific sub-diagrams or show only the most important entities.
- **Sequence diagrams**: Max 15 participants, 30 messages. Split complex flows.
- **State diagrams**: Max 15 states per diagram. Nest complex state machines.

### Testing Mermaid Strings
Before writing a Mermaid string to a data file, mentally verify:
1. Every participant/entity/state name has no spaces or special characters
2. Every arrow syntax is correct (`->>`, `-->>`, `-->`, `||--o{`)
3. Every `activate` has a matching `deactivate`
4. Every `alt` has a matching `end`
5. The diagram type declaration is the first line (`sequenceDiagram`, `erDiagram`, `stateDiagram-v2`)

---

## Empty State Handling

When a section of ProjectAnalysis has no data, export a valid but empty structure:

```typescript
// No API endpoints found
const data: APIContractData = { groups: [] };
export default data;

// No state machines found  
const data: StateMachineData = { machines: [] };
export default data;

// No entities found
const data: ERDData = { mermaid: '', entities: [] };
export default data;
```

The Site Builder will show contextual empty-state messages like "No API endpoints detected in this project" — not a blank page or error.

---

## Final Checklist

Before finishing, verify:

- [ ] All 11 data files written to src/data/
- [ ] Every file imports types from '../types' and exports default
- [ ] Every ID uses the correct prefix
- [ ] Cross-links are bidirectional and reference real IDs
- [ ] Mermaid strings follow the safety rules above
- [ ] No placeholder or fabricated data
- [ ] Empty sections export valid empty structures
- [ ] Run `npx tsc --noEmit` in the docs directory — fix any type errors
