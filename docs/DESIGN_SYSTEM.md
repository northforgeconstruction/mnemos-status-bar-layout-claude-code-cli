# Design System

> One visual language across three surfaces. Phase + state must look the same in the terminal, the menu bar, and the vault — or the cross-system narrative breaks.

## Principles

1. **State legibility over decoration.** Every glyph and color answers the question "what is the system doing right now?" If a visual element doesn't surface state, it shouldn't be there.
2. **Consistency across surfaces.** A green dot means "active" in the terminal, menu bar, and vault. If you can't say what a color/emoji means in one sentence, it's not in the system.
3. **Glance-able by default.** Top-level views (menu bar item, top of statusline) must communicate state in <1 second. Detail is in the dropdown / second line.
4. **Honest about uncertainty.** When data is stale or missing, show "—" (em-dash) or a dimmed value. Never invent a number.
5. **Accessible without color.** All state cues must be encoded in shape/symbol/text as well as color. Color is reinforcement, not the only signal.

---

## Design tokens

### Color palette

NFCG brand colors as the foundation. Each surface maps these to its native color system.

| Token | Hex | Use case | Terminal (256-color) | SwiftBar (hex) | Obsidian (callout type) |
|---|---|---|---|---|---|
| `--navy` | `#1E3A5F` | Primary brand, headers, defaults | `24` (dark blue) | `#1E3A5F` | `info` |
| `--orange` | `#E85D04` | Action, urgency, current focus | `202` (dark orange) | `#E85D04` | `warning` |
| `--amber` | `#F2A623` | Caution, in-progress, attention | `214` (orange) | `#F2A623` | `note` |
| `--green-active` | `#10B981` | Active state, success | `35` (green) | `#10B981` | `success` |
| `--red-blocked` | `#DC2626` | Blocked, error, hard-deny | `196` (red) | `#DC2626` | `error` |
| `--cyan-plan` | `#06B6D4` | Plan phase (thinking) | `45` (cyan) | `#06B6D4` | `tip` |
| `--purple-cowork` | `#9333EA` | Cowork phase (orchestration) | `129` (purple) | `#9333EA` | `quote` |
| `--gray-idle` | `#6B7280` | Idle, dimmed, secondary text | `244` (gray) | `#6B7280` | (default) |
| `--gray-mute` | `#9CA3AF` | Muted, stale, separator | `248` (light gray) | `#9CA3AF` | (default) |

### Typography (per surface)

| Surface | Font | Size constraints | Notes |
|---|---|---|---|
| Terminal | Whatever user's terminal uses | Single-line ~120 char target / multi-line as needed | Avoid wide unicode that may not render in all terminal fonts |
| SwiftBar menu bar | macOS system font (forced) | Truncated to ~30 chars for menu bar; dropdown unbounded | Use SF Symbols where possible for crisp rendering |
| Obsidian vault | Theme-controlled | Inherits user's theme | Use markdown emphasis sparingly; Dataview handles its own typography |

### Spacing / density

- **Terminal**: Single space between segments, ` │ ` (space-pipe-space) as segment separator
- **SwiftBar**: Menu items use `---` for visual breaks; submenus for grouped actions
- **Obsidian**: One blank line between sections; callouts for state blocks

### Icon vocabulary

Emojis must be consistent across all three surfaces. Add to this table before using a new glyph anywhere.

