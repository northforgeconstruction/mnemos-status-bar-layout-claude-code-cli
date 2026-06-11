# Screenshots

Visual proof points for the README and INSTALL docs. Each file is a captured render of a working surface.

## Index

| File | Surface | What it shows | Captured |
|---|---|---|---|
| `swiftbar-dropdown.png` | macOS menu bar (SwiftBar) | Multi-project dropdown listing all enrolled projects with per-project agent + snap count + ctx tokens + Jira open count | 2026-06-11 |
| `statusline-single-line.png` | Claude Code CLI terminal | Single-line statusline with model + folder + branch + phase + MNEMOS data + agent | TBD |
| `vault-right-now-panel.png` | Obsidian | "Right now" panel reading from `90-State/` read-cache notes | TBD |

## How to add a screenshot

1. Take screenshot on macOS: `Cmd-Shift-4` then space, click the surface (window or dropdown)
2. Save into this directory with a descriptive kebab-case name
3. Add an entry to the index table above
4. Reference it from the relevant doc (README.md, INSTALL.md, or DESIGN_SYSTEM.md) with markdown image syntax:

```markdown
![SwiftBar dropdown showing 7 projects](docs/screenshots/swiftbar-dropdown.png)
```

## Conventions

- PNG, not JPEG (sharper text rendering for terminal/UI shots)
- Max width ~1200px (resize if larger — GitHub renders inline at ~700px anyway)
- Crop to the actual surface; no desktop wallpaper bleeding in
- File names: `<surface>-<state>.png` (e.g., `swiftbar-dropdown.png`, `swiftbar-menu-bar-collapsed.png`)
- Update timestamps when you capture a new version (the surface evolves)
