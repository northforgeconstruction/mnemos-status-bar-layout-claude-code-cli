#!/usr/bin/env bash
# <bitbar.title>MNEMOS</bitbar.title>
# <bitbar.version>v0.2.0</bitbar.version>
# <bitbar.author>Phyrom Oum</bitbar.author>
# <bitbar.author.github>northforgeconstruction</bitbar.author.github>
# <bitbar.desc>Shows MNEMOS state across ALL active projects: per-project phase, agent, snapshot count, context tokens, Jira open tickets.</bitbar.desc>
# <bitbar.dependencies>bash,jq</bitbar.dependencies>
#
# Install: drop into ~/.config/swiftbar/plugins/ and chmod +x.
# Reads from: ~/.mnemos/cache/*/ for ALL MNEMOS-enrolled projects.
# Refreshes every 5 minutes (filename convention .5m.sh).
#
# v0.2: shows all projects in dropdown, summary stats in menu bar.

set -uo pipefail

MNEMOS_HOME="${MNEMOS_HOME:-${HOME}/.mnemos}"
STALE_THRESHOLD_SEC=300  # 5 min — agents considered idle after this

# ── Helpers ─────────────────────────────────────────────────────────────
now_epoch() { date "+%s"; }

agent_emoji() {
  case "$1" in
    claude)            echo "🤖" ;;
    human)             echo "👤" ;;
    idle|"")           echo "💤" ;;
    mnemos-daemon)     echo "🧠" ;;
    agent:Explore)     echo "🔍" ;;
    agent:Plan)        echo "📐" ;;
    agent:general-purpose) echo "🧰" ;;
    agent:*)           echo "🛠" ;;
    user-agent:*)      echo "🛠" ;;
    mcp:*)             echo "🔌" ;;
    *)                 echo "❓" ;;
  esac
}

phase_emoji() {
  case "$1" in
    plan)         echo "💭" ;;
    cowork)       echo "🎼" ;;
    build)        echo "🎯" ;;
    deploy)       echo "🚀" ;;
    maintenance)  echo "🔧" ;;
    *)            echo "" ;;
  esac
}

agent_label() {
  case "$1" in
    agent:*)      echo "${1#agent:}" ;;
    user-agent:*) echo "${1#user-agent:}" ;;
    *)            echo "$1" ;;
  esac
}

# ── Gather all projects ─────────────────────────────────────────────────
TOTAL_PROJECTS=0
ACTIVE_PROJECTS=0
TOTAL_SNAPS=0
TOTAL_CTX_TOKENS=0
TOTAL_JIRA_OPEN=0

declare -a PROJECT_LINES=()

