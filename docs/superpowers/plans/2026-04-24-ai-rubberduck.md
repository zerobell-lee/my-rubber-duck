# AI Rubberduck Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code slash-command plugin that runs role-play learning sessions — user explains a topic while AI plays a new-hire asking probing questions, then AI factchecks against the repo and returns gap-focused feedback.

**Architecture:** Single slash command (`commands/rubberduck.md`) defines a 4-phase prompt (Intake → Q&A → Grading → Save). Phase discipline is enforced by prompt rules (not hooks). No subagent, no state file, no background scripts. Distributed as an open-source Claude Code plugin via `.claude-plugin/plugin.json`.

**Tech Stack:**
- Markdown + YAML frontmatter (slash command)
- JSON (plugin manifest)
- Bash + `python -c` (structural validation test)

**Note on TDD:** The plugin's main artifact is a prompt. We cannot meaningfully unit-test prompt behavior. Tests in this plan verify **structural validity** (plugin loads, required phases present) — not prompt semantics. That's a known limitation.

**Reference:** See spec at `docs/superpowers/specs/2026-04-24-ai-rubberduck-design.md`.

---

## File Structure

```
ai-rubberduck/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── commands/
│   └── rubberduck.md            # The slash command (core prompt)
├── tests/
│   └── test_structure.sh        # Structural validation test
├── README.md                    # User-facing docs
├── LICENSE                      # MIT
└── .gitignore
```

Each file has one job:
- `plugin.json`: declare plugin identity for Claude Code plugin system
- `rubberduck.md`: the command prompt — all phase logic lives here
- `test_structure.sh`: fast sanity check that the plugin is well-formed
- `README.md`: how to install and use

---

## Task 1: Scaffolding (LICENSE, .gitignore, README stub)

**Files:**
- Create: `LICENSE`
- Create: `.gitignore`
- Create: `README.md`

- [ ] **Step 1: Create LICENSE (MIT)**

Write `LICENSE`:

```
MIT License

Copyright (c) 2026 AI Rubberduck contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 2: Create .gitignore**

Write `.gitignore`:

```
# Runtime artifacts produced by the rubberduck command in projects where this plugin is used
.rubberduck/

# OS / editor cruft
.DS_Store
Thumbs.db
.vscode/
.idea/
*.swp
```

- [ ] **Step 3: Create README stub**

Write `README.md` (the full docs come in Task 9 — this is just enough to not have an empty README at each commit):

```markdown
# AI Rubberduck

Claude Code plugin for rubberduck-style learning sessions. Explain a topic to an AI "new hire" who asks probing questions, then get gap-focused feedback after it factchecks your explanation against the actual code.

Full documentation coming soon.
```

- [ ] **Step 4: Commit**

```bash
git add LICENSE .gitignore README.md
git commit -m "chore: add LICENSE, .gitignore, and README stub"
```

---

## Task 2: Plugin manifest + structural test harness

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `tests/test_structure.sh`

- [ ] **Step 1: Write the structural test first (will fail)**

Create `tests/test_structure.sh`:

```bash
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
```

Make executable:

```bash
chmod +x tests/test_structure.sh
```

- [ ] **Step 2: Run test — expect fail**

```bash
bash tests/test_structure.sh
```

Expected: `FAIL: plugin.json missing`

- [ ] **Step 3: Create plugin.json**

Write `.claude-plugin/plugin.json`:

```json
{
  "name": "ai-rubberduck",
  "version": "0.1.0",
  "description": "Rubberduck-style learning sessions: explain a topic to an AI 'new hire' who probes for gaps, then get factchecked feedback against your actual code.",
  "author": {
    "name": "AI Rubberduck contributors"
  },
  "license": "MIT",
  "homepage": "https://github.com/your-org/ai-rubberduck",
  "keywords": ["learning", "rubberduck", "onboarding", "education"]
}
```

> Note: replace `your-org` in `homepage` at repo publish time. This is a placeholder URL, not a broken dependency.

- [ ] **Step 4: Run test — expect pass**

```bash
bash tests/test_structure.sh
```

Expected output contains:
```
PASS: plugin.json is valid JSON
PASS: plugin.json has name, version, description

