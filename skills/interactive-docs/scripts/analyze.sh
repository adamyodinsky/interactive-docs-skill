#!/usr/bin/env bash
# analyze.sh — Static structural analysis of any software project
# Input: $1 = absolute path to project root
# Output: JSON to stdout
# Exit: 0 on success, 1 on failure
set -euo pipefail

PROJECT_ROOT="${1:?Usage: analyze.sh <project-root>}"

if [ ! -d "$PROJECT_ROOT" ]; then
  echo "Error: Directory not found: $PROJECT_ROOT" >&2
  exit 1
fi

cd "$PROJECT_ROOT"

# ============================================================
# Helper: JSON-safe string escaping
# ============================================================
json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# ============================================================
# Project Name
# ============================================================
detect_project_name() {
  if [ -f "package.json" ] && command -v jq &>/dev/null; then
    local name
    name=$(jq -r '.name // empty' package.json 2>/dev/null)
    if [ -n "$name" ]; then printf '%s' "$name"; return; fi
  elif [ -f "package.json" ]; then
    local name
    name=$(grep -m1 '"name"' package.json 2>/dev/null | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    if [ -n "$name" ]; then printf '%s' "$name"; return; fi
  fi
  if [ -f "Cargo.toml" ]; then
    local name
    name=$(grep -m1 '^name' Cargo.toml 2>/dev/null | sed 's/.*=.*"\(.*\)".*/\1/')
    if [ -n "$name" ]; then printf '%s' "$name"; return; fi
  fi
  if [ -f "go.mod" ]; then
    local name
    name=$(head -1 go.mod 2>/dev/null | awk '{print $2}' | awk -F/ '{print $NF}')
    if [ -n "$name" ]; then printf '%s' "$name"; return; fi
  fi
  if [ -f "pyproject.toml" ]; then
    local name
    name=$(grep -m1 '^name' pyproject.toml 2>/dev/null | sed 's/.*=.*"\(.*\)".*/\1/')
    if [ -n "$name" ]; then printf '%s' "$name"; return; fi
  fi
  if [ -f "setup.py" ]; then
    local name
    name=$(grep -m1 'name=' setup.py 2>/dev/null | sed "s/.*name=['\"]\\([^'\"]*\\)['\"].*/\\1/")
    if [ -n "$name" ]; then printf '%s' "$name"; return; fi
  fi
  if [ -f "Gemfile" ] && [ -f "config/application.rb" ]; then
    local name
    name=$(grep -m1 'module ' config/application.rb 2>/dev/null | awk '{print $2}')
    if [ -n "$name" ]; then printf '%s' "$name"; return; fi
  fi
  basename "$PROJECT_ROOT"
}

PROJECT_NAME=$(detect_project_name)

# ============================================================
# Exclusion pattern for find commands
# ============================================================
EXCLUDE_DIRS="-not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/__pycache__/*' -not -path '*/coverage/*' -not -path '*/.next/*' -not -path '*/.nuxt/*' -not -path '*/vendor/*' -not -path '*/target/*' -not -path '*/.venv/*' -not -path '*/venv/*' -not -path '*/.tox/*' -not -path '*/.mypy_cache/*' -not -path '*/.pytest_cache/*' -not -path '*/Pods/*' -not -path '*/.gradle/*' -not -path '*/.idea/*' -not -path '*/.vscode/*' -not -path '*/*.egg-info/*' -not -path '*/.turbo/*' -not -path '*/.cache/*'"

# ============================================================
# Languages (by file extension count)
# ============================================================
detect_languages() {
  local result=""
  eval "find . -type f $EXCLUDE_DIRS" 2>/dev/null | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -20 | while read -r count ext; do
    case "$ext" in
      ts|tsx) lang="TypeScript" ;;
      js|jsx|mjs|cjs) lang="JavaScript" ;;
      py) lang="Python" ;;
      go) lang="Go" ;;
      rs) lang="Rust" ;;
      rb) lang="Ruby" ;;
      java) lang="Java" ;;
      kt|kts) lang="Kotlin" ;;
      swift) lang="Swift" ;;
      cs) lang="C#" ;;
      cpp|cc|cxx|c|h|hpp) lang="C/C++" ;;
      php) lang="PHP" ;;
      dart) lang="Dart" ;;
      ex|exs) lang="Elixir" ;;
      scala) lang="Scala" ;;
      vue) lang="Vue" ;;
      svelte) lang="Svelte" ;;
      sql) lang="SQL" ;;
      graphql|gql) lang="GraphQL" ;;
      proto) lang="Protobuf" ;;
      prisma) lang="Prisma" ;;
      *) continue ;;
    esac
    printf '{"name":"%s","ext":"%s","count":%d},' "$lang" "$ext" "$count"
  done
}

