# CLAUDE.md — MNEMOS Status Bar Layout · Claude Code CLI

## What this repo is

**The Claude Code CLI variant** of MNEMOS Status Bar Layout. Sibling of [northforgeconstruction/mnemos](https://github.com/northforgeconstruction/mnemos). Renders MNEMOS state across three operator surfaces:

1. Terminal statusline (extends `hostfin-statusline.sh`)
2. macOS menu bar (SwiftBar plugin)
3. Obsidian vault panel (Dataview block)

All three read from `~/.mnemos/cache/<project>/` + `<project>/.phase.json` + `<project>/active-agent.json`.

### Variant scope

This repo is the **Claude Code CLI** variant. Future harnesses (Claude Desktop, Codex CLI, Gemini CLI) will get their own variant repos sharing the schemas in `schemas/` and the design system in `docs/DESIGN_SYSTEM.md`. Renderers differ per harness; the data layer is portable. Don't add Claude-Desktop / Codex / Gemini renderers here — they belong in their own variant repos when the data layer is stable enough to be reused.

## Where context lives

1. **Current focus** — Jira `MNEM` project → tickets tagged `mnemos-status-bar-layout` → top of "In Progress"
2. **Recent decisions** — sibling MNEMOS repo's `docs/superpowers/specs/`
3. **Data layer schema** — `schemas/phase.schema.json` (canonical) + `docs/PHASE_SCHEMA.md` (human-readable)
4. **Architecture** — `README.md` for the surfaces overview
5. **Mode rules** — `docs/MODE_BY_PHASE.md` — drop-in CLAUDE.md snippet for other repos
6. **Design system** — `docs/DESIGN_SYSTEM.md` — color tokens, phase visual language, state semantics, icon vocabulary, per-surface components. **Read this before adding any visual output.**

## Where to write updates

- New rendering logic → its surface dir (`bin/`, `swiftbar/`, `vault/`)
- Schema changes → bump `schemas/phase.schema.json` version + update `docs/PHASE_SCHEMA.md`
- New phase transitions → extend `bin/mnemos-phase`
- Decisions during build → `docs/decisions/YYYY-MM-DD-<slug>.md`
- Status changes → Jira ticket transition + this CLAUDE.md if focus moves

## Current focus

Phase: 🚀 **deploy** (MNEM-83 — go-live record; MNEM-75 is the unrelated PreToolUse agent-tracking ticket that early commits mistakenly referenced). All three surfaces shipped: statusline (two-line, wired via /statusline), SwiftBar v0.2 (multi-project), vault panel (00-PORTFOLIO.md). Repo enrolled in MNEMOS (snapshot-before-compaction live). Next: observe real usage, then → maintenance.

## Mode by phase (auto-enforce)

When you read `.phase.json`, your Claude Code mode should match:

| Phase | Mode | Why |
|---|---|---|
| 💭 Plan/Concept | **Plan Mode** (Shift+Tab) | Designing, not executing — no code edits, no commits |
| 🎼 Cowork | **Manual** (default) | Cross-system orchestration; deliberate confirmation per action |
| 🎯 Build | **Auto-accept** (Shift+Tab toggle) | Heads-down coding; trust the agent to execute |
| 🚀 Deploy | **Manual** | Production touches; explicit confirmation per step |
| 🔧 Maintenance | **Manual** | Production care; explicit confirmation per step |

**Rule:** on session start, read `.phase.json`. If your current Claude Code mode does not match the recommended mode for the current phase, emit a banner:

> ⚠️ Current phase is `<phase>`; recommended mode is `<mode>`. Hit Shift+Tab to toggle if mismatched.

Do NOT silently proceed in the wrong mode. Wrong-mode work is an error class (e.g., editing code in Plan phase, or prompting per-action in Build phase).

## Project specifics

- **Smart commit pattern:** every commit references its `MNEM-N` ticket
- **No untracked files in main:** `.phase.json` is committed (it's project state, not user secret)
- **Data layer is the load-bearing piece:** if the schema is wrong, three renderers break in sync. Lock it before building renderers.

## Architecture

| File | Purpose |
|---|---|
| `schemas/phase.schema.json` | JSON schema for `.phase.json` — canonical |
| `bin/mnemos-phase` | CLI to set/get/transition phases |
| `bin/mnemos-statusline-render` | Renders multi-line statusline from cache + phase |
| `swiftbar/mnemos.5m.sh` | SwiftBar plugin script |
| `vault/right-now-panel.md` | Markdown + Dataview block for Obsidian vault |
| `docs/MODE_BY_PHASE.md` | Drop-in CLAUDE.md snippet for other repos |
| `docs/PHASE_SCHEMA.md` | Schema docs (human-readable) |
| `docs/INSTALL.md` | Per-surface install instructions |
| `examples/phase.example.json` | Sample `.phase.json` for testing |

## What NOT to do

- **Don't fork MNEMOS's data layer.** This repo READS from `~/.mnemos/cache/`; it doesn't write there. MNEMOS owns its own cache.
- **Don't add a fourth surface (web app, mobile, etc.) yet.** Three surfaces × one data layer is the discipline. Get the three solid before expanding.
- **Don't let renderers diverge.** All three use the same field names from `.phase.json` and the same lookup paths from `~/.mnemos/cache/`. Drift here defeats the purpose.
- **Don't add Claude Desktop / Codex / Gemini renderers here.** Those belong in their own variant repos (e.g., `mnemos-status-bar-layout-claude-desktop`) once the data layer is stable. This repo is scoped to Claude Code CLI.
- **Don't add new emojis, colors, or symbols without updating `docs/DESIGN_SYSTEM.md` first.** The icon vocabulary table is the contract. Adding a new glyph in code before adding it to the table = design drift.
- **Don't use color alone for state.** Every state cue must pair color + symbol + text (accessibility + monochrome-terminal compatibility).
- **Don't invent values when data is missing.** Show "—" (em-dash). Showing "0" or fake numbers breaks trust in the rendered state.

## References

- Sibling repo: github.com/northforgeconstruction/mnemos
- Renamed to: `mnemos-status-bar-layout-claude-code-cli` (was `mnemos-status-bar-layout`) on 2026-06-11. GitHub keeps the old URL redirecting for ~30 days.
- Operator vault product note for this work: TBD
- Jira: MNEM (https://bldsync.atlassian.net/jira/software/projects/MNEM) — file new tickets under MNEM with `tag:mnemos-status-bar-layout` for now until we split into its own project