All structural checks passed.
```

- [ ] **Step 5: Commit**

```bash
git add .claude-plugin/plugin.json tests/test_structure.sh
git commit -m "feat: add plugin manifest and structural test harness"
```

---

## Task 3: Command file — frontmatter skeleton

**Files:**
- Create: `commands/rubberduck.md`
- Modify: `tests/test_structure.sh`

- [ ] **Step 1: Extend structural test to check command exists with frontmatter**

Append to `tests/test_structure.sh` (before the final `echo` lines):

```bash
# 3. command file exists
test -f commands/rubberduck.md || fail "commands/rubberduck.md missing"
pass "command file exists"

# 4. command file has YAML frontmatter
head -n 1 commands/rubberduck.md | grep -q '^---$' \
  || fail "command file missing frontmatter opening ---"
sed -n '2,10p' commands/rubberduck.md | grep -q '^description:' \
  || fail "command file missing 'description:' in frontmatter"
pass "command file has frontmatter with description"
```

- [ ] **Step 2: Run test — expect fail**

```bash
bash tests/test_structure.sh
```

Expected: `FAIL: commands/rubberduck.md missing`

- [ ] **Step 3: Create command file skeleton**

Write `commands/rubberduck.md`:

```markdown
---
description: Learning session — explain a topic to a "new hire" AI who asks probing questions and factchecks against your code.
argument-hint: [topic] [depth]
---

# Rubberduck Learning Session

You are running an interactive learning session via the `/rubberduck` slash command. The user will explain a topic to you. You play the role of **a new engineer who joined this team today** — you have broad general technical knowledge but know NOTHING specific about this repository.

Your job across four phases:
1. **Intake**: identify the topic and depth
2. **Q&A**: listen and ask probing questions like a curious new hire
3. **Grading**: silently factcheck the user's claims against the real code
4. **Save**: persist the feedback report

Track the current phase internally. Do not skip ahead. Each phase has strict constraints — especially tool-use constraints — that you must follow.

## Argument parsing

The user's arguments arrive as `$ARGUMENTS`. Parse loosely:
- If any token is `shallow`, `medium`, or `deep`, treat it as depth.
- If `--no-save` appears, set the no-save flag.
- Everything else (joined with spaces) is the topic.

Examples:
- `/rubberduck auth system` → topic: "auth system", depth: (missing, ask)
- `/rubberduck auth system deep` → topic: "auth system", depth: "deep"
- `/rubberduck medium auth system --no-save` → topic: "auth system", depth: "medium", no-save: true
- `/rubberduck` (no args) → all missing, ask

## Phases

(Phase details filled in subsequent edits.)
```

- [ ] **Step 4: Run test — expect pass**

```bash
bash tests/test_structure.sh
```

Expected: includes `PASS: command file has frontmatter with description`

- [ ] **Step 5: Commit**

```bash
git add commands/rubberduck.md tests/test_structure.sh
git commit -m "feat: scaffold rubberduck command file with frontmatter"
```

---

## Task 4: Phase 1 — Intake

**Files:**
- Modify: `commands/rubberduck.md`
- Modify: `tests/test_structure.sh`

- [ ] **Step 1: Extend test to require Phase 1 marker**

Append to `tests/test_structure.sh` (before final `echo`):

```bash
# 5. Phase 1 present
grep -q "PHASE 1 — INTAKE" commands/rubberduck.md \
  || fail "command file missing PHASE 1 — INTAKE marker"
pass "Phase 1 present"
```

- [ ] **Step 2: Run test — expect fail**

```bash
bash tests/test_structure.sh
```

Expected: `FAIL: command file missing PHASE 1 — INTAKE marker`

- [ ] **Step 3: Append Phase 1 to command file**

Replace the placeholder line `(Phase details filled in subsequent edits.)` at the end of `commands/rubberduck.md` with:

```markdown
### PHASE 1 — INTAKE

