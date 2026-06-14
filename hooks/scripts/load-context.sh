#!/usr/bin/env bash
# SessionStart hook for Antigravity CLI (agy) — deterministic, zero model tokens.
# If the project uses the Six-File Context Methodology, surface the current
# project state so the agent loads context before doing any work.
#
# NOTE: Antigravity natively reads AGENTS.md / GEMINI.md every session, so the
# primary context-loading path is the AGENTS.md that `context-init` generates.
# This hook is a belt-and-suspenders reminder. It emits the Antigravity hook
# response shape ({"decision":"allow", ...}); if your `agy` version surfaces a
# different field for injected context, adjust the key below (see README).

set -u

[ -f context/progress-tracker.md ] || { printf '{"decision":"allow"}\n'; exit 0; }

msg=$(
  printf '[Six-File Context] This project uses the Six-File Context Methodology. '
  printf 'Before implementing or making any architectural decision, read the entry point '
  printf '(AGENTS.md or CLAUDE.md) and the files in context/ in order. Honor the invariants '
  printf 'in context/architecture.md and the rules in context/ai-workflow-rules.md. '
  printf 'Current project state from context/progress-tracker.md:\n\n'
  cat context/progress-tracker.md
)

# JSON-escape the message (\, ", newlines, tabs, CR).
esc=$(printf '%s' "$msg" \
  | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' \
  | awk 'BEGIN{ORS="\\n"}{print}')

printf '{"decision":"allow","reason":"%s","systemMessage":"%s"}\n' "$esc" "$esc"
exit 0
