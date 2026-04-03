# Codebase Analysis Methodology

This document defines exactly how the Explorer subagent must analyze a software project. The output is a `ProjectAnalysis` JSON object whose schema is defined in [TYPES.md](./TYPES.md).

---

## Your Mission

You are a senior engineer reading an unfamiliar codebase for the first time. Your goal is to understand it deeply enough to explain it to someone else — not just what things are, but why they exist, how they connect, and what would break without them.

You will receive **static analysis JSON** (file tree, detected languages, dependencies) as input. Your job is to **read the actual source files** and produce a rich, accurate `ProjectAnalysis`.

---

## What to Read (Priority Order)

Read files in this order. Stop at 200 files total — depth over breadth.

### Tier 1: Orientation (read all of these)
1. **README.md** / README — project purpose, architecture overview, setup instructions
2. **Package manifest** — package.json, pyproject.toml, go.mod, Cargo.toml, Gemfile, pom.xml, build.gradle
3. **Entry points** — main.ts/tsx, index.ts/tsx, app.ts/tsx, server.ts, cmd/main.go, main.py, main.rs
4. **Configuration** — tsconfig.json, vite.config.ts, webpack.config.js, next.config.js, nuxt.config.ts, angular.json, .env.example

### Tier 2: Data Layer (read all found)
5. **Schema files** — *.prisma, schema.sql, migrations/*, drizzle schema, TypeORM entities, Django models.py, SQLAlchemy models
6. **Type definitions** — types.ts, interfaces.ts, *.d.ts, models/, types/, schemas/ directories
7. **API schemas** — openapi.yaml, swagger.json, *.graphql, *.proto

### Tier 3: Core Source (read selectively — focus on the load-bearing code)
8. **Route definitions** — pages/, app/ (Next.js/Nuxt), routes.*, router.*, urls.py
9. **API handlers** — api/, routes/, controllers/, handlers/, endpoints/
10. **Core services** — services/, lib/, core/, domain/
11. **State management** — store/, stores/, state/, reducers/, slices/, context/
12. **Middleware** — middleware/, interceptors/, guards/

### Tier 4: Supporting Code (read if budget remains)
13. **Shared components** — components/shared/, components/common/, ui/
14. **Hooks/composables** — hooks/, composables/, use*.ts
15. **Utilities** — utils/, helpers/, lib/utils

### What NOT to Read
- `node_modules/`, `vendor/`, `.git/`, `dist/`, `build/`, `.next/`, `.nuxt/`, `target/`
- Test files (`*.test.*`, `*.spec.*`, `__tests__/`, `test/`, `tests/`, `spec/`)
- Generated files (`.generated.*`, `*.gen.*`, lock files)
- Build configuration (webpack loaders, babel config, jest config — unless relevant to architecture)
- Static assets (images, fonts, CSS files)
- Documentation files other than README

---

## What to Extract

For each area below, extract real data from the code. If you cannot determine something, leave it as an empty array or null — **never fabricate**.

### 1. Metadata
- Project name (from package manifest or directory name)
- One-paragraph description of what this project does and why
- Total files and lines (from static analysis)
- Language breakdown with percentages
- Detected frameworks
- Entry point files

### 2. Tech Stack
For each technology/library used:
- Name and version (from package manifest)
- Category (Frontend, Backend, Database, Auth, etc.)
- Its specific role in THIS project (not generic docs — what does it DO here?)
- Link to official docs
- Evidence: the import statement or config file that proves it's used

### 3. External Services
Any third-party service the project communicates with:
- Name (Stripe, Supabase, SendGrid, AWS S3, etc.)
- Purpose in this project
- Evidence: environment variable key or import that reveals it

### 4. Modules
For each significant file or directory:
- Name and file path
- Description of what it does
- Type (screen, component, hook, service, store, utility, module, config, middleware, handler)
- Parent module (if nested)
- What it imports and what imports it
- Lines of code

Focus on the load-bearing modules. A 5-line utility helper does not need its own entry unless it's used everywhere.

### 5. Components (for UI projects)
For each significant UI component:
- Name and file path
- Description of what it renders and why
- Props with types
- Where it's used (parent components/screens)
- What hooks and services it uses

### 6. Entities (Data Models)
For each data entity/model:
- Name and source (Prisma, SQL, TypeScript interface, inferred)
- Description
- All fields with types, primary key markers, optional markers
- Relationships to other entities with cardinality

**Sources to check**: Prisma schema, SQL migrations, TypeORM/Drizzle entities, Django models, SQLAlchemy models, GraphQL schema, Protobuf definitions, TypeScript interfaces that represent database records.

If no formal schema exists, infer entities from: API response types, state management types, database query code.

### 7. API Endpoints
For each API endpoint:
- HTTP method and path
- Description of what it does
- Authentication required?
- Request body shape (actual field names and types)
- Response body shape (actual field names and types)
- Error codes and messages
- Source file
- Related entities (which data models does this touch?)
- Related components (which UI components call this?)

**Sources**: Express/Fastify/Hono route files, Next.js API routes, Django views/urls, Flask/FastAPI routes, Go handler functions, Rails controllers, Supabase Edge Functions, tRPC routers, GraphQL resolvers.

If no server-side API exists (e.g., frontend-only app), look for API client files that reveal the expected API shape.

### 8. Key Flows
Identify the 3-6 most important user/data flows:
- Authentication flow
- The core feature action (the main thing the app does)
- Data creation/modification flow
- Error handling flow
- Any other distinctive flow (payment, sync, notification, onboarding)

For each flow:
- Name and description
- Actors (use REAL service/component names, not "Client" or "Server")
- Steps: who does what to whom, what data is passed, is it async, is it an error path
- Related components and entities

### 9. State Models
Identify stateful entities with discrete states:
- Auth state (logged out, logging in, authenticated, expired)
- Subscription/billing state
- Content/resource state (draft, published, archived)
- Upload/processing state (idle, uploading, processing, complete, failed)
- UI-level loading states
- Navigation/routing state

For each:
- Entity name and description
- All states including error and loading states
- All transitions with triggers
- Initial state and terminal states
- Related components that drive these transitions

### 10. Architectural Patterns
Identify non-obvious patterns:
- Event-driven architecture, pub/sub
- Repository pattern, CQRS
- Middleware chains
- Dependency injection
- Factory patterns
- Observer/subscriber patterns
- State machines (formal like XState, or informal)
- Functional pipeline / composition

For each: name, description, and file paths that demonstrate it.

### 11. ADR Suggestions
Generate Architecture Decision Records for:
- **Always**: framework choice, state management approach, database/backend choice
- **If applicable**: auth strategy, API design (REST vs GraphQL vs tRPC), styling approach, testing strategy, deployment target
- **If interesting**: any non-obvious pattern that deserves explanation (why use event sourcing? why a monorepo? why this specific state management library?)

For each: title, context (what problem was being solved), decision (what was chosen), consequences (tradeoffs), evidence (files/config that inform this).

### 12. Dependency Graph
For each source file in the project:
- File path
- List of other project files it imports (not external packages)

This data enhances the Dependency Graph view. If the static analysis includes `madge` output, use that as the primary source and supplement with your own import reading.

---

## Language Adaptation

The extraction methodology above is universal, but different ecosystems have different conventions. Adapt your reading strategy:

### JavaScript / TypeScript
- Look for: package.json, tsconfig.json, next.config.*, vite.config.*, angular.json
- Route conventions: pages/ (Next.js, Nuxt), app/ (Next.js 13+), src/routes/ (SvelteKit)
- State: Redux (store/, slices/), Zustand (stores/), MobX, Jotai, Recoil, Context API
- API: Express routes, Next.js API routes, tRPC routers, Hono handlers

### Python
- Look for: pyproject.toml, setup.py, requirements.txt, Pipfile
- Route conventions: urls.py (Django), app.py/main.py (Flask/FastAPI)
- Models: models.py (Django), SQLAlchemy model classes
- State: typically server-side session, Redis

### Go
- Look for: go.mod, cmd/ directory
- Route conventions: handler functions, chi/gin/echo routers
- Models: struct definitions, often in models/ or types/
- Entry point: cmd/*/main.go or main.go

