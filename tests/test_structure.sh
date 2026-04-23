#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  echo "PASS: $1"
}

# 1. plugin.json exists and is valid JSON
test -f .claude-plugin/plugin.json || fail "plugin.json missing"
python -c "import json; json.load(open('.claude-plugin/plugin.json'))" 2>/dev/null \
  || fail "plugin.json is not valid JSON"
pass "plugin.json is valid JSON"

# 2. plugin.json has required fields
python - <<'PY' || fail "plugin.json missing required fields"
import json, sys
m = json.load(open('.claude-plugin/plugin.json'))
for key in ("name", "version", "description"):
    if key not in m or not m[key]:
        sys.exit(1)
PY
pass "plugin.json has name, version, description"

# 3. command file exists
test -f commands/rubberduck.md || fail "commands/rubberduck.md missing"
pass "command file exists"

# 4. command file has YAML frontmatter
head -n 1 commands/rubberduck.md | grep -q '^---$' \
  || fail "command file missing frontmatter opening ---"
sed -n '2,10p' commands/rubberduck.md | grep -q '^description:' \
  || fail "command file missing 'description:' in frontmatter"
pass "command file has frontmatter with description"

# 5. Phase 1 present
grep -q "PHASE 1 — INTAKE" commands/rubberduck.md \
  || fail "command file missing PHASE 1 — INTAKE marker"
pass "Phase 1 present"

# 6. Phase 2 present
grep -q "PHASE 2 — Q&A" commands/rubberduck.md \
  || fail "command file missing PHASE 2 — Q&A marker"
pass "Phase 2 present"

echo ""
echo "All structural checks passed."
