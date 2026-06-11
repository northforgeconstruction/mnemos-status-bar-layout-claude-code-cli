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

# Format menu bar (top line)
MENU_BAR="🧠 ${LAST_PROJECT} · ${SNAP_COUNT}snaps"
if [ "$CONTEXT_TOKENS" -gt 0 ]; then
  TOKENS_K=$((CONTEXT_TOKENS / 1000))
  MENU_BAR="${MENU_BAR} · ${TOKENS_K}K ctx"
fi

echo "$MENU_BAR"

# Dropdown details
echo "---"
echo "Active project: ${LAST_PROJECT} | href=file://${CACHE_DIR}"
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
