#!/usr/bin/env bash
# PreToolUse guard for Antigravity CLI (agy) — deterministic, zero model tokens.
# Reads the tool-call JSON on stdin, extracts the target file path from toolCall.args,
# and DENIES edits to generated/lock/vendor files or any glob listed in
# context/protected-paths. Allows everything else. Never calls a model.
#
# Antigravity hook contract:
#   stdin  : JSON payload, e.g. { "toolCall": { "name": ..., "args": { ... } }, ... }
#   stdout : { "decision": "allow" | "deny" | "ask", "reason": "<text>" }

set -u
input=$(cat)

# Antigravity tools name the path argument differently across versions
# (TargetFile / AbsolutePath / file_path / path / filepath). Grab the first
# path-looking string value among those keys. Safe on multi-line JSON.
fp=$(printf '%s' "$input" \
  | grep -oE '"(TargetFile|AbsolutePath|file_path|filepath|path|FilePath)"[[:space:]]*:[[:space:]]*"[^"]*"' \
  | head -1 \
  | sed -E 's/^"[^"]*"[[:space:]]*:[[:space:]]*"(.*)"$/\1/')

allow() {
  printf '{"decision":"allow"}\n'
  exit 0
}

deny() {
  # Fixed, pre-escaped reason string -> always valid JSON.
  printf '{"decision":"deny","reason":"%s"}\n' "$1"
  exit 0
}

# Not a path-bearing tool (e.g. no file path) -> allow.
[ -z "$fp" ] && allow

# Built-in never-hand-edit patterns (essentially zero false-positive risk).
case "$fp" in
  node_modules/*|*/node_modules/*|.git/*|*/.git/*)
    deny "context-forge: this path is inside a vendor/.git directory and should not be edited by hand." ;;
  *.lock|*-lock.json|*-lock.yaml|package-lock.json|pnpm-lock.yaml|yarn.lock|Cargo.lock|poetry.lock|composer.lock)
    deny "context-forge: lock files are generated and should not be hand-edited; change the manifest and re-resolve instead." ;;
esac

# User-configured protected globs: one glob per line in context/protected-paths
# (lines starting with # are comments). Matches against the path or its basename.
if [ -f context/protected-paths ]; then
  base=${fp##*/}
  while IFS= read -r pat || [ -n "$pat" ]; do
    [ -z "$pat" ] && continue
    case "$pat" in \#*) continue ;; esac
    # shellcheck disable=SC2254
    case "$fp" in $pat) deny "context-forge: this file matches a protected path in context/protected-paths." ;; esac
    # shellcheck disable=SC2254
    case "$base" in $pat) deny "context-forge: this file matches a protected path in context/protected-paths." ;; esac
  done < context/protected-paths
fi

allow
