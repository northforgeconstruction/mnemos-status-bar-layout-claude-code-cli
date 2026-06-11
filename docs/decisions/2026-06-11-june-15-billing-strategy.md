# 2026-06-11 — June 15 billing split: MNEMOS token/storage/cache strategy

## Context

Effective **2026-06-15**, Anthropic splits Claude subscription billing into two pools:

| Pool | Covers | Billing |
|---|---|---|
| **Interactive** (unchanged) | Claude.ai chat, Claude Desktop, Claude Code used interactively in the terminal | Subscription 5h/7d rate-limit windows, as today |
| **Agent SDK credit pool** (new) | `claude -p` headless, Agent SDK apps, scheduled/autonomous cloud agents, third-party harnesses | Full API list prices against a monthly credit (Pro $20 / Max 5x $100 / Max 20x $200), **no rollover** |

The split is keyed to **how the session is driven**, not what runs inside it:
skills, subagents (Agent tool), and MCP tool results inside an interactive CLI
session all stay on the subscription pool — they just consume context tokens.

## Audit (2026-06-11)

- MNEMOS snapshot/render pipeline (`~/.mnemos/hooks/*`, SwiftBar plugin,
  statusline, this repo's `bin/`) is **pure shell + jq — zero model calls**.
  Unaffected by the change.
- No user/project Claude Code hooks invoke `claude -p`. No crontab.
- Only API usage found: `poc-judge.py` / `poc-baseline-report.sh` judge
  ensemble, gated behind an explicit `ANTHROPIC_API_KEY` (already API-billed;
  June 15 changes nothing for them).
- Storage: `~/.mnemos/cache` is 1.6MB. Non-issue.

**Verdict: well positioned.** Interactive work stays on subscription; nothing
mechanical starts drawing the credit pool.

## Decisions / actions

1. **Activate the Agent SDK credit pool** (Anthropic activation email sent
   ~June 8) and treat it as the default budget for *deliberate* programmatic
   work — it's included in the subscription and evaporates monthly if unused.
   → Manual user action. No code.
2. **Snapshot-before-compaction**: enroll this repo in MNEMOS
   (`mnemos-enroll --profile ai-infra --jira-key MNEM`), which wires the
   existing mechanical `PreCompact` hook (`~/.mnemos/hooks/pre-compact.sh`)
   into `.claude/settings.json`. Snapshot fires exactly when session state is
   about to get lossy. Zero tokens.
3. **Lean rehydration payloads** — sibling-repo work (ticket draft below).
4. **Batch API for the judge ensemble** — sibling-repo work (ticket draft
   below); 50% off API list prices for latency-insensitive judge runs.

## Ticket drafts (file under MNEM, tag `mnemos-status-bar-layout`)

- **Lean rehydration payloads**: curate snapshot content to decisions +
  open state, not transcript replay. Target: keep rehydration ≤ ~20K tokens.
  Every K is re-read against the subscription window at each session start.
- **Route poc-judge through the Agent SDK credit pool**: after June 15
  activation, prefer the monthly credit over the pay-as-you-go API key for
  judge runs, up to the credit limit. Stacks with the Batch API (50% off)
  for non-urgent batches.

## Cross-harness portability (Desktop / outside agents / Skills / MCPs)

- **Claude Desktop**: interactive → subscription pool, same as CLI. But the
  *data capture* side of MNEMOS does not port: Desktop has no statusline and
  no shell-hook surface, so Desktop sessions won't write `~/.mnemos/cache/`.
  The SwiftBar + vault surfaces still *render* whatever the CLI wrote. A
  Desktop capture path (likely MCP-based) belongs in the future
  `mnemos-status-bar-layout-claude-desktop` variant repo — not here.
- **Skills / subagents / MCPs inside an interactive session**: subscription
  pool. They add context tokens (visible in the statusline ctx segment) but
  never touch the credit pool.
- **Outside agents** (Agent SDK apps, scheduled cloud agents, third-party
  tools driving Claude, `claude -p`): credit pool at API rates from June 15.
  MNEMOS doesn't change their billing — but its cache stays readable by them
  for free, since it's just local files.
