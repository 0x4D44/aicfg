#!/bin/bash
# ~/.codex/win_notify_codex.sh
JSON_DATA="$1"
PS_EXE="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
WIN_SCRIPT="C:\\Users\\MartinDavidson\\Scripts\\notify_codex.ps1"  

# Extract various fields
LAST_MESSAGE=$(echo "$JSON_DATA" | jq -r '.["last-assistant-message"] // "No message"')
TIMESTAMP=$(echo "$JSON_DATA" | jq -r '.timestamp // ""')
STATUS=$(echo "$JSON_DATA" | jq -r '.status // "completed"')
TASK_DURATION=$(echo "$JSON_DATA" | jq -r '.duration // ""')

# Build notification message
if [ -n "$TASK_DURATION" ]; then
    NOTIFICATION="Task $STATUS in $TASK_DURATION: $LAST_MESSAGE"
else
    NOTIFICATION="Task $STATUS: $LAST_MESSAGE"
fi

# Option 1: Pass as plain string parameter (simpler)
"$PS_EXE" -NoProfile -Command "& '$WIN_SCRIPT' -Message '$NOTIFICATION'" >/dev/null 2>&1 &

# Option 2: If you really need to pass the original JSON to PowerShell:
# escaped_json=$(echo "$JSON_DATA" | sed 's/"/\\"/g')
# "$PS_EXE" -NoProfile -Command "& '$WIN_SCRIPT' -JsonInput '$escaped_json'" >/dev/null 2>&1 &

# Log to file
echo "$(date): $NOTIFICATION" >> ~/.codex/task_history.log