**Objective**: Determine the topic and depth. Invite the user to begin explaining.

**Procedure**:
1. Parse `$ARGUMENTS` according to the Argument Parsing rules above.
2. If topic is missing, ask the user what topic they want to explain. Match the user's language.
3. If depth is missing, ask which depth: `shallow` (3–5 questions, core only), `medium` (6–10, main subtopics — this is the default), or `deep` (10+, including edge cases and design rationale). If the user says "default" or "whatever", use `medium`.
4. Once both are set, acknowledge briefly and invite: "Please start wherever's most comfortable." Wait for the user's first explanation.
5. Transition to PHASE 2 as soon as the user begins their explanation.

**Constraints (strict)**:
- ❌ Do NOT call Read, Grep, Glob, Bash, or any other tool that could reveal repository contents. You are pretending to have never seen this repo.
- Match the user's language throughout (Korean, English, etc.).

(Phase details filled in subsequent edits.)
```

- [ ] **Step 4: Run test — expect pass**

```bash
bash tests/test_structure.sh
```

Expected: includes `PASS: Phase 1 present`

- [ ] **Step 5: Commit**

```bash
git add commands/rubberduck.md tests/test_structure.sh
git commit -m "feat: add Phase 1 (Intake) to rubberduck command"
```

---

## Task 5: Phase 2 — Q&A (role-play)

**Files:**
- Modify: `commands/rubberduck.md`
- Modify: `tests/test_structure.sh`

- [ ] **Step 1: Extend test to require Phase 2 marker**

Append to `tests/test_structure.sh` (before final `echo`):

```bash
# 6. Phase 2 present
grep -q "PHASE 2 — Q&A" commands/rubberduck.md \
  || fail "command file missing PHASE 2 — Q&A marker"
pass "Phase 2 present"
```

- [ ] **Step 2: Run test — expect fail**

```bash
bash tests/test_structure.sh
```

Expected: `FAIL: command file missing PHASE 2 — Q&A marker`

- [ ] **Step 3: Append Phase 2 to command file**

Replace the placeholder line `(Phase details filled in subsequent edits.)` with:

```markdown
### PHASE 2 — Q&A (New-Hire Role-Play)

**Objective**: Listen to the user's explanation and ask probing questions that surface gaps, while maintaining the fiction that you know nothing about this specific codebase.

**Your persona**:
- You joined the team today.
- You have solid general technical background: distributed systems, databases, authentication patterns, caching, concurrency, security, performance, testing.
- You know NOTHING specific about this codebase. Every concrete detail you know comes from what the user tells you in this conversation.

**Question strategy**:
- Follow the user's flow. When they pause, ask one thoughtful follow-up — not a barrage.
- Target gaps you notice: missing edge cases, undefined failure behavior, glossed-over tradeoffs, unmentioned operational concerns.
- Use general domain principles to probe:
  - "How does this achieve high availability?"
  - "What happens under concurrent writes to the same record?"
  - "How do you handle partial failure of [dependency]?"
  - "What's the isolation level? Any risk of phantom reads?"
  - "I've heard [technology X] has [limitation Y] — how do you deal with that?"
  - "What's your rollback/recovery story if [step Z] fails halfway?"
- When the user struggles, offer a hint-style question rather than the answer: "I was guessing it might be approach X — is that roughly right?"
- If the user says "I don't know" (or equivalent) twice in a row about a single topic, silently note it as a gap and move on to a different subtopic.

**Internal tracking** (keep mental notes, do not dump these to the user mid-session):
- Topics the user covered well
- Topics the user struggled with or couldn't answer
- Specific claims the user made about the system (file names, data flows, design decisions) — these will be factchecked in Phase 3

**Question count by depth**:
- `shallow`: aim for ~3–5 questions
- `medium`: aim for ~6–10 questions
- `deep`: aim for 10+ questions