LANGUAGES_RAW=$(detect_languages)
LANGUAGES_JSON="[${LANGUAGES_RAW%,}]"

# ============================================================
# Frameworks (detected from config files and manifests)
# ============================================================
detect_frameworks() {
  local frameworks=""
  [ -f "next.config.js" ] || [ -f "next.config.ts" ] || [ -f "next.config.mjs" ] && frameworks="${frameworks}\"Next.js\","
  [ -f "nuxt.config.ts" ] || [ -f "nuxt.config.js" ] && frameworks="${frameworks}\"Nuxt\","
  [ -f "angular.json" ] && frameworks="${frameworks}\"Angular\","
  [ -f "svelte.config.js" ] || [ -f "svelte.config.ts" ] && frameworks="${frameworks}\"SvelteKit\","
  [ -f "remix.config.js" ] || [ -f "remix.config.ts" ] && frameworks="${frameworks}\"Remix\","
  [ -f "astro.config.mjs" ] || [ -f "astro.config.ts" ] && frameworks="${frameworks}\"Astro\","
  [ -f "vite.config.ts" ] || [ -f "vite.config.js" ] && frameworks="${frameworks}\"Vite\","
  [ -f "gatsby-config.js" ] || [ -f "gatsby-config.ts" ] && frameworks="${frameworks}\"Gatsby\","
  [ -f "vue.config.js" ] && frameworks="${frameworks}\"Vue CLI\","
  [ -f "manage.py" ] && frameworks="${frameworks}\"Django\","
  [ -f "app.py" ] && grep -q "Flask\|flask" app.py 2>/dev/null && frameworks="${frameworks}\"Flask\","
  [ -f "main.py" ] && grep -q "FastAPI\|fastapi" main.py 2>/dev/null && frameworks="${frameworks}\"FastAPI\","
  [ -f "Gemfile" ] && grep -q "rails" Gemfile 2>/dev/null && frameworks="${frameworks}\"Rails\","
  [ -f "Gemfile" ] && grep -q "sinatra" Gemfile 2>/dev/null && frameworks="${frameworks}\"Sinatra\","
  [ -f "go.mod" ] && grep -q "gin-gonic" go.mod 2>/dev/null && frameworks="${frameworks}\"Gin\","
  [ -f "go.mod" ] && grep -q "labstack/echo" go.mod 2>/dev/null && frameworks="${frameworks}\"Echo\","
  [ -f "go.mod" ] && grep -q "go-chi" go.mod 2>/dev/null && frameworks="${frameworks}\"Chi\","
  [ -f "Cargo.toml" ] && grep -q "actix" Cargo.toml 2>/dev/null && frameworks="${frameworks}\"Actix\","
  [ -f "Cargo.toml" ] && grep -q "axum" Cargo.toml 2>/dev/null && frameworks="${frameworks}\"Axum\","
  [ -f "Cargo.toml" ] && grep -q "rocket" Cargo.toml 2>/dev/null && frameworks="${frameworks}\"Rocket\","
  [ -f "pom.xml" ] && grep -q "spring" pom.xml 2>/dev/null && frameworks="${frameworks}\"Spring\","
  [ -f "build.gradle" ] && grep -q "spring" build.gradle 2>/dev/null && frameworks="${frameworks}\"Spring\","
  [ -f "Package.swift" ] && frameworks="${frameworks}\"Swift Package\","
  [ -d "ios" ] || [ -d "android" ] && [ -f "pubspec.yaml" ] && frameworks="${frameworks}\"Flutter\","
  [ -d "ios" ] || [ -d "android" ] && [ -f "package.json" ] && grep -q "react-native" package.json 2>/dev/null && frameworks="${frameworks}\"React Native\","
  [ -f "electron-builder.json" ] || [ -f "electron-builder.yml" ] && frameworks="${frameworks}\"Electron\","
  [ -f "tauri.conf.json" ] && frameworks="${frameworks}\"Tauri\","
  # Additional tech detection from package.json
  if [ -f "package.json" ]; then
    grep -q '"express"' package.json 2>/dev/null && frameworks="${frameworks}\"Express\","
    grep -q '"fastify"' package.json 2>/dev/null && frameworks="${frameworks}\"Fastify\","
    grep -q '"hono"' package.json 2>/dev/null && frameworks="${frameworks}\"Hono\","
    grep -q '"prisma"' package.json 2>/dev/null && frameworks="${frameworks}\"Prisma\","
    grep -q '"drizzle-orm"' package.json 2>/dev/null && frameworks="${frameworks}\"Drizzle\","
    grep -q '"@supabase/supabase-js"' package.json 2>/dev/null && frameworks="${frameworks}\"Supabase\","
    grep -q '"firebase"' package.json 2>/dev/null && frameworks="${frameworks}\"Firebase\","
    grep -q '"tailwindcss"' package.json 2>/dev/null && frameworks="${frameworks}\"Tailwind CSS\","
    grep -q '"react"' package.json 2>/dev/null && frameworks="${frameworks}\"React\","
    grep -q '"vue"' package.json 2>/dev/null && frameworks="${frameworks}\"Vue\","
    grep -q '"svelte"' package.json 2>/dev/null && frameworks="${frameworks}\"Svelte\","
  fi
  printf '[%s]' "${frameworks%,}"
}

