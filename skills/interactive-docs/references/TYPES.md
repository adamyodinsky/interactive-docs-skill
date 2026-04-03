# Canonical Type Definitions

This file is the **single source of truth** for all TypeScript types used across every phase of interactive-docs generation. The scaffold script copies these types into the generated project's `src/types/index.ts`. Every subagent must read this file before writing any code.

---

## Cross-Linking System

Every entity across all views uses a strict ID prefix convention. Cross-links reference these IDs to navigate between views.

```typescript
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
```

### ID Prefix Convention

| View | Prefix | Example |
|------|--------|---------|
| System Overview | `arch-` | `arch-api-gateway` |
| Component Graph | `comp-` | `comp-auth-provider` |
| Data Flow | `df-` | `df-login-validate-creds` |
| Sequence Diagrams | `seq-` | `seq-auth-flow` |
| ERD | `entity-` | `entity-user` |
| State Machines | `sm-` | `sm-subscription-state` |
| API Contracts | `api-` | `api-post-auth-login` |
| Dependency Graph | `dep-` | `dep-src-services-auth` |
| Tech Stack | `tech-` | `tech-react` |
| ADRs | `adr-` | `adr-001-chose-react` |

**Rules**:
- IDs are globally unique across all data files
- Use kebab-case after the prefix
- Derive from real names in the codebase: `AuthProvider` → `comp-auth-provider`
- API IDs include method: `api-post-auth-login`, `api-get-users-id`
- Data flow IDs include flow name: `df-login-validate-creds`
- Cross-links must be **bidirectional**: if A links to B, B must link back to A

---

## ProjectAnalysis Types (Phase 2 Output)

This is the schema the Explorer subagent produces. The Diagram Architect consumes it to generate all data files.

```typescript
// ==========================================
// PROJECT ANALYSIS (Explorer Output)
// ==========================================

export interface ProjectAnalysis {
  metadata: ProjectMetadata;
  techStack: TechStackEntry[];
  externalServices: ExternalService[];
  modules: ModuleInfo[];
  components: ComponentInfo[];
  entities: EntityInfo[];
  apiEndpoints: ApiEndpointInfo[];
  keyFlows: KeyFlowInfo[];
  stateModels: StateModelInfo[];
  architecturalPatterns: PatternInfo[];
  adrSuggestions: AdrSuggestionInfo[];
  dependencyGraph: DepGraphEntry[];
}

export interface ProjectMetadata {
  name: string;
  description: string;
  totalFiles: number;
  totalLines: number;
  languages: { name: string; lines: number; percentage: number }[];
  frameworks: string[];
  entryPoints: string[];
}

export interface TechStackEntry {
  name: string;
  category: 'Frontend' | 'Backend' | 'Database' | 'Auth' | 'Payments' | 'Monitoring' | 'AI' | 'DevOps' | 'Testing' | 'Tooling';
  version: string | null;
  roleInProject: string;
  docsUrl: string;
  evidence: string; // import statement or config file that proves usage
}

export interface ExternalService {
  name: string;
  purpose: string;
  evidence: string; // env key or import
}

export interface ModuleInfo {
  name: string;
  filePath: string;
  description: string;
  type: 'screen' | 'component' | 'hook' | 'service' | 'store' | 'utility' | 'module' | 'config' | 'middleware' | 'handler';
  parentModule: string | null;
  children: string[]; // child module names
  imports: string[];   // what this module imports
  importedBy: string[]; // what imports this module
  linesOfCode: number;
}

export interface ComponentInfo {
  name: string;
  filePath: string;
  description: string;
  props: { name: string; type: string; required: boolean }[];
  usedIn: string[];     // parent component/screen names
  usesHooks: string[];
  usesServices: string[];
  usesComponents: string[];
}

export interface EntityInfo {
  name: string;
  source: 'prisma' | 'sql' | 'typescript' | 'graphql' | 'protobuf' | 'inferred';
  description: string;
  fields: EntityField[];
  relationships: EntityRelationship[];
}

export interface EntityField {
  name: string;
  type: string;
  isPrimary: boolean;
  isOptional: boolean;
  isRelation: boolean;
  description: string;
}

export interface EntityRelationship {
  targetEntity: string;
  type: 'one-to-one' | 'one-to-many' | 'many-to-many';
  fieldName: string;
  description: string;
}

export interface ApiEndpointInfo {
  method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  path: string;
  description: string;
  auth: boolean;
  requestShape: Record<string, unknown> | null;
  responseShape: Record<string, unknown> | null;
  errors: { code: number; message: string }[];
  sourceFile: string;
  relatedEntities: string[];   // entity names
  relatedComponents: string[]; // component names that call this
}

export interface KeyFlowInfo {
  name: string;
  description: string;
  actors: string[]; // real service/component names
  steps: FlowStep[];
  relatedComponents: string[];
  relatedEntities: string[];
}

export interface FlowStep {
  actor: string;
  action: string;
  target: string;
  data: string; // what data is passed
  isAsync: boolean;
  isError: boolean; // true if this is an error/failure path step
}

export interface StateModelInfo {
  entity: string;
  description: string;
  states: string[];
  initialState: string;
  terminalStates: string[];
  transitions: StateTransition[];
  relatedComponents: string[];
}

export interface StateTransition {
  from: string;
  to: string;
  trigger: string;
  description: string;
}

export interface PatternInfo {
  name: string;
  description: string;
  evidence: string[]; // file paths or code references
}

export interface AdrSuggestionInfo {
  title: string;
  context: string;
  decision: string;
  consequences: string;
  evidence: string[]; // file paths or config that informed this
}

export interface DepGraphEntry {
  filePath: string;
  imports: string[]; // file paths this file imports
}
```

