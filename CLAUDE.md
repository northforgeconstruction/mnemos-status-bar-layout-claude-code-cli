# CLAUDE.md — MNEMOS Status Bar Layout

## What this repo is

Sibling of [northforgeconstruction/mnemos](https://github.com/northforgeconstruction/mnemos). Renders MNEMOS state across three surfaces:

1. Terminal statusline (extends `hostfin-statusline.sh`)
2. macOS menu bar (SwiftBar plugin)
3. Obsidian vault panel (Dataview block)

All three read from `~/.mnemos/cache/<project>/` + `<project>/.phase.json`.

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

`.phase.json` for this repo will start at `plan` until the first surface ships. Acceptance for moving to `build`: schema locked, `mnemos-phase` CLI working, statusline+swiftbar render real data from a fake `.phase.json`.

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
- **Don't add new emojis, colors, or symbols without updating `docs/DESIGN_SYSTEM.md` first.** The icon vocabulary table is the contract. Adding a new glyph in code before adding it to the table = design drift.
- **Don't use color alone for state.** Every state cue must pair color + symbol + text (accessibility + monochrome-terminal compatibility).
- **Don't invent values when data is missing.** Show "—" (em-dash). Showing "0" or fake numbers breaks trust in the rendered state.

## References

- Sibling repo: github.com/northforgeconstruction/mnemos
- Operator vault product note for this work: TBD
- Jira: MNEM (https://bldsync.atlassian.net/jira/software/projects/MNEM) — file new tickets under MNEM with `tag:mnemos-status-bar-layout` for now until we split into its own project
