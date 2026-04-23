# AI Rubberduck

<p align="center">
  <img src="assets/rubberduck-hero.png" alt="A tiny rubberduck 'new hire' at your keyboard, ready to be explained to" width="480">
</p>

A Claude Code plugin for rubberduck-style learning sessions. You explain a topic to an AI that plays the role of a new hire who has never seen your code. The AI asks probing questions, pretending not to know the answers. At the end, it drops the role-play, reads your actual code, and gives you **gap-focused feedback** on what you explained well, what you glossed over, and what you got factually wrong.

## Why

As AI handles more of the development work, human domain understanding in a codebase tends to drift downward. New hires used to force existing engineers to re-learn by explaining — but in many teams, onboarding is disappearing. This plugin puts an AI in the newcomer's seat so you can keep that "learn by teaching" loop.

## Install

### Option 1 — Install from GitHub (recommended)

Add the marketplace to your `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "my-rubber-duck": {
      "source": {
        "source": "github",
        "repo": "zerobell-lee/my-rubber-duck"
      }
    }
  }
}
```

Then in Claude Code:

```
/plugin install ai-rubberduck@my-rubber-duck
```

### Option 2 — Local clone (for hacking on the plugin)

```bash
git clone git@github.com:zerobell-lee/my-rubber-duck.git
claude --plugin-dir my-rubber-duck
```

### Verify

```
/ai-rubberduck:rubberduck
```

Phase 1 prompt should appear.

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