---

## Data File Types (Phase 4A Output)

Each data file in `src/data/` exports a typed constant. The Site Builder imports and renders these.

```typescript
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
  generatedAt: string; // ISO date
}

// Export as: export const metadata: SiteMetadata = { ... };

// ==========================================
// src/data/architecture.ts (View 1: System Overview)
// ==========================================

export interface ArchitectureData {
  layers: ArchLayer[];
  nodes: ArchNode[];
  edges: ArchEdge[];
}

export interface ArchLayer {
  id: string;
  label: string;
  y: number; // vertical position for layout
}

export interface ArchNode {
  id: string;  // prefix: arch-
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
  label: string; // protocol + data type, e.g. "REST + JWT"
  animated: boolean;
}

// Export as: export const architecture: ArchitectureData = { ... };

// ==========================================
// src/data/components.ts (View 2: Component/Module Graph)
// ==========================================

export interface ComponentGraphData {
  nodes: CompNode[];
  edges: CompEdge[];
  rootNodeIds: string[]; // top-level IDs shown initially
}

export interface CompNode {
  id: string;  // prefix: comp-
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
  label: string; // "imports", "uses", "provides"
}

// Export as: export const componentGraph: ComponentGraphData = { ... };

// ==========================================
// src/data/dataflow.ts (View 3: Data Flow)
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
  id: string;  // prefix: df-
  label: string;
  category: 'source' | 'process' | 'store' | 'sink';
  description: string;
  crossLinks: CrossLink[];
}

export interface DFEdge {
  id: string;
  source: string;
  target: string;
  label: string; // data shape, e.g. "{ userId, token }"
  animated: true;
}

// Export as: export const dataFlow: DataFlowData = { ... };

// ==========================================
// src/data/sequences.ts (View 4: Sequence Diagrams)
// ==========================================

export interface SequenceDiagramData {
  diagrams: SequenceDiagram[];
}

export interface SequenceDiagram {
  id: string;  // prefix: seq-
  title: string;
  description: string;
  mermaid: string; // full Mermaid sequenceDiagram source
  relatedComponents: CrossLink[];
  relatedEntities: CrossLink[];
}

// Export as: export const sequences: SequenceDiagramData = { ... };

// ==========================================
// src/data/erd.ts (View 5: Entity-Relationship Diagram)
// ==========================================

export interface ERDData {
  mermaid: string; // full Mermaid erDiagram source
  entities: EntityDetail[];
}

export interface EntityDetail {
  id: string;  // prefix: entity-
  name: string;
  source: 'prisma' | 'sql' | 'typescript' | 'graphql' | 'protobuf' | 'inferred';
  fields: { name: string; type: string; isPrimary: boolean; isRelation: boolean }[];
  description: string;
  crossLinks: CrossLink[];
}

// Export as: export const erd: ERDData = { ... };

// ==========================================
// src/data/stateMachines.ts (View 6: State Machines)
// ==========================================

export interface StateMachineData {
  machines: StateMachine[];
}

export interface StateMachine {
  id: string;  // prefix: sm-
  title: string;
  entity: string;
  description: string;
  mermaid: string; // full Mermaid stateDiagram-v2 source
  relatedComponents: CrossLink[];
}

// Export as: export const stateMachines: StateMachineData = { ... };

// ==========================================
// src/data/apiContracts.ts (View 7: API Contracts)
// ==========================================

export interface APIContractData {
  groups: APIGroup[];
}

export interface APIGroup {
  id: string;
  name: string; // e.g. "Authentication", "Users", "Content"
  endpoints: APIEndpoint[];
}

export interface APIEndpoint {
  id: string;  // prefix: api-
  method: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  path: string;
  description: string;
  auth: boolean;
  requestShape: Record<string, unknown> | null;
  responseShape: Record<string, unknown> | null;
  errorCodes: { code: number; message: string }[];
  crossLinks: CrossLink[];
}

// Export as: export const apiContracts: APIContractData = { ... };

// ==========================================
// src/data/dependencies.ts (View 8: Dependency Graph)
// ==========================================

export interface DependencyGraphData {
  nodes: DepNode[];
  edges: DepEdge[];
  circularDeps: string[][]; // arrays of node IDs forming cycles
}

export interface DepNode {
  id: string;  // prefix: dep-
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

// Export as: export const dependencyGraph: DependencyGraphData = { ... };

// ==========================================
// src/data/techStack.ts (View 9: Tech Stack)
// ==========================================

export interface TechStackData {
  categories: TechCategory[];
}

export interface TechCategory {
  name: string;
  technologies: TechItem[];
}

export interface TechItem {
  id: string;  // prefix: tech-
  name: string;
  category: 'Frontend' | 'Backend' | 'Database' | 'Auth' | 'Payments' | 'Monitoring' | 'AI' | 'DevOps' | 'Testing' | 'Tooling';
  version: string | null;
  roleInProject: string;
  docsUrl: string;
  usedBy: CrossLink[];
}

// Export as: export const techStack: TechStackData = { ... };

// ==========================================
// src/data/adrs.ts (View 10: Architecture Decision Records)
// ==========================================

export interface ADRData {
  records: ADR[];
}

export interface ADR {
  id: string;  // prefix: adr-
  number: number;
  title: string;
  status: 'Accepted' | 'Proposed' | 'Deprecated';
  date: string; // ISO date or "unknown"
  context: string;      // Markdown
  decision: string;     // Markdown
  consequences: string; // Markdown
  relatedComponents: CrossLink[];
}

// Export as: export const adrs: ADRData = { ... };

// ==========================================
// SEARCH INDEX
// ==========================================

export interface SearchEntry {
  id: string;
  name: string;
  type: 'architecture' | 'component' | 'data-flow' | 'sequence' | 'entity' | 'state-machine' | 'api-endpoint' | 'dependency' | 'technology' | 'adr';
  description: string;
  view: ViewId;
}
```

---

## Data File Export Convention

Every `src/data/*.ts` file must follow this pattern:

```typescript
import type { SomeDataType } from '../types';

const data: SomeDataType = {
  // ... populated with real project data
};

export default data;
```

**Do not use named exports.** Use `export default` so that view components import consistently:

```typescript
import architecture from '../data/architecture';
import componentGraph from '../data/components';
import dataFlow from '../data/dataflow';
import sequences from '../data/sequences';
import erd from '../data/erd';
import stateMachines from '../data/stateMachines';
import apiContracts from '../data/apiContracts';
import dependencyGraph from '../data/dependencies';
import techStack from '../data/techStack';
import adrs from '../data/adrs';
import metadata from '../data/metadata';
```
