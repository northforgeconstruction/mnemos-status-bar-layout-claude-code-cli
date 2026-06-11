# Mode by phase — drop-in CLAUDE.md snippet

Copy the section below into any repo's `CLAUDE.md`. The rule self-enforces: when Claude Code reads `.phase.json`, it knows which mode to be in (and emits a banner if you're mismatched).

---

## Mode by phase (auto-enforce)

When you read `.phase.json`, your Claude Code mode should match the current phase:

| Phase | Claude Code mode | Why |
|---|---|---|
| 💭 **Plan/Concept** | **Plan Mode** (`Shift+Tab` once from default) | You're designing, not executing. No code edits, no commits. Output is a plan or design doc, not changes. |
| 🎼 **Cowork** | **Manual** (default) | Cross-system orchestration; deliberate confirmation per tool call. You're touching Jira, Drive, GitHub, vault — not one repo. |
| 🎯 **Build** | **Auto-accept** (`Shift+Tab` twice from default) | Heads-down coding in one repo. Trust the agent to execute against the focus list. |
| 🚀 **Deploy** | **Manual** | Production touches. Each step needs explicit confirmation. |
| 🔧 **Maintenance** | **Manual** | Production care. Don't auto-edit without confirmation. |

### Rule

On session start (or whenever `.phase.json` changes), check:

1. Read `<repo>/.phase.json` → get current phase
2. Detect current Claude Code mode (Plan / Manual / Auto-accept)
3. If they don't match, emit:

> ⚠️ Current phase is `<phase>`; recommended mode is `<mode>`. Hit `Shift+Tab` to toggle if you intended this; otherwise switch modes before continuing.

4. **Do not silently proceed in the wrong mode.** Wrong-mode work is an error class:
   - Editing code in Plan phase = scope creep into Build prematurely
   - Prompting per-action in Build phase = inefficient drag on flow state
   - Auto-accepting in Deploy phase = uncontrolled production touches

### How phase transitions happen

Use the `mnemos-phase` CLI (see [bin/mnemos-phase](../bin/mnemos-phase)):

```bash
mnemos-phase set build --ticket OBS-3
# Archives current phase to .previous, stamps new started_at = now,
# emits a log event, suggests new Claude Code mode
```

After transition, the next `Shift+Tab` should put you in the recommended mode.

### Examples

| Situation | Right move |
|---|---|
| Just wrote a plan in Claude Chat, opening Code CLI to implement | `mnemos-phase set build` → Auto-accept Mode |
| Realized mid-build that the design is wrong | `mnemos-phase set plan` → switch to Plan Mode → redesign → `mnemos-phase set build` to resume |
| Production deploy after Build is done | `mnemos-phase set deploy` → switch to Manual mode |
| Bug report in production | `mnemos-phase set maintenance` → Manual mode → fix → either back to Build (if more work) or stay in Maintenance |

### Why this matters

Without the mode rule, you waste energy fighting Claude Code's interaction model:

- In Build phase, every "do you want to run this?" prompt breaks flow.
- In Plan phase, auto-execution creates code that's not yet been thought through.
- In Deploy, auto-execution touches production without your eyes on each step.

Tying mode to phase makes the right mode the path of least resistance.
