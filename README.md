# claude-statusline

A compact status line for [Claude Code](https://docs.claude.com/en/docs/claude-code/statusline).

```
Opus │ my-project@main (+12 -3) │ ctx ████░░░░░░  42% 84k/200k │ high │ 5h ███░░░░░░░  31% (2h14) │ 7d █████████░  85% (2d07h)
```

It shows, from left to right:

- **Model** in use
- **Folder @ git branch**, with uncommitted line changes
- **Context window** usage, as a bar and in tokens
- **Effort level**
- **5-hour and 7-day rate limits**, with the time left until each one resets

Bars turn red at 80%.

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
2. Adds the `statusLine` entry to `~/.claude/settings.json`, keeping your other settings. The previous file is saved as `settings.json.bak`.

If `settings.json` is not valid JSON, the installer stops without changing it.

Run the same command again to update.

### Options

| Variable              | Default                                                            | Purpose                           |
| --------------------- | ------------------------------------------------------------------ | --------------------------------- |
| `CLAUDE_CONFIG_DIR`   | `~/.claude`                                                        | Claude Code config directory      |
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
    "command": "~/.claude/statusline.sh"
  }
}
```

## Uninstall

```bash
rm ~/.claude/statusline.sh
jq 'del(.statusLine)' ~/.claude/settings.json > /tmp/settings.json && mv /tmp/settings.json ~/.claude/settings.json
```
