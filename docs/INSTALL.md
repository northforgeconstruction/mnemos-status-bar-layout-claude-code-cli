# Install Guide

> One install for the system; one bootstrap per project. Total time: ~5 minutes.

## Prerequisites

| Required | Why | Install |
|---|---|---|
| `bash` 4+ | All scripts | macOS ships with bash 3.x; `brew install bash` for 4+ |
| `jq` | JSON parsing | `brew install jq` |
| `git` | Smart-commit pattern | macOS ships with it |

| Optional (per surface) | Surface | Install |
|---|---|---|
| SwiftBar | macOS menu bar | `brew install --cask swiftbar` |
| MNEMOS | All three surfaces (data layer) | github.com/northforgeconstruction/mnemos |
| Obsidian + Dataview + Templater | Vault panel | https://obsidian.md → Community Plugins |

The three surfaces are independent — install the ones you'll use. MNEMOS is recommended for full functionality but not strictly required for `mnemos-phase` to work standalone.

## Install (one-time, system-wide)

### Quick path

```bash
git clone https://github.com/northforgeconstruction/mnemos-status-bar-layout.git
cd mnemos-status-bar-layout
bash bin/install.sh
```

The installer is idempotent — safe to re-run after pulling updates.

### What `bin/install.sh` does

1. Checks prerequisites (`bash`, `jq`, MNEMOS, SwiftBar)
2. Copies `mnemos-phase` + `mnemos-session-setup` to `~/.local/bin/`
3. Copies `swiftbar/mnemos.5m.sh` to `~/.config/swiftbar/plugins/` (if SwiftBar is installed)
4. Prints next steps for the Obsidian vault panel (manual paste)
5. Prints next steps for the terminal statusline patch

### Add `~/.local/bin` to PATH

If the installer warned about PATH, add this to your shell config:

```bash
# ~/.zshrc or ~/.bashrc
export PATH="$HOME/.local/bin:$PATH"
```

Then `source ~/.zshrc` (or open a new terminal).

### Verify

```bash
mnemos-phase --help          # should print usage
mnemos-session-setup --help  # should print usage
```

## Per-project setup

For each project you want phase-tracked:

```bash
cd /path/to/your/project
mnemos-session-setup
```

Defaults to `plan` phase. Override with flags:

```bash
mnemos-session-setup --phase build --ticket OBS-3
```

The bootstrap will:
1. Create `.phase.json` in the current directory (skips if already exists)
2. Nudge you if `CLAUDE.md` is missing the [Mode by phase](MODE_BY_PHASE.md) snippet
3. Recommend the appropriate Claude Code mode for the current phase

## Per-surface install detail

### Surface 1 — Terminal statusline

The terminal statusline is implemented as an extension of MNEMOS's existing `hostfin-statusline.sh`. This repo doesn't ship a standalone replacement — it ships the new fields and the design system.

To add the new fields (phase, session timer, MNEMOS cache state) to your terminal statusline, patch `~/.mnemos/hooks/hostfin-statusline.sh`:

1. Read `.phase.json` if it exists in `$PWD`
2. Compute phase age from `started_at`
3. Read snapshot count from `~/.mnemos/cache/<project>/history/`
4. Read session age from `~/.mnemos/cache/<project>/session-start.timestamp`
5. Emit per the design system color tokens

Full patch + integration tests will land in a follow-up release. For now, see [`docs/DESIGN_SYSTEM.md`](DESIGN_SYSTEM.md) → "Terminal statusline" for the target layout.

### Surface 2 — SwiftBar menu bar

After `install.sh` ran successfully:

1. Open SwiftBar (Cmd+Space → "SwiftBar")
2. Click the SwiftBar menu bar icon → "Refresh All"
3. You should see `🧠 <project> · Nsnaps · NK ctx` near the right edge of your menu bar

If you don't see it:

- Verify the plugin file: `ls -la ~/.config/swiftbar/plugins/mnemos.5m.sh`
- Check it's executable: `chmod +x ~/.config/swiftbar/plugins/mnemos.5m.sh`
- Check SwiftBar's "Plugins directory" setting points to `~/.config/swiftbar/plugins`
- Run the plugin manually to see errors: `bash ~/.config/swiftbar/plugins/mnemos.5m.sh`

### Surface 3 — Obsidian vault panel

This is a manual paste (Obsidian doesn't auto-load templates from CLI).

1. Open your operator vault folder in Obsidian
2. Open `00-PORTFOLIO.md`
3. Pick a variant from [`vault/right-now-panel.md`](../vault/right-now-panel.md) (full, compact, or history)
4. Paste at the top of `00-PORTFOLIO.md` (just below the YAML frontmatter)
5. Edit the phase, timestamp, ticket to match your current `.phase.json`

For the **future** auto-render variant (Dataview reading from a vault-side mirror of `~/.mnemos/cache/`), see the "Dataview-powered auto-render (future)" section in `vault/right-now-panel.md`.

## Verify the whole install

After `install.sh` + `mnemos-session-setup` in a test project:

```bash
cd /tmp/test-project
mkdir -p /tmp/test-project && cd /tmp/test-project
mnemos-session-setup --phase build --ticket TEST-1
mnemos-phase status

# Expected output:
# Phase:    🎯 build
# Since:    <timestamp> (Xm)
# Ticket:   TEST-1
# Mode:     Auto-accept Mode  ← recommended Claude Code mode
```

Then check the SwiftBar menu bar — it should show the test project as the most-recently-active.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `mnemos-phase: command not found` | `~/.local/bin` not on PATH | Add to shell config; `source` it |
| `jq: command not found` | Prereq not installed | `brew install jq` |
| SwiftBar shows "🧠 idle" | No MNEMOS cache yet | Run a session in any MNEMOS-enrolled repo first |
| SwiftBar plugin doesn't show | Not executable | `chmod +x ~/.config/swiftbar/plugins/mnemos.5m.sh` |
| `.phase.json` shows wrong phase | Set with mismatched flag | `mnemos-phase set <correct-phase> --ticket <KEY>` to fix |
| Color codes show as garbage in terminal | Terminal doesn't support 256-color | Use a modern terminal (iTerm2, Alacritty, etc.) or set `TERM=xterm-256color` |

## Updating

```bash
cd ~/path/to/mnemos-status-bar-layout
git pull
bash bin/install.sh   # idempotent; copies the updated files
```

The schema version (`schema_version` field in `.phase.json`) handles breaking changes — `mnemos-phase` will refuse to operate on an unrecognized version and prompt for migration.

## Uninstall

```bash
rm ~/.local/bin/mnemos-phase
rm ~/.local/bin/mnemos-session-setup
rm ~/.config/swiftbar/plugins/mnemos.5m.sh   # refresh SwiftBar after
# .phase.json files in your projects are project state — keep or delete per-project
```

## What about Linux / Windows?

- **Linux**: terminal statusline + `mnemos-phase` work. SwiftBar doesn't exist; replace with Polybar or i3blocks (script is portable). Obsidian works.
- **Windows**: untested. WSL probably works for `mnemos-phase`. Native Windows would need adaptations.

Per the MNEMOS sibling repo, Linux portability is tracked as MNEM-37; same caveats apply here.