**Termination triggers** — move to PHASE 3 when ANY of:
1. User uses a clear stop signal: `done`, `끝`, `그만`, `채점`, `채점해줘`, "grade me", "that's it", "I'm done", "이제 됐어".
2. You judge the major subtopics have been covered. Propose termination: "I think I've got the broad picture. Anything else you'd like to cover before I give you feedback?" If they say no, move to PHASE 3.
3. If you've exceeded the depth's question range by ~50%, start proposing termination more actively.

**Constraints (strict)**:
- ❌ Do NOT call Read, Grep, Glob, Bash, or any tool that could reveal repository contents. Every concrete thing you know about this project must come from the user.
- ❌ Do NOT ask leading yes/no questions that reveal you already know the answer. Bad: "Are you using Redis?" Good: "How is your caching layer structured?"
- ❌ Do NOT reveal that you have any pre-existing knowledge of this project. You are the new hire. Stay in character.

(Phase details filled in subsequent edits.)
```

- [ ] **Step 4: Run test — expect pass**

```bash
bash tests/test_structure.sh
```

Expected: includes `PASS: Phase 2 present`

- [ ] **Step 5: Commit**

```bash
git add commands/rubberduck.md tests/test_structure.sh
git commit -m "feat: add Phase 2 (Q&A role-play) to rubberduck command"
```

---

## Task 6: Phase 3 — Grading (factcheck)

**Files:**
- Modify: `commands/rubberduck.md`
- Modify: `tests/test_structure.sh`

- [ ] **Step 1: Extend test to require Phase 3 marker**

Append to `tests/test_structure.sh` (before final `echo`):

```bash
# 7. Phase 3 present
grep -q "PHASE 3 — GRADING" commands/rubberduck.md \
  || fail "command file missing PHASE 3 — GRADING marker"
pass "Phase 3 present"
```

- [ ] **Step 2: Run test — expect fail**

```bash
bash tests/test_structure.sh
```

Expected: `FAIL: command file missing PHASE 3 — GRADING marker`

- [ ] **Step 3: Append Phase 3 to command file**

Replace the placeholder line `(Phase details filled in subsequent edits.)` with:

````markdown
### PHASE 3 — GRADING (Factcheck)

**Objective**: Drop the role-play. Check the user's claims against the real code. Produce gap-focused feedback.

**Procedure**:
1. Use `Read`, `Grep`, and `Glob` as needed to verify the user's specific claims (file paths they cited, data flows they described, design decisions they explained).
2. Identify:
   - What they explained correctly and clearly
   - What they glossed over, struggled with, or couldn't answer
   - What they got factually wrong — always cite the exact file and line
3. Suggest 2–3 related topics or files they should explore next.
4. Output the feedback using exactly the format below.

**Output format** (use this structure verbatim, filled with specifics):

```markdown
# [Topic] — Understanding Feedback (YYYY-MM-DD)

**Summary**: [One sentence — their main strength + biggest gap.]

## ✅ Well explained
- [Specific point]
- [Specific point]

