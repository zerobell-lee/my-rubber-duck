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

echo ""
echo "All structural checks passed."
