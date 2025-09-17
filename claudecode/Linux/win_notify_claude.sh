# ~/.local/bin/claude_hook_to_windows.sh
#!/usr/bin/env bash
set -eu

PS_EXE="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
WIN_SCRIPT="C:\\Users\\MartinDavidson\\Scripts\\notify_claude.ps1"   # ← update if different

hook="$(cat)"  # Claude hook JSON on stdin

# Best-effort snippet: prefer Bash stdout, else .message, else fallback
snippet="$(
  printf '%s' "$hook" | jq -r '
    .tool_response.stdout? // .message? // .tool_name? // "Claude Code finished"
  ' 2>/dev/null || echo "Claude Code finished"
)"

# Trim to something toast-friendly
snippet="$(printf '%s' "$snippet" | head -n 12)"
if [ "$(printf '%s' "$snippet" | wc -c)" -gt 800 ]; then
  snippet="$(printf '%.800s' "$snippet")…"
fi

payload="$(jq -nc --arg msg "$snippet" '{ "last-assistant-message": $msg }')"

# Forward to Windows via -EncodedCommand
b64_payload=$(printf '%s' "$payload" | iconv -f UTF-8 -t UTF-16LE | base64 -w0)
ps="& '${WIN_SCRIPT}' -JsonInput ([Text.Encoding]::Unicode.GetString([Convert]::FromBase64String('$b64_payload')))"
encoded=$(printf '%s' "$ps" | iconv -f UTF-8 -t UTF-16LE | base64 -w0)

"$PS_EXE" -NoProfile -EncodedCommand "$encoded" >/dev/null 2>&1 &