### Rust
- Look for: Cargo.toml, src/main.rs or src/lib.rs
- Module system: mod.rs files, pub mod declarations
- Web: Actix-web, Axum, Rocket handlers
- Models: struct definitions with serde derives

### Ruby
- Look for: Gemfile, config/routes.rb (Rails)
- Models: app/models/*.rb (ActiveRecord)
- Controllers: app/controllers/*.rb
- Views: app/views/

### Java / Kotlin
- Look for: pom.xml, build.gradle
- Models: entity classes with JPA annotations
- Controllers: @RestController, @Controller classes
- Services: @Service classes

### Mixed-Language / Monorepos
- Read the root README and any workspace configuration (package.json workspaces, nx.json, turbo.json, lerna.json)
- Identify the distinct apps/packages and their roles
- Focus your 200-file budget on the most important packages
- Capture inter-package dependencies in the modules section

---

## Output Format

Write the complete `ProjectAnalysis` JSON object to `<docs-dir>/project-analysis.json`.

The JSON must validate against the `ProjectAnalysis` interface defined in [TYPES.md](./TYPES.md). Every field must be present. Use empty arrays `[]` or `null` for fields with no data — never omit fields.

---

## Quality Checklist

Before finishing, verify:

- [ ] `metadata.description` is a real description of THIS project, not generic
- [ ] Every `techStack` entry has a `roleInProject` specific to this project
- [ ] Every `entity` has real field names and types from the actual schema
- [ ] Every `apiEndpoint` has real request/response shapes (not just `{}`)
- [ ] Every `keyFlow` uses real actor names (component/service names from the project)
- [ ] `stateModels` includes error and loading states, not just happy-path states
- [ ] `adrSuggestions` are grounded in evidence from the codebase
- [ ] `dependencyGraph` entries reference real file paths
- [ ] No fabricated data — everything comes from reading actual source files
- [ ] Cross-references are consistent (entity names in `apiEndpoints.relatedEntities` match names in `entities`)
