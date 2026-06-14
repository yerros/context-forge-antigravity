# context-forge — Antigravity CLI build

The Six-File Context Methodology, packaged as a native **Antigravity CLI (`agy`)** plugin.
This is a separate, Antigravity-specific build of [context-forge](https://github.com/yerros/context-forge);
the original Claude Code plugin is unchanged and lives in its own folder.

What it gives the agent:

- **12 skills** for the full context lifecycle — init, prompt, spec, build, build-all, verify, debug, decision, feature, audit, pr, resume. Antigravity auto-discovers these from `skills/`.
- **3 deterministic, token-free hooks** — load context at session start, guard generated/protected files before edits, and record activity on stop.

## What changed vs. the Claude Code build

| Component | Claude Code | Antigravity CLI build |
| --- | --- | --- |
| Plugin marker | `.claude-plugin/plugin.json` | `plugin.json` at the plugin **root** |
| Skills | `skills/*/SKILL.md` | identical — copied as-is, auto-discovered |
| Hooks file | `hooks/hooks.json` (wrapped in `"hooks": {…}`) | `hooks.json` at root, **named hook groups** |
| Hook events | `SessionStart`, `PreToolUse`, `Stop` | same event names |
| PreToolUse matcher | `Write\|Edit\|MultiEdit` | Antigravity tool names: `write_to_file\|replace_file_content\|multi_replace_file_content\|edit_file\|create_file` |
| Hook output schema | `hookSpecificOutput.permissionDecision` | `{"decision":"allow"\|"deny"\|"ask","reason":…}` |
| Plugin-root variable | `${CLAUDE_PLUGIN_ROOT}` | relative `./hooks/scripts/…` |
| `marketplace.json` | present | dropped (Antigravity installs from git/path) |

The skill markdown is agent-agnostic and was not modified. Because Antigravity reads `AGENTS.md`/`GEMINI.md` natively every session, `context-init`'s `AGENTS.md` output is the primary context-loading path; the SessionStart hook is a backup reminder.

## Install

From a local clone:

```bash
agy plugin validate /path/to/context-forge-antigravity
agy plugin install  /path/to/context-forge-antigravity
agy plugin list
```

Or, once pushed to a repo:

```bash
agy plugin install https://github.com/yerros/context-forge-antigravity.git
```

Installing stages the bundle into `~/.gemini/antigravity-cli/plugins/context-forge/`.

## Verify hooks manually

The hooks are plain shell scripts that read JSON on stdin and print a JSON decision on stdout:

```bash
# should DENY
echo '{"toolCall":{"name":"write_to_file","args":{"TargetFile":"package-lock.json"}}}' \
  | bash hooks/scripts/guard.sh
# -> {"decision":"deny","reason":"context-forge: lock files are generated …"}

# should ALLOW
echo '{"toolCall":{"name":"write_to_file","args":{"TargetFile":"src/app.ts"}}}' \
  | bash hooks/scripts/guard.sh
# -> {"decision":"allow"}
```

## Caveats — please verify against your `agy` version

Antigravity reached 1:1 feature parity is *not* guaranteed, and exact hook contracts evolve. Two things to confirm on your machine:

1. **Path argument key.** `guard.sh` scans the tool-call JSON for the keys `TargetFile`, `AbsolutePath`, `file_path`, `filepath`, `path`, `FilePath`. If your `agy` build names the write-tool path argument something else, add it to the `grep -oE` pattern in `hooks/scripts/guard.sh`.
2. **SessionStart context injection.** `load-context.sh` returns `decision`, `reason`, and `systemMessage`. If your build surfaces injected context under a different field, adjust the final `printf` in `hooks/scripts/load-context.sh`. The guard and track hooks use the well-documented `allow`/`deny` contract and are lower-risk.
3. **Relative script paths.** Commands use `./hooks/scripts/…`. If they don't resolve in your install, replace with the absolute staged path (`~/.gemini/antigravity-cli/plugins/context-forge/hooks/scripts/…`).

## Files

```
context-forge-antigravity/
├── plugin.json              # root marker
├── hooks.json               # named hook groups (SessionStart / PreToolUse / Stop)
├── hooks/scripts/
│   ├── load-context.sh      # SessionStart: surface project state
│   ├── guard.sh             # PreToolUse: block generated/protected files
│   └── track.sh             # Stop: record uncommitted changes
└── skills/                  # 12 skills, auto-discovered
```