| Symbol | Meaning | Where it appears |
|---|---|---|
| 🧠 | MNEMOS-the-system itself | Statusline prefix when MNEMOS data; SwiftBar menu bar icon |
| 🤖 | Main Claude orchestrator (active agent) | Statusline model field; agent field when `claude` |
| 📁 | Folder / project | Statusline folder field |
| 🌿 | Git branch | Statusline branch field |
| 💭 | Phase: Plan/Concept | Phase indicator everywhere |
| 🎼 | Phase: Cowork | Phase indicator everywhere |
| 🎯 | Phase: Build | Phase indicator everywhere |
| 🚀 | Phase: Deploy | Phase indicator everywhere |
| 🔧 | Phase: Maintenance | Phase indicator everywhere |
| ⏱ | Timer (session or phase) | Statusline timer fields |
| 💰 | Cost / billing | Statusline cost field |
| 📸 | Snapshot count | MNEMOS data summary |
| 🎫 | Jira ticket count | MNEMOS data summary |
| 🔍 | Subagent: Explore | Active agent (claude-installed) |
| 📐 | Subagent: Plan | Active agent (claude-installed) |
| 🧰 | Subagent: general-purpose | Active agent (claude-installed) |
| 🛠 | Subagent: user-installed (any) | Active agent (user-installed) |
| 🔌 | MCP service active | Active agent (mcp:*) |
| 👤 | Human directly editing | Active agent |
| 💤 | Idle / no active agent | Active agent (default) |
| ✓ | Success / done | Inline confirmations |
| ✗ | Failure / blocked | Inline error |
| ⚠️ | Warning, mode mismatch | Banner output |
| ⛔ | Hard deny, RBAC block | RBAC checks |
| — | No data / not applicable | When a field is intentionally blank |

**Don't use:** any other emoji without adding it here first. Drift in vocabulary defeats the cross-surface consistency.

### Agent categories (active-agent.json)

The `active-agent.json` data file tracks which actor is doing work in a project. Four top-level categories drive display grouping + color:

| Category | Pattern | Examples | Color token | Display in statusline |
|---|---|---|---|---|
| **Orchestrator** | `claude` | Main Claude Code session | `--navy` | `🤖 Claude` |
| **Claude-installed subagent** | `agent:<role>` | `agent:Explore`, `agent:Plan`, `agent:general-purpose` | `--green-active` | `🔍 Explore`, `📐 Plan`, `🧰 general-purpose` |
| **User-installed subagent** | `user-agent:<name>` | `user-agent:my-reviewer`, `user-agent:doc-linter` | `--cyan-plan` | `🛠 my-reviewer` (with tooltip indicating user-installed) |
| **MCP service** | `mcp:<service>` | `mcp:atlassian`, `mcp:github`, `mcp:chrome-devtools` | `--purple-cowork` | `🔌 mcp:atlassian` |
| Human | `human` | Direct file edit by Phyrom | `--navy` | `👤 human` |
| Daemon | `mnemos-daemon` | Future MNEMOS background process | `--gray-idle` | `🧠 daemon` |
| Idle | `idle` | No activity in the last N seconds | `--gray-idle` | `💤 idle` |

**Why distinguish user-installed from Claude-installed:**

- Audit + accountability — user-installed agents are owned by the user; Claude-installed are owned by Anthropic/Claude Code
- Permission/RBAC context — different defaults may apply per category
- Cost attribution — different agents may have different rate cards
- Mental model — "what subprocess is touching my work, and did I write it?"

### Agent state semantics

| State | When | Display |
|---|---|---|
| **Active** | Agent currently mid-tool-call | Full color, full label |
| **Recently active** | Last activity within 60 sec | Full color, full label |
| **Stale** | Last activity 60-300 sec ago | Dimmed (`--gray-idle`), label intact |
| **Idle** | No activity for >300 sec | `💤 idle` |
| **Unknown** | Agent name not in vocabulary | `❓ <name>` — surfaces the drift so it can be added to the vocabulary table |

---

## Phase visual language

Each phase has a fixed color + emoji combination. **Never use a phase color outside its phase.**

