# Right Now Panel — Obsidian vault component

> Drop-in markdown component for `00-PORTFOLIO.md` (or any vault index note). Renders current phase + session + MNEMOS state as a callout.

## How to use

1. Open `00-PORTFOLIO.md` in the operator vault
2. Paste the appropriate variant below at the top of the file (just after the YAML frontmatter)
3. Templater (if installed) or manual edits keep the values current

For full auto-rendering, this requires:

- **Dataview plugin** — for live queries against vault notes
- **Templater plugin** — for dynamic timestamp / age calculations
- A cached JSON file at `~/.mnemos/cache/<project>/latest.json` that the vault can read (Obsidian's restricted-write FS can't reach `~/.mnemos/`; you'll need a small helper script that copies the latest snapshot into the vault's `.mnemos-mirror/` folder periodically)

## Variants

### Variant: full (top of 00-PORTFOLIO.md)

Use Obsidian's callout syntax. Callout type matches phase per the design system.

```markdown
> [!success] 🎯 Build · obsidian-operator
> - **Phase**: 🎯 Build since 2026-06-11 09:00 (3d 5h)
> - **Ticket**: [[OBS-3]] · Portfolio Dataview query
> - **Session**: 2h 14m · $0.42 (89% cached)
> - **MNEMOS**: 4 snaps · 18K rehydration payload
> - **Mode**: Auto-accept (recommended for Build)
> - **Last snap**: 2026-06-11 14:30 (~24m ago)
```

Replace `[!success]` with the phase's callout type per design system:

| Phase | Callout |
|---|---|
| 💭 Plan | `[!tip]` |
| 🎼 Cowork | `[!quote]` |
| 🎯 Build | `[!success]` |
| 🚀 Deploy | `[!warning]` |
| 🔧 Maintenance | `[!note]` |

### Variant: compact (inline in product notes)

Single line, for product notes that want a "Right now" indicator without taking much space.

```markdown
> [!success] 🎯 Build · [[OBS-3]] · 2h 14m · MNEMOS 4 snaps
```

### Variant: history (collapsible, bottom of product note)

```markdown
> [!note]- Phase history
> | Phase | Started | Ended | Duration | Ticket |
> |---|---|---|---|---|
> | 🎼 Cowork | 2026-06-10 14:00 | 2026-06-11 09:00 | 19h | OBS-1 |
> | 💭 Plan | 2026-06-09 20:00 | 2026-06-10 14:00 | 18h | — |
> | (Current) 🎯 Build | 2026-06-11 09:00 | — | 3d 5h | OBS-3 |
```

## Dataview-powered auto-render (future)

When `~/.mnemos/cache/<project>/latest.json` is mirrored into the vault, this Dataview block renders the panel automatically from the cached JSON:

````markdown
```dataviewjs
const mnemos = await dv.io.load(".mnemos-mirror/obsidian-operator/latest.json")
const state = JSON.parse(mnemos)
const phase = state.phase ?? "unknown"
const phaseEmoji = { plan: "💭", cowork: "🎼", build: "🎯", deploy: "🚀", maintenance: "🔧" }[phase] ?? "❓"
const calloutType = { plan: "tip", cowork: "quote", build: "success", deploy: "warning", maintenance: "note" }[phase] ?? "info"

dv.paragraph(`> [!${calloutType}] ${phaseEmoji} ${phase} · ${state.project_id}
> - **Phase**: ${phaseEmoji} ${phase} since ${state.phase_started_at}
> - **Ticket**: ${state.ticket ?? "—"}
> - **MNEMOS**: ${state.snapshot_count} snaps · ${Math.round(state.context_tokens_estimated/1000)}K rehydration
`)
```
````

This is **future work** — requires:
1. A bridge script that periodically copies `~/.mnemos/cache/<project>/latest.json` into the vault's `.mnemos-mirror/` folder
2. The `latest.json` schema to include the phase fields (currently they live in `.phase.json` separately — needs unification or join logic)

For now, use the manual paste variants above.

## Design system compliance

All variants in this file follow [`../docs/DESIGN_SYSTEM.md`](../docs/DESIGN_SYSTEM.md):

- Phase emojis from the icon vocabulary (no improvisation)
- Callout types match the phase-color mapping
- Pair color (callout type) with text/emoji (the phase line) — no color-only state
- Use "—" for missing data, never "0" or invented values
- Compact variant stays under ~80 chars for terminal-like density

## Do's and don'ts (specific to this surface)

| ✅ Do | ❌ Don't |
|---|---|
| Match callout type to current phase | Use `[!info]` for everything |
| Include the phase emoji even when callout type implies it (e.g., `[!success] 🎯 Build`) | Rely on callout type alone for phase signal |
| Update timestamps when phase transitions | Let stale "since" timestamps drift days behind |
| Link the ticket as `[[OBS-3]]` so Obsidian's graph view picks it up | Write raw "OBS-3" with no link |