FRAMEWORKS_JSON=$(detect_frameworks)

# ============================================================
# File Tree (max depth 4, JSON array of paths)
# ============================================================
generate_file_tree() {
  eval "find . -maxdepth 4 $EXCLUDE_DIRS -type f -o -type d" 2>/dev/null | sort | head -2000 | while IFS= read -r path; do
    local relpath="${path#./}"
    [ -z "$relpath" ] && continue
    local ftype="file"
    [ -d "$path" ] && ftype="directory"
    printf '{"path":"%s","type":"%s"},' "$(json_escape "$relpath")" "$ftype"
  done
}

FILE_TREE_RAW=$(generate_file_tree)
FILE_TREE_JSON="[${FILE_TREE_RAW%,}]"

# ============================================================
# Entry Points
# ============================================================
detect_entry_points() {
  local entries=""
  for pattern in "index.ts" "index.tsx" "index.js" "index.jsx" "main.ts" "main.tsx" "main.js" "main.py" "main.go" "main.rs" "app.ts" "app.tsx" "app.js" "app.py" "server.ts" "server.js" "server.py" "lib.rs" "mod.rs"; do
    eval "find . -maxdepth 3 $EXCLUDE_DIRS -name '$pattern' -type f" 2>/dev/null | head -5 | while IFS= read -r f; do
      printf '"%s",' "$(json_escape "${f#./}")"
    done
  done
  # Also check cmd/ for Go projects
  if [ -d "cmd" ]; then
    find cmd -name "main.go" -type f 2>/dev/null | head -5 | while IFS= read -r f; do
      printf '"%s",' "$(json_escape "$f")"
    done
  fi
}

ENTRY_POINTS_RAW=$(detect_entry_points)
ENTRY_POINTS_JSON="[${ENTRY_POINTS_RAW%,}]"

# ============================================================
# Lines of Code by Directory
# ============================================================
loc_by_directory() {
  for dir in */; do
    [ -d "$dir" ] || continue
    local dirname="${dir%/}"
    case "$dirname" in
      node_modules|.git|dist|build|coverage|.next|.nuxt|vendor|target|.venv|venv|Pods|.gradle) continue ;;
    esac
    local count
    count=$(eval "find '$dir' -type f $EXCLUDE_DIRS -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' -o -name '*.go' -o -name '*.rs' -o -name '*.rb' -o -name '*.java' -o -name '*.kt' -o -name '*.swift' -o -name '*.cs' -o -name '*.cpp' -o -name '*.c' -o -name '*.h' -o -name '*.php' -o -name '*.vue' -o -name '*.svelte' -o -name '*.dart' -o -name '*.ex' -o -name '*.exs' -o -name '*.scala'" 2>/dev/null | head -5000 | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')
    [ -z "$count" ] && count=0
    printf '{"directory":"%s","lines":%d},' "$(json_escape "$dirname")" "$count"
  done
}

LOC_RAW=$(loc_by_directory)
LOC_JSON="[${LOC_RAW%,}]"

# ============================================================
# Dependencies (from package manifests)
# ============================================================
parse_dependencies() {
  if [ -f "package.json" ] && command -v jq &>/dev/null; then
    jq -r '(.dependencies // {}) + (.devDependencies // {}) | to_entries[] | "{\"name\":\"\(.key)\",\"version\":\"\(.value)\"},"' package.json 2>/dev/null
  elif [ -f "package.json" ]; then
    grep -E '^\s+"[^"]+"\s*:\s*"[^"]+"' package.json 2>/dev/null | sed 's/.*"\([^"]*\)".*:.*"\([^"]*\)".*/{"name":"\1","version":"\2"},/' | head -100
  fi
  if [ -f "go.mod" ]; then
    grep -E '^\t' go.mod 2>/dev/null | awk '{print "{\"name\":\""$1"\",\"version\":\""$2"\"},"}' | head -50
  fi
  if [ -f "Cargo.toml" ]; then
    grep -E '^[a-zA-Z].*=' Cargo.toml 2>/dev/null | grep -v '^\[' | sed 's/\([^=]*\)=.*/{"name":"\1","version":""},/' | head -50
  fi
  if [ -f "requirements.txt" ]; then
    grep -vE '^\s*#|^\s*$' requirements.txt 2>/dev/null | sed 's/\([^=<>!]*\).*/{"name":"\1","version":""},/' | head -50
  fi
  if [ -f "pyproject.toml" ]; then
    grep -A100 '\[project\]' pyproject.toml 2>/dev/null | grep -E '^\s+"' | sed 's/.*"\([^"]*\)".*/{"name":"\1","version":""},/' | head -50
  fi
  if [ -f "Gemfile" ]; then
    grep -E "^gem " Gemfile 2>/dev/null | sed "s/gem ['\"]\\([^'\"]*\\)['\"].*/{\\"name\\":\\"\\1\\",\\"version\\":\\"\\"},/" | head -50
  fi
}

DEPS_RAW=$(parse_dependencies)
DEPS_JSON="[${DEPS_RAW%,}]"

# ============================================================
# Environment Variable Keys
# ============================================================
detect_env_keys() {
  local env_file=""
  [ -f ".env.example" ] && env_file=".env.example"
  [ -f ".env.local.example" ] && env_file=".env.local.example"
  [ -f ".env.sample" ] && env_file=".env.sample"
  [ -f ".env.template" ] && env_file=".env.template"
  if [ -n "$env_file" ]; then
    grep -E '^[A-Z_]+=' "$env_file" 2>/dev/null | sed 's/=.*//' | while IFS= read -r key; do
      printf '"%s",' "$(json_escape "$key")"
    done
  fi
}

ENV_KEYS_RAW=$(detect_env_keys)
ENV_KEYS_JSON="[${ENV_KEYS_RAW%,}]"

# ============================================================
# Config Files
# ============================================================
detect_config_files() {
  for f in tsconfig.json tsconfig.*.json webpack.config.* vite.config.* next.config.* nuxt.config.* angular.json svelte.config.* remix.config.* astro.config.* gatsby-config.* babel.config.* .babelrc jest.config.* vitest.config.* .eslintrc* eslint.config.* .prettierrc* prettier.config.* postcss.config.* tailwind.config.* docker-compose.yml docker-compose.yaml Dockerfile Makefile turbo.json nx.json lerna.json pnpm-workspace.yaml; do
    eval "find . -maxdepth 2 $EXCLUDE_DIRS -name '$f' -type f" 2>/dev/null | head -3 | while IFS= read -r path; do
      printf '"%s",' "$(json_escape "${path#./}")"
    done
  done
}

CONFIG_FILES_RAW=$(detect_config_files)
CONFIG_FILES_JSON="[${CONFIG_FILES_RAW%,}]"

# ============================================================
# Schema Files
# ============================================================
detect_schema_files() {
  # Prisma
  eval "find . -maxdepth 4 $EXCLUDE_DIRS -name '*.prisma' -type f" 2>/dev/null | head -5 | while IFS= read -r f; do
    printf '"%s",' "$(json_escape "${f#./}")"
  done
  # SQL migrations
  eval "find . -maxdepth 4 $EXCLUDE_DIRS -path '*/migrations/*' -name '*.sql' -type f" 2>/dev/null | head -10 | while IFS= read -r f; do
    printf '"%s",' "$(json_escape "${f#./}")"
  done
  # Drizzle
  eval "find . -maxdepth 3 $EXCLUDE_DIRS -name 'drizzle.config.*' -type f" 2>/dev/null | head -3 | while IFS= read -r f; do
    printf '"%s",' "$(json_escape "${f#./}")"
  done
  # GraphQL schemas
  eval "find . -maxdepth 4 $EXCLUDE_DIRS \\( -name '*.graphql' -o -name '*.gql' \\) -type f" 2>/dev/null | head -10 | while IFS= read -r f; do
    printf '"%s",' "$(json_escape "${f#./}")"
  done
  # Protobuf
  eval "find . -maxdepth 4 $EXCLUDE_DIRS -name '*.proto' -type f" 2>/dev/null | head -10 | while IFS= read -r f; do
    printf '"%s",' "$(json_escape "${f#./}")"
  done
  # Django models
  eval "find . -maxdepth 4 $EXCLUDE_DIRS -name 'models.py' -type f" 2>/dev/null | head -5 | while IFS= read -r f; do
    printf '"%s",' "$(json_escape "${f#./}")"
  done
  # SQL schema files
  eval "find . -maxdepth 3 $EXCLUDE_DIRS -name 'schema.sql' -type f" 2>/dev/null | head -3 | while IFS= read -r f; do
    printf '"%s",' "$(json_escape "${f#./}")"
  done
}

SCHEMA_FILES_RAW=$(detect_schema_files)
SCHEMA_FILES_JSON="[${SCHEMA_FILES_RAW%,}]"

# ============================================================
# Madge dependency graph (optional)
# ============================================================
MADGE_JSON="null"
if command -v npx &>/dev/null && [ -f "package.json" ]; then
  MADGE_OUTPUT=$(npx --yes madge --json . 2>/dev/null || true)
  if [ -n "$MADGE_OUTPUT" ] && echo "$MADGE_OUTPUT" | head -1 | grep -q '{'; then
    MADGE_JSON="$MADGE_OUTPUT"
  fi
fi

# ============================================================
# Output JSON
# ============================================================
cat <<ENDJSON
{
  "projectName": "$(json_escape "$PROJECT_NAME")",
  "languages": $LANGUAGES_JSON,
  "frameworks": $FRAMEWORKS_JSON,
  "fileTree": $FILE_TREE_JSON,
  "entryPoints": $ENTRY_POINTS_JSON,
  "locByDirectory": $LOC_JSON,
  "dependencies": $DEPS_JSON,
  "envKeys": $ENV_KEYS_JSON,
  "configFiles": $CONFIG_FILES_JSON,
  "schemaFiles": $SCHEMA_FILES_JSON,
  "madgeOutput": $MADGE_JSON
}
ENDJSON
