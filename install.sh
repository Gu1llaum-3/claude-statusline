#!/usr/bin/env bash
# Installs the Claude Code status line:
#   curl -fsSL https://raw.githubusercontent.com/Gu1llaum-3/claude-statusline/main/install.sh | bash
set -euo pipefail

REPO_RAW="${STATUSLINE_REPO_RAW:-https://raw.githubusercontent.com/Gu1llaum-3/claude-statusline/main}"
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SCRIPT="$CONFIG_DIR/statusline.sh"
SETTINGS="$CONFIG_DIR/settings.json"

die() { printf '\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
ok()  { printf '\033[32m✓\033[0m %s\n' "$*"; }

# Everything lives in main: a truncated download runs nothing.
main() {
  command -v curl >/dev/null || die "curl is required"
  command -v jq   >/dev/null || die "jq is required (brew install jq / apt install jq)"
  command -v git  >/dev/null || printf '! git not found: branch will not be shown\n'

  mkdir -p "$CONFIG_DIR"

  # ── Script
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' EXIT
  curl -fsSL "$REPO_RAW/statusline.sh" -o "$tmp" || die "failed to download statusline.sh"
  head -n1 "$tmp" | grep -q '^#!' || die "downloaded statusline.sh is invalid"
  install -m 755 "$tmp" "$SCRIPT"
  ok "script installed: $SCRIPT"

  # ── settings.json (merge, other keys are kept)
  if [ -s "$SETTINGS" ]; then
    jq empty "$SETTINGS" 2>/dev/null || die "$SETTINGS is not valid JSON, nothing was changed"
    cp "$SETTINGS" "$SETTINGS.bak"
    ok "backup: $SETTINGS.bak"
  else
    echo '{}' > "$SETTINGS"
  fi
  jq --arg cmd "$SCRIPT" '.statusLine = {type: "command", command: $cmd}' "$SETTINGS" > "$tmp"
  cat "$tmp" > "$SETTINGS"  # rewrite in place: keeps file permissions
  ok "statusLine configured in $SETTINGS"

  printf '\nRestart Claude Code to see the new status line.\n'
}

main "$@"