| Phase | Emoji | Color | One-word vibe | Recommended Claude Code mode |
|---|---|---|---|---|
| Plan/Concept | 💭 | `--cyan-plan` (#06B6D4) | Thinking | Plan Mode |
| Cowork | 🎼 | `--purple-cowork` (#9333EA) | Orchestrating | Manual |
| Build | 🎯 | `--green-active` (#10B981) | Executing | Auto-accept Mode |
| Deploy | 🚀 | `--orange` (#E85D04) | Shipping | Manual |
| Maintenance | 🔧 | `--gray-idle` (#6B7280) | Steady | Manual |

### Phase transitions

A transition from phase to phase is a **visual event**. Surfaces should ack the change:

- **Terminal**: next statusline render shows new phase emoji + reset timer
- **SwiftBar**: menu bar icon's accent color shifts to new phase color
- **Obsidian**: vault panel updates its "Phase" line and re-renders timer

A transition into Deploy or Maintenance should be more prominent than Plan↔Cowork↔Build because production-affecting work needs higher visual weight.

---

## State semantics

These four states apply uniformly across all surfaces and all components.

| State | Color | Symbol | When |
|---|---|---|---|
| **Idle** | `--gray-idle` | (default) or 💤 | No active session / no recent activity |
| **Active** | `--green-active` | ✓ or solid dot | Current session live, data fresh |
| **Warning** | `--amber` | ⚠️ | Stale data, mode mismatch, approaching limit |
| **Error / Blocked** | `--red-blocked` | ✗ or ⛔ | Hook failed, schema invalid, RBAC denied |

### State display patterns

- **Pair color with shape/symbol** — never rely on color alone (color-blind users, monochrome terminals)
- **Dim non-critical values** — secondary text uses `--gray-mute`
- **Show last-known when stale** — better than showing nothing; mark with `⚠️` and the staleness duration

---

## Components per surface

### Terminal statusline

#### Component: line-1 (where am I)

```
🤖 Fable 5 │ 📁 obsidian-operator │ 🌿 vault (Drive) │ 🎯 Build · 6/11 09:00 (3d 5h) · OBS-3
```

**Variants:**

| Variant | Use when |
|---|---|
| Full | Default — terminal wide enough |
| Compact | Terminal narrower than 120 chars; drop emoji, shorten labels |
| Minimal | <80 chars; show only model + phase + ticket |

**States:**

| State | Visual |
|---|---|
| Phase Plan | 💭 in `--cyan-plan` |
| Phase Build | 🎯 in `--green-active` |
| Phase Deploy | 🚀 in `--orange` |
| Mode mismatch | ⚠️ prepended to phase segment |
| No `.phase.json` | `🎯 ?` — dimmed |

#### Component: line-2 (budget + state)

```
69K/1M 7% │ 5h 12%·13:10 │ 7d 20%·Mon 15 │ 🧠 4·18K │ ⏱ 2h 14m │ 💰 $0.42 89%c │ 🔍 Explore
```

The trailing agent segment follows the agent-category colors and only appears when `active-agent.json` exists for the project. `89%c` = cache-hit percentage of the last turn (`c` = cached).

**Color rules:**

| Field | Default | Approaching limit | At limit |
|---|---|---|---|
| Token usage | `--navy` | `--amber` (>70%) | `--red-blocked` (>90%) |
| 5h window | `--navy` | `--amber` (>70%) | `--red-blocked` (>90%) |
| 7d window | `--navy` | `--amber` (>70%) | `--red-blocked` (>90%) |
| MNEMOS data | `--gray-idle` | — | — |
| Session timer | `--gray-idle` | — | — |
| Session cost | `--gray-idle` | `--amber` (>$5) | `--red-blocked` (>$25) |

### SwiftBar menu bar plugin

#### Component: menu-bar-item

Compact view, ~30 char target.

```
🧠 obsidian-operator · 4snaps · 18K ctx
```

**Variants:**

| Variant | When |
|---|---|
| Active | Live session; show project + snaps + tokens |
| Idle | No active project; show "🧠 idle" only |
| Error | Cache unreadable; show "🧠 ⛔ error" |

**Color (icon accent only):**

- Phase color tints the brain emoji area subtly (via SwiftBar `font` + `color` params)

#### Component: dropdown

Shown when user clicks menu bar item.

```
Active project: obsidian-operator       (link to cache dir)
Phase: 🎯 Build since 6/11 09:00 (3d 5h)
Last session: 2026-06-11 09:00          (refresh)
Snapshots: 4
Latest payload: 18K tokens
Jira open: 7
---
Open cache dir
Open Obsidian Operator vault
Open Jira project
---
Refresh
```

**Component states:**

| State | Visual |
|---|---|
| Default | Plain text, default font |
| Hovered (auto by SwiftBar) | Highlighted background |
| Action item | Prefixed `→` or indented |

### Obsidian vault panel

#### Component: right-now-callout

Lives at top of `00-PORTFOLIO.md`. Uses Obsidian callouts for state coloring.

```markdown
> [!info] 🎯 Build · obsidian-operator
> - **Phase**: 🎯 Build since 6/11 09:00 (3d 5h)
> - **Ticket**: [[OBS-3]] · Portfolio Dataview query
> - **Session**: 2h 14m · $0.42 (89% cached)
> - **MNEMOS**: 4 snaps · 18K rehydration payload
> - **Mode**: Auto-accept (recommended for Build)
```

**Callout type by phase:**

| Phase | Callout type | Rendered color |
|---|---|---|
| Plan | `[!tip]` | Cyan |
| Cowork | `[!quote]` | Purple/gray |
| Build | `[!success]` | Green |
| Deploy | `[!warning]` | Orange |
| Maintenance | `[!note]` | Default |

**Component variants:**

| Variant | Use when |
|---|---|
| Full | Top of 00-PORTFOLIO.md — always |
| Compact | Inline in product notes — phase + ticket only |
| History | At bottom of a product note — collapsible phase history |

---

## Accessibility

### Color independence

Every state cue uses **color + symbol + text**. A monochrome render of the statusline still tells you what's happening because:

- Phase is encoded in emoji (`💭`/`🎼`/`🎯`/`🚀`/`🔧`)
- Warnings are encoded in `⚠️`
- Errors are encoded in `✗` or `⛔`
- Stale data is encoded with `—`

### Terminal compatibility

- Use ANSI 256-color where possible; fall back to 8-color basic palette
- If terminal does not support unicode, fall back to ASCII labels: `[plan]` `[cowork]` `[build]` etc.
- Detect via `tput colors` and `LC_ALL`/`LANG`

### Screen reader (Obsidian)

- Callout types announce as their role ("info", "success", "warning") — built into Obsidian
- Dataview tables are HTML tables under the hood, navigable by screen reader
- Phase emoji should have a text equivalent in the same line (we always pair: `🎯 Build`, not just `🎯`)

---

## Do's and Don'ts

| ✅ Do | ❌ Don't |
|---|---|
| Use the exact emoji from the icon vocabulary table | Substitute similar emojis ("📓" instead of "🧠") |
| Use the phase color only for that phase | Use green for Plan phase or cyan for Build |
| Pair color with a symbol | Rely on color alone for state |
| Show "—" for missing data | Show "0" or invent a value |
| Update emoji vocabulary BEFORE using new glyph | Sneak in new emojis surface by surface |
| Match SwiftBar terminology to terminal statusline | Use "Active project" in SwiftBar but "Working dir" in terminal |
| Default to dimmed (`--gray-idle`) | Default to brand color (visual noise) |

---

## Open questions

- **SF Symbol vs emoji for SwiftBar icon** — emoji is universal but SF Symbols render sharper. Pick one and stick with it.
- **Truncation strategy when statusline overflows** — drop right-to-left? collapse middle? abbreviate? Pick a rule.
- **Phase history visualization in Obsidian** — should we render the `previous` array as a Mermaid timeline? Or a simple table?
- **Animated state in SwiftBar** — does the SwiftBar plugin show "thinking" indicators during long ops? If so, what's the animation?

---

## Versioning

This design system is at **v0.1** — pre-implementation. Once the three surfaces ship and we observe real usage, breaking changes get versioned (v1.0, v1.1, etc.) and old conventions get a migration path.

---

## See also

- [`PHASE_SCHEMA.md`](PHASE_SCHEMA.md) — Schema for `.phase.json` (the data layer)
- [`MODE_BY_PHASE.md`](MODE_BY_PHASE.md) — Mode enforcement rules
- Sibling MNEMOS repo `BRAND.md` — North Forge / NFCG brand voice (informs but does not override this design system)
