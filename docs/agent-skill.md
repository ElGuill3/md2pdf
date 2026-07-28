# Install the md2pdf agent skill

Install one repository-owned skill for each supported agent you actually use. The installer creates symlinks, so every agent reads the same canonical files and repository updates take effect immediately.

## Quick Install

From the repository root:

```sh
./install-skill.sh --all-detected
```

The command detects only these supported CLIs:

| Agent | Executable | Destination |
|---|---|---|
| Codex | `codex` | `${CODEX_HOME:-$HOME/.codex}/skills/md2pdf` |
| OpenCode | `opencode` | `${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills/md2pdf` |
| Claude Code | `claude` | `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/md2pdf` |
| Gemini CLI | `gemini` | `${GEMINI_CLI_HOME:-$HOME/.gemini}/skills/md2pdf` |

No agent configuration file is changed. The installer does not use `sudo`.

## Choose Agents

Install for one or more agents explicitly when detection is not appropriate:

```sh
./install-skill.sh --agent codex --agent claude
```

Use `--home` to test or install beneath another user-controlled root. It overrides the agent-specific home variables for that invocation:

```sh
./install-skill.sh --home /tmp/md2pdf-skill-home --agent opencode
```

## Update And Verify

The installed directories are absolute symlinks to `skills/md2pdf`. Pulling or editing this checkout updates every installation immediately. If the checkout moves, rerun installation from its new location after uninstalling the old managed links.

Reinstallation is safe and idempotent:

```sh
./install-skill.sh --all-detected
./tests/skill-installer.sh
```

Inspect a destination with `readlink`, then compare through the link:

```sh
readlink "$HOME/.codex/skills/md2pdf"
cmp skills/md2pdf/SKILL.md "$HOME/.codex/skills/md2pdf/SKILL.md"
```

## Collision Behavior

The installer never replaces a file, directory, or symlink it does not manage. A managed destination is only an exact symlink to this checkout's canonical `skills/md2pdf` directory. Remove or relocate a conflicting installation yourself after reviewing it, then rerun the command.

## Uninstall

Remove managed links for detected agents:

```sh
./install-skill.sh --all-detected --uninstall
```

You can also select agents with `--agent`. Uninstall refuses to remove a changed or unmanaged destination and never removes the canonical repository skill.

## Manual Installation

Create the parent directory and link the canonical skill directory. For example:

```sh
mkdir -p "$HOME/.claude/skills"
ln -s "$(pwd -P)/skills/md2pdf" "$HOME/.claude/skills/md2pdf"
```

Symlinks avoid copy drift but depend on this checkout remaining available. If you deliberately choose a copy instead, replace the full copy whenever the repository skill changes and verify all files with `cmp`.
