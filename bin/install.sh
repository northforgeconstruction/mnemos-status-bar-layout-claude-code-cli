#!/usr/bin/env bash
# install.sh — install MNEMOS Status Bar Layout for the current user.
#
# Wires up all three surfaces:
#   1. Terminal: mnemos-phase CLI to PATH
#   2. macOS menu bar: SwiftBar plugin to ~/.config/swiftbar/plugins/
#   3. Obsidian vault: prints manual paste instructions
#
# Idempotent — safe to re-run.

set -uo pipefail

# ── Colors (design system tokens) ───────────────────────────────────────
COLOR_NAVY='\033[38;5;24m'
COLOR_GREEN='\033[38;5;35m'
COLOR_AMBER='\033[38;5;214m'
COLOR_RED='\033[38;5;196m'
COLOR_GRAY='\033[38;5;244m'
COLOR_RESET='\033[0m'

ok()   { printf "${COLOR_GREEN}✓${COLOR_RESET} %s\n" "$*"; }
warn() { printf "${COLOR_AMBER}⚠${COLOR_RESET}  %s\n" "$*"; }
err()  { printf "${COLOR_RED}✗${COLOR_RESET} %s\n" "$*" >&2; }
info() { printf "${COLOR_GRAY}•${COLOR_RESET} %s\n" "$*"; }
head() { printf "\n${COLOR_NAVY}━━ %s ━━${COLOR_RESET}\n" "$*"; }

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL_BIN="${HOME}/.local/bin"
SWIFTBAR_PLUGINS="${HOME}/.config/swiftbar/plugins"

# ── Step 1: Prerequisites ───────────────────────────────────────────────
head "Step 1 — Prerequisites"

PREREQ_FAIL=0

check_cmd() {
  if command -v "$1" >/dev/null 2>&1; then
    ok "$1 found ($(command -v "$1"))"
  else
    err "$1 not found"
    PREREQ_FAIL=1
  fi
}

check_cmd bash
check_cmd jq

# MNEMOS itself
if [ -d "${HOME}/.mnemos" ]; then
  ok "MNEMOS installed at ~/.mnemos"
else
  warn "MNEMOS not installed at ~/.mnemos — status bar will work but with no data until you install MNEMOS"
  info "Install MNEMOS: github.com/northforgeconstruction/mnemos"
fi

# SwiftBar (optional, only needed for menu bar surface)
if [ -d "/Applications/SwiftBar.app" ] || command -v swiftbar >/dev/null 2>&1; then
  ok "SwiftBar found"
  SWIFTBAR_OK=1
else
  warn "SwiftBar not installed — menu bar surface will be skipped"
  info "Install: brew install --cask swiftbar"
  SWIFTBAR_OK=0
fi

if [ "$PREREQ_FAIL" -eq 1 ]; then
  err "Required prerequisites missing. Fix and re-run."
  exit 1
fi

# ── Step 2: Install mnemos-phase CLI ────────────────────────────────────
head "Step 2 — Install mnemos-phase CLI"

mkdir -p "$INSTALL_BIN"
cp "$REPO_DIR/bin/mnemos-phase" "$INSTALL_BIN/mnemos-phase"
chmod +x "$INSTALL_BIN/mnemos-phase"
ok "Installed $INSTALL_BIN/mnemos-phase"

# Optional: also install mnemos-session-setup
if [ -f "$REPO_DIR/bin/mnemos-session-setup" ]; then
  cp "$REPO_DIR/bin/mnemos-session-setup" "$INSTALL_BIN/mnemos-session-setup"
  chmod +x "$INSTALL_BIN/mnemos-session-setup"
  ok "Installed $INSTALL_BIN/mnemos-session-setup"
fi

# Also install mnemos-agent (active-agent tracking CLI)
if [ -f "$REPO_DIR/bin/mnemos-agent" ]; then
  cp "$REPO_DIR/bin/mnemos-agent" "$INSTALL_BIN/mnemos-agent"
  chmod +x "$INSTALL_BIN/mnemos-agent"
  ok "Installed $INSTALL_BIN/mnemos-agent"
fi

if [[ ":$PATH:" != *":$INSTALL_BIN:"* ]]; then
  warn "$INSTALL_BIN not on PATH"
  info "Add to your shell config (e.g., ~/.zshrc or ~/.bashrc):"
  info '  export PATH="$HOME/.local/bin:$PATH"'
fi

# ── Step 3: SwiftBar plugin (if SwiftBar installed) ─────────────────────
head "Step 3 — SwiftBar menu bar plugin"

if [ "$SWIFTBAR_OK" -eq 1 ]; then
  mkdir -p "$SWIFTBAR_PLUGINS"
  cp "$REPO_DIR/swiftbar/mnemos.5m.sh" "$SWIFTBAR_PLUGINS/mnemos.5m.sh"
  chmod +x "$SWIFTBAR_PLUGINS/mnemos.5m.sh"
  ok "Installed $SWIFTBAR_PLUGINS/mnemos.5m.sh"
  info "Refresh SwiftBar to load: click menu bar → 'Refresh All' or restart SwiftBar"
else
  info "Skipped — install SwiftBar then re-run this script"
fi

# ── Step 4: Obsidian vault panel ────────────────────────────────────────
head "Step 4 — Obsidian vault panel"

info "Manual step (one per vault):"
info "  1. Open your operator vault (~/Library/CloudStorage/.../obsidian-operator/)"
info "  2. Open 00-PORTFOLIO.md"
info "  3. Paste a variant from $REPO_DIR/vault/right-now-panel.md"
info "  4. Edit phase/timestamp/ticket as appropriate"
info "  5. Save"

# ── Step 5: Terminal statusline ─────────────────────────────────────────
head "Step 5 — Terminal statusline"

info "Terminal statusline extends MNEMOS's existing ~/.mnemos/hooks/hostfin-statusline.sh"
info "See $REPO_DIR/docs/INSTALL.md → 'Terminal statusline' section for the patch"

# ── Step 6: Per-project setup ───────────────────────────────────────────
head "Step 6 — Per-project setup"

info "For each project you want phase-tracked:"
info "  cd /path/to/your/project"
info "  mnemos-session-setup"
info "or, manually:"
info "  mnemos-phase set <plan|cowork|build|deploy|maintenance> [--ticket KEY]"

# ── Summary ─────────────────────────────────────────────────────────────
head "Install complete"

ok "mnemos-phase CLI installed at $INSTALL_BIN/"
[ "$SWIFTBAR_OK" -eq 1 ] && ok "SwiftBar plugin installed; refresh SwiftBar to see it"
info ""
info "Quick verify:"
info "  mnemos-phase --help"
info "  mnemos-phase status   (in a directory with .phase.json)"
info ""
info "Next: run 'mnemos-session-setup' in any project to initialize .phase.json"