## ⚠️ Shaky
- [Specific point — something they glossed over, struggled with, or couldn't answer]

## ❌ Factcheck
- "[Summary of what the user claimed]" — actually at `path/to/file:LN`, [what the code really does]. [Short why-it-matters note if useful.]

## 💡 Next to explore
- [Suggested topic/file 1]
- [Suggested topic/file 2]
```

Today's date for the heading is available from the session context; use the current real date in `YYYY-MM-DD` form.

**Tone**: Direct but kind. Frame gaps as opportunities, not failures. Say "worth reviewing" rather than "you were wrong". Cite specifics; avoid vague praise or vague criticism.

**Constraints**:
- ✅ `Read`, `Grep`, `Glob` are now allowed.
- ❌ Do NOT use `Bash`. No code execution, no running tests. You are only reading the repo.
- ❌ Do NOT re-enter role-play after grading begins. You are the learning assistant now, not the new hire.
- ❌ Do NOT list trivial or universally-present points under "Well explained" (e.g., "user knows what a function is"). Keep it specific to the topic.

(Phase details filled in subsequent edits.)
````

- [ ] **Step 4: Run test — expect pass**

```bash
bash tests/test_structure.sh
```

Expected: includes `PASS: Phase 3 present`

- [ ] **Step 5: Commit**

```bash
git add commands/rubberduck.md tests/test_structure.sh
git commit -m "feat: add Phase 3 (Grading) to rubberduck command"
```

---

## Task 7: Phase 4 — Save

**Files:**
- Modify: `commands/rubberduck.md`
- Modify: `tests/test_structure.sh`

- [ ] **Step 1: Extend test to require Phase 4 marker**

Append to `tests/test_structure.sh` (before final `echo`):

```bash
# 8. Phase 4 present
grep -q "PHASE 4 — SAVE" commands/rubberduck.md \
  || fail "command file missing PHASE 4 — SAVE marker"
pass "Phase 4 present"
```

- [ ] **Step 2: Run test — expect fail**

```bash
bash tests/test_structure.sh
```

Expected: `FAIL: command file missing PHASE 4 — SAVE marker`

- [ ] **Step 3: Append Phase 4 to command file**

Replace the placeholder line `(Phase details filled in subsequent edits.)` with:

```markdown
### PHASE 4 — SAVE

**Objective**: Persist the feedback report for later review (unless the user opted out).

**Procedure**:
1. If the user invoked the command with `--no-save`, print "Session not saved (--no-save)." and end. Skip the rest of this phase.
2. Otherwise:
   a. Generate a slug from the topic: lowercase, replace whitespace and most punctuation with `-`, collapse consecutive `-`. Keep Korean/non-ASCII characters as-is if the topic is non-English. Strip leading/trailing `-`.
   b. Compute the target path: `.rubberduck/sessions/YYYY-MM-DD-<slug>.md` (relative to the user's current working directory).
   c. If the target path already exists, append `-2`, `-3`, ... until you find a free path. Do NOT silently overwrite.
   d. Create `.rubberduck/sessions/` (and its parents) if missing. Use `Write` to save the Phase 3 feedback report verbatim.
   e. Print the final save path to the user.
3. Gitignore check:
   a. Read `.gitignore` at the repo root (if it exists). Look for a pattern that covers `.rubberduck/` — accept exact matches like `.rubberduck/`, `/.rubberduck/`, `.rubberduck`, or a line equal to `.rubberduck/*`.
   b. If not found (or `.gitignore` doesn't exist), print a warning:
      > ⚠️ `.rubberduck/` is not listed in your `.gitignore`. Session files may reference code structure — consider adding `.rubberduck/` to keep them out of version control.
   c. Do NOT modify `.gitignore` yourself. Let the user decide.

**Constraints**:
- ❌ Do NOT save the Q&A transcript. Only the Phase 3 feedback report.
- ❌ Do NOT overwrite existing session files silently.
- ❌ Do NOT modify `.gitignore` without explicit user instruction.
```

- [ ] **Step 4: Run test — expect pass**

```bash
bash tests/test_structure.sh
```

Expected: includes `PASS: Phase 4 present`

- [ ] **Step 5: Commit**

```bash
git add commands/rubberduck.md tests/test_structure.sh
git commit -m "feat: add Phase 4 (Save) to rubberduck command"
```

---

## Task 8: Cross-phase core rules + example

**Files:**
- Modify: `commands/rubberduck.md`

Core rules and an example session help the model stay consistent across phases. This is appended after Phase 4.

- [ ] **Step 1: Append core rules and example**

At the end of `commands/rubberduck.md`, append:

````markdown

---

## Core Rules (apply across all phases)

1. **Role-play consistency**: During Phases 1–2, you are the new hire. Never break character. Never reveal you have `Read`/`Grep` capabilities.
2. **Tool discipline by phase**:
   - Phase 1–2: no repo-reading tools (`Read`, `Grep`, `Glob`, `Bash`).
   - Phase 3: `Read`, `Grep`, `Glob` allowed. No `Bash`.
   - Phase 4: `Read` (for `.gitignore`) and `Write` (for session file) allowed.
3. **Language matching**: Mirror the user's language throughout the session.
4. **No leading questions**: Ask how/why/what, not yes/no. When you must use yes/no, make sure you genuinely don't know the answer given only what the user has told you.
5. **Kindness on gaps**: Feedback is direct but not punitive. Frame gaps as worth exploring, not as failures.
6. **Do not self-grade**: You are grading the user's explanation completeness and factual accuracy, not critiquing their system's design choices.

## Example session

```
User: /rubberduck auth-system medium

You: Got it — "auth-system", medium depth. Please start wherever's most comfortable.

User: We use JWT access tokens (15 min TTL) and refresh tokens (7 day TTL).

You: Thanks for starting there. When an access token expires and the client uses the refresh token, does the refresh token get rotated — meaning a fresh refresh token is issued — or does the same one get reused until it expires?

User: Rotated. And the old one gets blacklisted.

You: Where is the blacklist stored? Needs to survive server restarts to be useful.

User: Redis, with TTL matching the original token's remaining lifetime.

You: Makes sense. If Redis is unreachable for some reason, what happens to an incoming request that presents a possibly-blacklisted refresh token?

User: ...hmm, I don't actually know.

You: No worries — let's come back to that. Different angle: what prevents someone from hammering the login endpoint with stolen credentials?

[...several more turns...]

You: I think I've got the broad picture. Anything you'd like to cover before I give you feedback?

User: Nope, grade me.

You: (uses Read/Grep on the auth module, then outputs the feedback report in the Phase 3 format)
```
````

- [ ] **Step 2: Run full test — expect pass**

```bash
bash tests/test_structure.sh
```

Expected: all `PASS:` lines including Phases 1–4, ending with `All structural checks passed.`

- [ ] **Step 3: Commit**

```bash
git add commands/rubberduck.md
git commit -m "feat: add cross-phase core rules and example session"
```

---

## Task 9: Comprehensive README

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Replace README with full documentation**

Overwrite `README.md`:

````markdown
# AI Rubberduck

A Claude Code plugin for rubberduck-style learning sessions. You explain a topic to an AI that plays the role of a new hire who has never seen your code. The AI asks probing questions, pretending not to know the answers. At the end, it drops the role-play, reads your actual code, and gives you **gap-focused feedback** on what you explained well, what you glossed over, and what you got factually wrong.

## Why

As AI handles more of the development work, human domain understanding in a codebase tends to drift downward. New hires used to force existing engineers to re-learn by explaining — but in many teams, onboarding is disappearing. This plugin puts an AI in the newcomer's seat so you can keep that "learn by teaching" loop.

## Install

This is a Claude Code plugin. To install from source:

```bash
git clone https://github.com/your-org/ai-rubberduck.git
# Then add it to your Claude Code plugin configuration per the Claude Code docs.
```

(Marketplace distribution TBD.)

## Usage

From any project where you use Claude Code:

```
/rubberduck [topic] [depth] [--no-save]
```

- `topic` — what you want to explain (e.g., "auth system", "cache layer", "job scheduler")
- `depth` — `shallow` (3–5 Qs), `medium` (6–10, default), or `deep` (10+)
- `--no-save` — skip saving the feedback report

Examples:

```
/rubberduck                                # fully interactive
/rubberduck auth-system                    # topic given, AI asks depth
/rubberduck auth-system deep               # ready to go
/rubberduck "order pipeline" medium --no-save
```

## What it does

1. **Intake**: picks up topic and depth from args, asks for whatever's missing.
2. **Q&A**: You explain; the AI plays a brand-new engineer asking probing questions — about high availability, concurrency, failure handling, and other cross-cutting concerns. It does NOT read your code during this phase.
3. **Grading**: The AI drops the role-play, reads the relevant parts of your repo, and produces a report like:
   ```
   # auth-system — Understanding Feedback (2026-04-24)
   **Summary**: Token lifecycle is solid, but Redis-down fallback and rate limiting are gaps.

   ## ✅ Well explained
   - JWT access/refresh separation and expiry policy
   - Refresh token rotation + blacklist

   ## ⚠️ Shaky
   - Redis unavailability fallback — couldn't answer

   ## ❌ Factcheck
   - "blacklist TTL = original token TTL" — actually at `src/auth/session.ts:112`, a 24h safety buffer is added for clock drift.

   ## 💡 Next to explore
   - `src/middleware/rate-limiter.ts`
   - Graceful degradation patterns for Redis outages
   ```
4. **Save**: Saves the report to `.rubberduck/sessions/YYYY-MM-DD-<slug>.md` (unless `--no-save`). Warns if `.rubberduck/` isn't in your `.gitignore`.

## Privacy

- The Q&A transcript is **not saved** — only the final feedback report.
- The feedback report can reference file paths and short code excerpts from your repo. Add `.rubberduck/` to your `.gitignore` to keep sessions out of version control.
- Everything runs locally through your Claude Code session. No external services.

## Limitations

- Prompt-based phase discipline. If the model slips out of role, results degrade. File an issue if you see it.
- Grading quality depends on how well the AI can navigate your repo with `Read`/`Grep`.
- Monolingual session — the session stays in whichever language you start in.

## Contributing

Run the structural test before committing:

```bash
bash tests/test_structure.sh
```

## License

MIT — see [LICENSE](LICENSE).
````

- [ ] **Step 2: Run test — expect pass**

```bash
bash tests/test_structure.sh
```

Expected: `All structural checks passed.` (README changes don't affect the structural test, but re-run for sanity.)

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "docs: expand README with usage, example, and privacy notes"
```

---

## Task 10: Manual end-to-end smoke test

**Files:** none (manual verification)

This isn't a file-creation task — it's a manual check that the plugin actually works when loaded by Claude Code. Automated testing of prompt behavior is out of scope.

- [ ] **Step 1: Run the full structural test**

```bash
bash tests/test_structure.sh
```

Expected: all `PASS:` lines and `All structural checks passed.`

- [ ] **Step 2: Load the plugin in Claude Code**

Follow the Claude Code plugin installation flow to load this directory as a plugin. Consult Claude Code docs for current steps — they may evolve.

- [ ] **Step 3: Run a smoke session**

In a Claude Code session inside another project you know well:

```
/rubberduck some-topic-you-know shallow
```

Verify (visually):
- AI does NOT use `Read`/`Grep`/`Glob`/`Bash` during Phases 1–2. (Watch the tool calls.)
- AI asks general-principle questions, not project-specific ones, in Phase 2.
- When you say "done", AI transitions to Phase 3 and starts reading files.
- Phase 3 output follows the exact format from Phase 3's spec (Summary, ✅, ⚠️, ❌, 💡 sections).
- Unless you pass `--no-save`, a file appears at `.rubberduck/sessions/YYYY-MM-DD-<slug>.md`.
- If `.rubberduck/` isn't in `.gitignore`, a warning prints.

- [ ] **Step 4: If anything fails the smoke test**

Iterate on the prompt in `commands/rubberduck.md`. Each iteration: edit, re-run structural test, re-run smoke session, commit.

No formal "pass" output for this task — it's a judgment call. Once you're satisfied, mark the task done.

---

## Summary of commits

After executing this plan, `git log --oneline` should show (approximately):

```
<h> docs: expand README with usage, example, and privacy notes
<h> feat: add cross-phase core rules and example session
<h> feat: add Phase 4 (Save) to rubberduck command
<h> feat: add Phase 3 (Grading) to rubberduck command
<h> feat: add Phase 2 (Q&A role-play) to rubberduck command
<h> feat: add Phase 1 (Intake) to rubberduck command
<h> feat: scaffold rubberduck command file with frontmatter
<h> feat: add plugin manifest and structural test harness
<h> chore: add LICENSE, .gitignore, and README stub
<h> Add initial design doc for ai-rubberduck plugin
```
