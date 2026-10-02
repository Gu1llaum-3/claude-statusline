# claude-statusline

A compact status line for [Claude Code](https://docs.claude.com/en/docs/claude-code/statusline).

```
 ▐▛███▜▌   ✻ Opus 5.5 │ high │ ctx ▋▋▋▋▋▋▋▋▋▋ 42% 420k/1M
▝▜█████▛▘  ⎇ my-project main (+12 -3)
  ▘▘ ▝▝    ◔ 5h ▋▋▋▋▋▋▋▋▋▋ 31% (2h14) │ 7d ▋▋▋▋▋▋▋▋▋▋ 85% (2d07h)
```

Or, with the `compact` layout, on one line:

```
✻ Opus 5.5 │ high │ ⎇ my-project main (+12 -3) │ ctx ▋▋▋▋▋▋▋▋▋▋ 42% 420k/1M │ 5h ▋▋▋▋▋▋▋▋▋▋ 31% (2h14) │ 7d ▋▋▋▋▋▋▋▋▋▋ 85% (2d07h)
```

Next to Clawd, the Claude Code mascot, the `full` layout shows three lines:

1. **Model** in use, behind the Claude spark, **effort level** and **context window** usage, as a gauge and in tokens
2. **⎇ Folder and git branch**: green when everything is committed, orange otherwise, with uncommitted line changes
3. **◔ 5-hour and 7-day rate limits**, with the time left until each one resets; in the last 15 minutes before the 5-hour reset, a ↻ respawn countdown

Gauges turn red at 80%.

## Requirements

- `bash`, `curl`, `jq`
- `git` (optional, for the branch and diff)

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/Gu1llaum-3/claude-statusline/main/install.sh | bash
```

Then restart Claude Code.

The installer:

1. Downloads `statusline.sh` to `~/.claude/statusline.sh` and makes it executable.
2. Shows a preview of both layouts and asks which one you want. On an update, Enter keeps your current layout.
3. Adds the `statusLine` entry to `~/.claude/settings.json`, keeping your other settings. The previous file is saved as `settings.json.bak`.

If `settings.json` is not valid JSON, the installer stops without changing it.

Run the same command again to update.

From a clone, `./install.sh` installs the `statusline.sh` next to it instead of downloading it.

### Options

| Variable              | Default                                                            | Purpose                           |
| --------------------- | ------------------------------------------------------------------ | --------------------------------- |
| `CLAUDE_CONFIG_DIR`   | `~/.claude`                                                        | Claude Code config directory      |
| `STATUSLINE_LAYOUT`   | asked, or `full` without a terminal                                | `full` or `compact`, skips the question |
| `STATUSLINE_REPO_RAW` | `https://raw.githubusercontent.com/Gu1llaum-3/claude-statusline/main` | Where to download the script from |

```bash
curl -fsSL https://raw.githubusercontent.com/Gu1llaum-3/claude-statusline/main/install.sh | CLAUDE_CONFIG_DIR=~/.claude-work bash
```

## Manual install

Copy `statusline.sh` to `~/.claude/statusline.sh`, run `chmod +x` on it, and add this to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh full"
  }
}
```

Replace `full` with `compact` for the one-line layout.

## Uninstall

```bash
rm ~/.claude/statusline.sh
jq 'del(.statusLine)' ~/.claude/settings.json > /tmp/settings.json && mv /tmp/settings.json ~/.claude/settings.json
```
