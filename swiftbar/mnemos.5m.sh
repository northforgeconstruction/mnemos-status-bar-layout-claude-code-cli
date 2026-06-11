#!/usr/bin/env bash
# <bitbar.title>MNEMOS</bitbar.title>
# <bitbar.version>v0.1.0</bitbar.version>
# <bitbar.author>Phyrom Oum</bitbar.author>
# <bitbar.author.github>northforgeconstruction</bitbar.author.github>
# <bitbar.desc>Shows MNEMOS state: current project phase, snapshot count, context tokens, session age, Jira open tickets.</bitbar.desc>
# <bitbar.dependencies>bash,jq</bitbar.dependencies>
#
# Install: drop into ~/.config/swiftbar/plugins/ and chmod +x.
# Reads from: ~/.mnemos/cache/<project>/ for whichever project most recently fired SessionStart.
#
# Refreshes every 5 minutes (filename convention .5m.sh).

set -uo pipefail

MNEMOS_HOME="${MNEMOS_HOME:-${HOME}/.mnemos}"

# Find the most-recently-active project
LAST_PROJECT=""
LAST_AGE=999999
if [ -d "${MNEMOS_HOME}/cache" ]; then
  for project_dir in "${MNEMOS_HOME}/cache"/*/; do
    [ -d "$project_dir" ] || continue
    local_ts_file="${project_dir}session-start.timestamp"
    [ -f "$local_ts_file" ] || continue
    ts_mtime=$(stat -f %m "$local_ts_file" 2>/dev/null || echo 0)
    now=$(date +%s)
    age=$(( now - ts_mtime ))
    if [ "$age" -lt "$LAST_AGE" ]; then
      LAST_AGE=$age
      LAST_PROJECT=$(basename "$project_dir")
    fi
  done
fi

if [ -z "$LAST_PROJECT" ]; then
  echo "🧠 idle"
  echo "---"
  echo "No active MNEMOS project"
  echo "Cache dir: ${MNEMOS_HOME}/cache | refresh=true"
  exit 0
fi

CACHE_DIR="${MNEMOS_HOME}/cache/${LAST_PROJECT}"

# Read snapshot count
SNAP_COUNT=0
if [ -d "${CACHE_DIR}/history" ]; then
  SNAP_COUNT=$(ls "${CACHE_DIR}/history"/*.json 2>/dev/null | wc -l | tr -d ' ')
fi

# Read latest snapshot for context tokens
CONTEXT_TOKENS=0
if [ -f "${CACHE_DIR}/latest.json" ] && command -v jq >/dev/null 2>&1; then
  CONTEXT_TOKENS=$(jq -r '.context_tokens_estimated // 0' "${CACHE_DIR}/latest.json")
fi

# Read Jira open tickets
JIRA_OPEN=0
if [ -f "${CACHE_DIR}/jira-open-tickets.json" ] && command -v jq >/dev/null 2>&1; then
  JIRA_OPEN=$(jq -r '.tickets | length' "${CACHE_DIR}/jira-open-tickets.json" 2>/dev/null || echo 0)
fi

# Read active agent
ACTIVE_AGENT="idle"
AGENT_EMOJI="💤"
AGENT_LABEL="idle"
AGENT_CATEGORY="idle"
AGENT_AGE_SEC=999999
if [ -f "${CACHE_DIR}/active-agent.json" ] && command -v jq >/dev/null 2>&1; then
  ACTIVE_AGENT=$(jq -r '.agent // "idle"' "${CACHE_DIR}/active-agent.json")
  AGENT_CATEGORY=$(jq -r '.category // "idle"' "${CACHE_DIR}/active-agent.json")
  AGENT_STARTED=$(jq -r '.started_at // ""' "${CACHE_DIR}/active-agent.json")
  if [ -n "$AGENT_STARTED" ]; then
    AGENT_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${AGENT_STARTED%Z}" "+%s" 2>/dev/null || \
                  date -d "$AGENT_STARTED" "+%s" 2>/dev/null || echo 0)
    NOW_EPOCH=$(date "+%s")
    AGENT_AGE_SEC=$((NOW_EPOCH - AGENT_EPOCH))
  fi
  # If stale (>5 min), mark as idle visually
  if [ "$AGENT_AGE_SEC" -gt 300 ]; then
    ACTIVE_AGENT="idle"
    AGENT_CATEGORY="idle"
  fi
  case "$ACTIVE_AGENT" in
    claude)            AGENT_EMOJI="🤖"; AGENT_LABEL="Claude" ;;
    human)             AGENT_EMOJI="👤"; AGENT_LABEL="human" ;;
    idle)              AGENT_EMOJI="💤"; AGENT_LABEL="idle" ;;
    mnemos-daemon)     AGENT_EMOJI="🧠"; AGENT_LABEL="daemon" ;;
    agent:Explore)     AGENT_EMOJI="🔍"; AGENT_LABEL="Explore" ;;
    agent:Plan)        AGENT_EMOJI="📐"; AGENT_LABEL="Plan" ;;
    agent:general-purpose) AGENT_EMOJI="🧰"; AGENT_LABEL="general-purpose" ;;
    agent:*)           AGENT_EMOJI="🛠"; AGENT_LABEL="${ACTIVE_AGENT#agent:}" ;;
    user-agent:*)      AGENT_EMOJI="🛠"; AGENT_LABEL="${ACTIVE_AGENT#user-agent:}" ;;
    mcp:*)             AGENT_EMOJI="🔌"; AGENT_LABEL="$ACTIVE_AGENT" ;;
    *)                 AGENT_EMOJI="❓"; AGENT_LABEL="$ACTIVE_AGENT" ;;
  esac
fi

# Format menu bar (top line)
MENU_BAR="🧠 ${LAST_PROJECT} · ${AGENT_EMOJI}${AGENT_LABEL}"
if [ "$CONTEXT_TOKENS" -gt 0 ]; then
  TOKENS_K=$((CONTEXT_TOKENS / 1000))
  MENU_BAR="${MENU_BAR} · ${TOKENS_K}K ctx"
fi

echo "$MENU_BAR"

# Dropdown details
echo "---"
echo "Active project: ${LAST_PROJECT} | href=file://${CACHE_DIR}"
echo "Active agent: ${AGENT_EMOJI} ${AGENT_LABEL} (${AGENT_CATEGORY})"
echo "Last session: $(date -r $(stat -f %m "${CACHE_DIR}/session-start.timestamp" 2>/dev/null) "+%Y-%m-%d %H:%M") | refresh=true"
echo "Snapshots: ${SNAP_COUNT}"
echo "Latest payload: ${CONTEXT_TOKENS} tokens"
echo "Jira open: ${JIRA_OPEN}"
echo "---"
echo "Open cache dir | href=file://${CACHE_DIR}"
echo "Open Obsidian Operator vault | href=obsidian://open?vault=obsidian-operator"
echo "Open Jira project | href=https://bldsync.atlassian.net/jira/projects"
echo "---"
echo "Refresh | refresh=true"
