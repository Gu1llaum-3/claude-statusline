#!/usr/bin/env bash
# Usage: statusline.sh [full|compact]   full = 3 lines next to Clawd (default), compact = 1 line
layout=${1:-full}
input=$(cat)
now=$(date +%s)

ORANGE=$'\033[38;2;217;119;87m'
RED=$'\033[31m'
GREEN=$'\033[32m'
CYAN=$'\033[36m'
DIM=$'\033[90m'
RESET=$'\033[0m'
SEP=" ${DIM}│${RESET} "

IFS='|' read -r model cwd ctx size used effort h5 h5r d7 d7r < <(jq -r '
  (.context_window // {}) as $c
  | ($c.current_usage // {}) as $u
  | [
      .model.display_name // "?",
      .workspace.current_dir // .cwd // "",
      $c.used_percentage // 0,
      $c.context_window_size // 0,
      (($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0)),
      .effort.level // "",
      .rate_limits.five_hour.used_percentage // "",
      .rate_limits.five_hour.resets_at // "",
      .rate_limits.seven_day.used_percentage // "",
      .rate_limits.seven_day.resets_at // ""
    ] | map(tostring) | join("|")' <<<"$input")

gauge() {  # $1 = percentage → segmented gauge (▋ = 5/8 of a cell, the remaining space separates segments)
  local p=${1%.*} n i c=$ORANGE fill="" empty=""
  (( p > 100 )) && p=100
  (( p >= 80 )) && c=$RED
  n=$(( (p + 5) / 10 )); (( n > 10 )) && n=10
  for ((i = 0; i < 10; i++)); do (( i < n )) && fill+="▋" || empty+="▋"; done
  printf '%s%s%s%s%s %d%%' "$c" "$fill" "$DIM" "$empty" "$RESET" "$p"
}

timer() {  # $1 = reset epoch → respawn countdown in the last quarter hour, else time left
  [ -z "$1" ] && return
  local s=$(( ${1%.*} - now ))
  if (( s >= 0 && s < 900 )); then printf ' %s↻ respawn %dmin%s' "$GREEN" $(( (s + 59) / 60 )) "$RESET"
  else left "$1"; fi
}

left() {  # $1 = reset epoch
  [ -z "$1" ] && return
  local s=$(( ${1%.*} - now )); (( s < 0 )) && s=0
  local d=$(( s / 86400 )) h=$(( s % 86400 / 3600 )) m=$(( s % 3600 / 60 ))
  if (( d > 0 )); then printf ' (%dd%02dh)' "$d" "$h"; else printf ' (%dh%02d)' "$h" "$m"; fi
}

fmt() {  # tokens → 134k, 1M, 1.5M
  local n=${1%.*}
  if (( n >= 1000000 )); then
    (( n % 1000000 == 0 )) && printf '%dM' $(( n / 1000000 )) \
      || printf '%d.%dM' $(( n / 1000000 )) $(( n % 1000000 / 100000 ))
  elif (( n >= 1000 )); then printf '%dk' $(( (n + 500) / 1000 ))
  else printf '%d' "$n"; fi
}

# ── ⎇ folder branch (branch green when everything is committed, orange otherwise) + uncommitted diff
vcs="${DIM}·${RESET}"   # icon column placeholder outside a git repo
loc="${CYAN}${cwd##*/}${RESET}"
if branch=$(git --no-optional-locks -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null); then
  bc=$GREEN
  [ -n "$(git --no-optional-locks -C "$cwd" status --porcelain 2>/dev/null | head -1)" ] && bc=$ORANGE
  vcs="${ORANGE}⎇${RESET}"
  loc+=" ${bc}${branch}${RESET}"
  stat=$(git --no-optional-locks -C "$cwd" diff --numstat 2>/dev/null \
    | awk '{a+=$1; d+=$2} END {if (a+d) printf "+%d -%d", a, d}')
  [ -n "$stat" ] && loc+=" ${DIM}(${RESET}${GREEN}${stat% *}${RESET} ${RED}${stat#* }${RESET}${DIM})${RESET}"
fi

# ── Effort: session JSON, else env var, else settings.json
if [ -z "$effort" ]; then
  effort=${CLAUDE_CODE_EFFORT_LEVEL:-$(jq -r '.effortLevel // empty' \
    "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/settings.json" 2>/dev/null)}
fi
case "$effort" in
  low)       eff="${DIM}low${RESET}" ;;
  medium)    eff="med" ;;
  high)      eff="${ORANGE}high${RESET}" ;;
  xhigh|max) eff="${RED}${effort}${RESET}" ;;
  *)         eff="$effort" ;;
esac

# ── Context: derive tokens from percentage when current_usage is missing
(( ${used%.*} == 0 && size > 0 )) && used=$(( ${ctx%.*} * size / 100 ))

# ── Model, effort / context / rate limits
head="${ORANGE}✻${RESET} ${model% (*context)}"   # spark + "Opus 5.5 (1M context)" → "Opus 5.5"
[ -n "$eff" ] && head+="${SEP}${eff}"
cx="ctx $(gauge "$ctx")"
(( size > 0 )) && cx+=" ${DIM}$(fmt "$used")/$(fmt "$size")${RESET}"
lim=""
[ -n "$h5" ] && lim="5h $(gauge "$h5")$(timer "$h5r")"
[ -n "$d7" ] && lim+="${lim:+$SEP}7d $(gauge "$d7")$(left "$d7r")"

if [ "$layout" = compact ]; then
  [ -n "$branch" ] && loc="${vcs} ${loc}"
  printf '%s\n' "${head}${SEP}${loc}${SEP}${cx}${lim:+$SEP$lim}"
  exit 0
fi

# ── Clawd, the Claude Code mascot, on the left (padded to the same width)
[ -n "$lim" ] && lim="${ORANGE}◔${RESET} ${lim}"   # plain Unicode, no Nerd Font needed
printf '%s ▐▛███▜▌ %s  %s\n' "$ORANGE" "$RESET" "${head}${SEP}${cx}"
printf '%s▝▜█████▛▘%s  %s\n' "$ORANGE" "$RESET" "${vcs} ${loc}"
printf '%s  ▘▘ ▝▝  %s  %s\n' "$ORANGE" "$RESET" "$lim"
