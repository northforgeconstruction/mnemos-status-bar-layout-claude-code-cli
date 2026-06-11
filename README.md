# MNEMOS Status Bar Layout

> Three surfaces, one source of truth. Phase + session state visible everywhere you look.

A sibling of [MNEMOS](https://github.com/northforgeconstruction/mnemos) that renders MNEMOS state across three operator surfaces:

| Surface | Where you see it | Plugin file |
|---|---|---|
| **Terminal statusline** | Your Claude Code prompt bar (`hostfin-statusline.sh` extension) | `bin/mnemos-statusline-render` |
| **macOS menu bar** | Top of your screen, always on | `swiftbar/mnemos.5m.sh` |
| **Obsidian vault panel** | Inside the Operator vault's `00-PORTFOLIO.md` | `vault/right-now-panel.md` |

All three read from the same data layer:

- `~/.mnemos/cache/<project>/` (MNEMOS's own snapshot + jira-open-tickets + history)
- `~/.mnemos/cache/<project>/active-agent.json` (current agent + transitions — owned by this repo, schema in `schemas/active-agent.schema.json`)
- `<project>/.phase.json` (current phase + start timestamp + active ticket — owned by this repo)
- `<project>/.mnemos-state.json` (curated state per MNEMOS's curation contract)

## Why this is a separate repo

Per [MNEMOS](https://github.com/northforgeconstruction/mnemos)'s 2026-06-11 repositioning, the "session-rehydration layer" framing is now table stakes (Anthropic ships auto memory natively). MNEMOS's actual moat is **cross-system state orchestration** — Jira + Obsidian + Claude Code + MCP in one coherent state. This repo is the **operator-visible surface** of that orchestration. Every glance reinforces the moat.

## What it tracks

The combined statusline display, all rendered from `.phase.json` + MNEMOS cache:

```
Line 1:  🤖 Fable 5 │ 📁 obsidian-operator │ 🌿 vault (Drive) │ 🎯 Build · 6/11 09:00 (3d 5h) · OBS-3
Line 2:  69K/1M 7% │ 5h 12%·13:10 │ 7d 20%·Mon 15 │ 🧠 4·18K │ ⏱ 2h 14m │ 💰 $0.42 89%c │ 🔍 Explore
```

The last segment shows the **active agent** — who's actually touching files right now. Possible values:

- `🤖 Claude` — main orchestrator
- `🔍 Explore` / `📐 Plan` / `🧰 general-purpose` — Claude-installed subagents
- `🛠 my-reviewer` — user-installed subagent (color cues distinguish)
- `🔌 mcp:atlassian` — MCP service mid-call
- `👤 human` — direct file edit (via your editor, not Claude)
- `💤 idle` — no activity in the last 5 minutes

See `docs/DESIGN_SYSTEM.md` → "Agent categories" for the full taxonomy.

| Field | Source |
|---|---|
| Model | Claude Code session env |
| Folder | `basename $PWD` |
| Repo/Branch | `git` if repo; "vault (Drive)" or "n/a" otherwise |
| Phase + started + duration | `.phase.json` |
| Current ticket | `.phase.json` |
| Tokens used / max | Claude Code session API |
| Reset windows | Claude Code session API |
| MNEMOS snaps · payload | `~/.mnemos/cache/<project>/` |
| Session timer | `~/.mnemos/cache/<project>/session-start.timestamp` |
| Session cost | `/usage` or `mnemos-stats --session` |

## Phase model

```
💭 Plan/Concept  →  🎼 Cowork  →  🎯 Build  →  🚀 Deploy  →  🔧 Maintenance
```

Each project's `.phase.json` tracks the current phase with start timestamp:

```json
{
  "phase": "build",
  "started_at": "2026-06-11T09:00:00-04:00",
  "ticket": "OBS-3",
  "previous": [
    {"phase": "cowork", "started_at": "2026-06-10T14:00:00", "ended_at": "2026-06-11T09:00:00"}
  ]
}
```

Phase transitions are deliberate rituals via `mnemos-phase set <name> --ticket <id>`.

## Mode-by-phase (Claude Code enforcement)

When Code CLI reads `.phase.json`, the recommended Claude Code mode follows automatically:

| Phase | Mode | Why |
|---|---|---|
| 💭 Plan/Concept | **Plan Mode** | Designing, not executing |
| 🎼 Cowork | **Manual** | Cross-system orchestration; deliberate per-action |
| 🎯 Build | **Auto-accept** | Heads-down coding; trust the agent |
| 🚀 Deploy | **Manual** | Production touches; explicit confirmation |
| 🔧 Maintenance | **Manual** | Production care; explicit confirmation |

`CLAUDE.md` snippet (drop-in for any repo) is in [`docs/MODE_BY_PHASE.md`](docs/MODE_BY_PHASE.md).

## Design system

One visual language across all three surfaces. Phase + state must look the same in the terminal, the menu bar, and the vault — see [`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md) for the full system:

- **Color tokens** mapped to terminal ANSI, SwiftBar hex, and Obsidian callout types
- **Phase visual language** — each of the 5 phases has a fixed color + emoji combination
- **State semantics** — idle / active / warning / error, encoded in color + symbol + text for accessibility
- **Icon vocabulary** — the canonical glyph table; don't add new emojis without updating it first
- **Per-surface components** — statusline lines, SwiftBar menu items, Obsidian callouts

The design system is the contract that lets all three surfaces feel like one product, not three.

## Install

(See [`docs/INSTALL.md`](docs/INSTALL.md) — to be written.)

Quick path for the impatient:

```bash
# Statusline (terminal)
cp bin/mnemos-statusline-render ~/.mnemos/bin/
# Then extend hostfin-statusline.sh to include the new fields

# SwiftBar (menu bar)
brew install --cask swiftbar
mkdir -p ~/.config/swiftbar/plugins
cp swiftbar/mnemos.5m.sh ~/.config/swiftbar/plugins/
chmod +x ~/.config/swiftbar/plugins/mnemos.5m.sh
# Restart SwiftBar; mnemos shows in menu bar

# Vault panel (Obsidian)
# Copy vault/right-now-panel.md into 00-PORTFOLIO.md at the top
# Requires Dataview + Templater plugins
```

## Status

Early. The data model (`.phase.json` + MNEMOS cache) is the load-bearing piece; the three renderers are thin shells on top. Currently scaffolded; rendering is stubbed.

See [Jira project for tracking](https://bldsync.atlassian.net/jira/software/projects/MNEM).

## License

TBD.