if [ -d "${MNEMOS_HOME}/cache" ]; then
  NOW=$(now_epoch)
  for project_dir in "${MNEMOS_HOME}/cache"/*/; do
    [ -d "$project_dir" ] || continue
    PROJECT_ID=$(basename "$project_dir")
    TOTAL_PROJECTS=$((TOTAL_PROJECTS + 1))

    # Last session
    LAST_ACTIVE="—"
    LAST_AGE_SEC=999999
    if [ -f "${project_dir}session-start.timestamp" ]; then
      TS_MTIME=$(stat -f %m "${project_dir}session-start.timestamp" 2>/dev/null || echo 0)
      LAST_AGE_SEC=$((NOW - TS_MTIME))
      if [ "$LAST_AGE_SEC" -lt 86400 ]; then
        LAST_ACTIVE=$(date -r "$TS_MTIME" "+%H:%M" 2>/dev/null)
      else
        LAST_ACTIVE=$(date -r "$TS_MTIME" "+%m-%d" 2>/dev/null)
      fi
    fi

    # Snapshot count
    SNAPS=0
    [ -d "${project_dir}history" ] && SNAPS=$(ls "${project_dir}history"/*.json 2>/dev/null | wc -l | tr -d ' ')
    TOTAL_SNAPS=$((TOTAL_SNAPS + SNAPS))

    # Context tokens
    CTX=0
    if [ -f "${project_dir}latest.json" ] && command -v jq >/dev/null 2>&1; then
      CTX=$(jq -r '.context_tokens_estimated // 0' "${project_dir}latest.json" 2>/dev/null || echo 0)
    fi
    TOTAL_CTX_TOKENS=$((TOTAL_CTX_TOKENS + CTX))

    # Jira open
    JIRA=0
    if [ -f "${project_dir}jira-open-tickets.json" ] && command -v jq >/dev/null 2>&1; then
      JIRA=$(jq -r '.tickets | length' "${project_dir}jira-open-tickets.json" 2>/dev/null || echo 0)
    fi
    TOTAL_JIRA_OPEN=$((TOTAL_JIRA_OPEN + JIRA))

    # Phase (from .phase.json — mirror copy at ~/.mnemos/cache/<project>/phase-mirror.json)
    PHASE="—"
    PHASE_EMOJI_VAL=""
    TICKET="—"
    if [ -f "${project_dir}phase-mirror.json" ] && command -v jq >/dev/null 2>&1; then
      PHASE=$(jq -r '.phase // "—"' "${project_dir}phase-mirror.json" 2>/dev/null)
      TICKET=$(jq -r '.ticket // "—"' "${project_dir}phase-mirror.json" 2>/dev/null)
      PHASE_EMOJI_VAL=$(phase_emoji "$PHASE")
    fi

    # Active agent
    AGENT="idle"
    AGENT_AGE_SEC=999999
    if [ -f "${project_dir}active-agent.json" ] && command -v jq >/dev/null 2>&1; then
      AGENT_RAW=$(jq -r '.agent // "idle"' "${project_dir}active-agent.json" 2>/dev/null)
      AGENT_STARTED=$(jq -r '.started_at // ""' "${project_dir}active-agent.json" 2>/dev/null)
      if [ -n "$AGENT_STARTED" ]; then
        AGENT_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${AGENT_STARTED%Z}" "+%s" 2>/dev/null || \
                      date -d "$AGENT_STARTED" "+%s" 2>/dev/null || echo 0)
        AGENT_AGE_SEC=$((NOW - AGENT_EPOCH))
      fi
      if [ "$AGENT_AGE_SEC" -lt "$STALE_THRESHOLD_SEC" ]; then
        AGENT="$AGENT_RAW"
      fi
    fi
    AGENT_EMOJI_VAL=$(agent_emoji "$AGENT")
    AGENT_LABEL_VAL=$(agent_label "$AGENT")

    # Active if last session within 24h
    if [ "$LAST_AGE_SEC" -lt 86400 ]; then
      ACTIVE_PROJECTS=$((ACTIVE_PROJECTS + 1))
    fi

    # Build per-project dropdown line
    PHASE_DISPLAY=""
    [ -n "$PHASE_EMOJI_VAL" ] && PHASE_DISPLAY=" · ${PHASE_EMOJI_VAL} ${PHASE}"
    [ "$TICKET" != "—" ] && [ -n "$TICKET" ] && [ "$TICKET" != "null" ] && PHASE_DISPLAY="${PHASE_DISPLAY} · ${TICKET}"

    PROJECT_LINES+=("${PROJECT_ID}${PHASE_DISPLAY} · ${AGENT_EMOJI_VAL} ${AGENT_LABEL_VAL} · ${SNAPS} snaps · $((CTX / 1000))K ctx · 🎫${JIRA} · last ${LAST_ACTIVE} | href=file://${project_dir}")
  done
fi

# ── Menu bar (top line) ─────────────────────────────────────────────────
if [ "$TOTAL_PROJECTS" -eq 0 ]; then
  echo "🧠 idle"
  echo "---"
  echo "No active MNEMOS projects"
  echo "Cache dir: ${MNEMOS_HOME}/cache | refresh=true"
  exit 0
fi

MENU_BAR="🧠 ${ACTIVE_PROJECTS}/${TOTAL_PROJECTS}"
if [ "$TOTAL_SNAPS" -gt 0 ]; then
  MENU_BAR="${MENU_BAR} · ${TOTAL_SNAPS}snaps"
fi
if [ "$TOTAL_CTX_TOKENS" -gt 0 ]; then
  MENU_BAR="${MENU_BAR} · $((TOTAL_CTX_TOKENS / 1000))K"
fi
if [ "$TOTAL_JIRA_OPEN" -gt 0 ]; then
  MENU_BAR="${MENU_BAR} · 🎫${TOTAL_JIRA_OPEN}"
fi

echo "$MENU_BAR"

# ── Dropdown ────────────────────────────────────────────────────────────
echo "---"
echo "MNEMOS — ${ACTIVE_PROJECTS} of ${TOTAL_PROJECTS} active in last 24h"
echo "---"

# Per-project lines (sorted alphabetically by project name)
printf '%s\n' "${PROJECT_LINES[@]}" | sort

echo "---"
echo "Open cache dir | href=file://${MNEMOS_HOME}/cache/"
echo "Open Obsidian Operator vault | href=obsidian://open?vault=obsidian-operator"
echo "Open Jira | href=https://bldsync.atlassian.net/jira/projects"
echo "---"
echo "Refresh | refresh=true"
