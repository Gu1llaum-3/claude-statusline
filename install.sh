#!/usr/bin/env bash
# Installs the Claude Code status line:
#   curl -fsSL https://raw.githubusercontent.com/Gu1llaum-3/claude-statusline/main/install.sh | bash
set -euo pipefail

REPO_RAW="${STATUSLINE_REPO_RAW:-https://raw.githubusercontent.com/Gu1llaum-3/claude-statusline/main}"
CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SCRIPT="$CONFIG_DIR/statusline.sh"
SETTINGS="$CONFIG_DIR/settings.json"
SELF="${BASH_SOURCE[0]:-}"  # empty when piped from curl

die() { printf '\033[31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
ok()  { printf '\033[32m✓\033[0m %s\n' "$*"; }

# Renders both layouts with sample data in a throwaway git repo, then asks on the terminal
# (stdin is the piped installer, so the answer is read from /dev/tty).
pick_layout() {
  local current=$1 demo now choice def=1 json
  [ "$current" = compact ] && def=2
  demo=$(mktemp -d)/my-project
  mkdir -p "$demo"
  if command -v git >/dev/null; then
    git -C "$demo" init -q 2>/dev/null && git -C "$demo" symbolic-ref HEAD refs/heads/main \
      && git -C "$demo" -c user.name=demo -c user.email=demo@example.com commit -q --allow-empty -m init \
      && touch "$demo/wip" || true
  fi
  now=$(date +%s)
  json=$(jq -n --arg cwd "$demo" --argjson now "$now" '{
    model: {display_name: "Opus 5.5 (1M context)"}, workspace: {current_dir: $cwd}, effort: {level: "high"},
    context_window: {used_percentage: 42, context_window_size: 1000000},
    rate_limits: {five_hour: {used_percentage: 31, resets_at: ($now + 8040)},
                  seven_day: {used_percentage: 85, resets_at: ($now + 198000)}}}')
  printf '\n1) full: three lines next to Clawd\n\n'
  "$SCRIPT" full <<<"$json"
  printf '\n2) compact: one line\n\n'
  "$SCRIPT" compact <<<"$json"
  rm -rf "${demo%/*}"
  printf '\nLayout [%d]: ' "$def" >/dev/tty
  read -r choice </dev/tty || choice=""
  case "${choice:-$def}" in
    2|compact) layout=compact ;;
    *)         layout=full ;;
  esac
}

# Everything lives in main: a truncated download runs nothing.
main() {
  command -v curl >/dev/null || die "curl is required"
  command -v jq   >/dev/null || die "jq is required (brew install jq / apt install jq)"
  command -v git  >/dev/null || printf '! git not found: branch will not be shown\n'

  mkdir -p "$CONFIG_DIR"

  # ── Script
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' EXIT
  # Run from a clone (./install.sh): use the statusline.sh next to it, else download it
  if [ -f "$SELF" ] && [ -f "$(dirname "$SELF")/statusline.sh" ] && [ -z "${STATUSLINE_REPO_RAW:-}" ]; then
    cp "$(dirname "$SELF")/statusline.sh" "$tmp"
  else
    curl -fsSL "$REPO_RAW/statusline.sh" -o "$tmp" || die "failed to download statusline.sh"
  fi
  head -n1 "$tmp" | grep -q '^#!' || die "downloaded statusline.sh is invalid"
  install -m 755 "$tmp" "$SCRIPT"
  ok "script installed: $SCRIPT"

  # ── settings.json (merge, other keys are kept)
  if [ -s "$SETTINGS" ]; then
    jq empty "$SETTINGS" 2>/dev/null || die "$SETTINGS is not valid JSON, nothing was changed"
  fi

  # ── Layout: STATUSLINE_LAYOUT, else ask with a preview, else keep the current one
  current=$(jq -r '.statusLine.command // "" | split(" ")[1] // ""' "$SETTINGS" 2>/dev/null || true)
  case "$current" in full|compact) ;; *) current="" ;; esac  # another status line, or an older install
  layout=${STATUSLINE_LAYOUT:-}
  if [ -z "$layout" ]; then
    if { : </dev/tty; } 2>/dev/null; then pick_layout "$current"; else layout=${current:-full}; fi
  fi
  case "$layout" in full|compact) ;; *) die "unknown layout: $layout (full or compact)" ;; esac
  ok "layout: $layout"

  if [ -s "$SETTINGS" ]; then
    cp "$SETTINGS" "$SETTINGS.bak"
    ok "backup: $SETTINGS.bak"
  else
    echo '{}' > "$SETTINGS"
  fi
  jq --arg cmd "$SCRIPT $layout" '.statusLine = {type: "command", command: $cmd}' "$SETTINGS" > "$tmp"
  cat "$tmp" > "$SETTINGS"  # rewrite in place: keeps file permissions
  ok "statusLine configured in $SETTINGS"

  printf '\nRestart Claude Code to see the new status line.\n'
}

main "$@"
