#!/usr/bin/env bash
# PreToolUse hook: enforces the docs-control delegation policy.
# In docs-control itself: everything is allowed (source-of-truth).
# In downstream repos:
#   - main session and non-delegated subagents are blocked from running
#     git commit / git push / gh pr create (must delegate to github-ops).
#   - the f5xc-github-ops:github-ops subagent may run those operations,
#     UNLESS the changeset touches a file listed in governance.json.
# Distributed by docs-control via managed_files sync.
# Exit 0 = allow, Exit 2 = block (stderr shown to Claude).
set -euo pipefail

# ── Guard: exit if no stdin data (e.g., linter running script) ───────
if ! read -t 0 2>/dev/null; then
  exit 0
fi

INPUT=$(cat)

# ── Self-exclusion: allow all git/GitHub operations in docs-control ─
REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
if echo "$REMOTE_URL" | grep -q "docs-control"; then
  exit 0
fi

# ── Extract the Bash command ────────────────────────────────────────
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")
if [ -z "$COMMAND" ]; then
  exit 0
fi

# ── Detect operation type ───────────────────────────────────────────
IS_COMMIT=0
IS_PUSH=0
IS_PR=0
if [[ "$COMMAND" =~ (^|[^A-Za-z0-9_])git[[:space:]]+commit([^A-Za-z0-9_]|$) ]]; then
  IS_COMMIT=1
fi
if [[ "$COMMAND" =~ (^|[^A-Za-z0-9_])git[[:space:]]+push([^A-Za-z0-9_]|$) ]]; then
  IS_PUSH=1
fi
if [[ "$COMMAND" =~ (^|[^A-Za-z0-9_])gh[[:space:]]+pr[[:space:]]+create([^A-Za-z0-9_]|$) ]]; then
  IS_PR=1
fi

# Not a delegated operation — no policy applies
if [ "$IS_COMMIT" = 0 ] && [ "$IS_PUSH" = 0 ] && [ "$IS_PR" = 0 ]; then
  exit 0
fi

# ── Delegation check: only github-ops may run delegated operations ──
AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // empty' 2>/dev/null || echo "")
if [ "$AGENT_TYPE" != "f5xc-github-ops:github-ops" ]; then
  cat >&2 <<EOF
BLOCKED: "${COMMAND}" is a delegated git/GitHub operation.

CLAUDE.md requires all git commit, git push, and gh pr create calls to
go through the f5xc-github-ops:github-ops subagent. Dispatch that agent
with a clear task description instead of running the command directly.
EOF
  exit 2
fi

# ── Content check: governed files cannot leave a downstream repo ────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GOVERNANCE_FILE="${SCRIPT_DIR}/../governance.json"
if [ ! -f "$GOVERNANCE_FILE" ]; then
  exit 0
fi

# Compute the set of file paths this operation would affect
CHANGED=""
if [ "$IS_COMMIT" = 1 ]; then
  # Files staged for this commit
  CHANGED=$(git diff --cached --name-only 2>/dev/null || echo "")
  # -a / --all flag includes modified-but-unstaged tracked files
  if [[ " $COMMAND " =~ [[:space:]]-[a-zA-Z]*a[a-zA-Z]*[[:space:]] ]] ||
    [[ " $COMMAND " =~ [[:space:]]--all[[:space:]] ]]; then
    CHANGED=$(printf '%s\n%s\n' "$CHANGED" "$(git diff --name-only 2>/dev/null || echo "")")
  fi
else
  # push or pr create: files changed between upstream and HEAD
  UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "")
  if [ -z "$UPSTREAM" ]; then
    UPSTREAM=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || echo "origin/main")
  fi
  CHANGED=$(git diff --name-only "${UPSTREAM}..HEAD" 2>/dev/null || echo "")
fi

CHANGED_SORTED=$(printf '%s\n' "$CHANGED" | awk 'NF' | sort -u)
GOVERNED_SORTED=$(jq -r '.protected_files[]' "$GOVERNANCE_FILE" 2>/dev/null | awk 'NF' | sort -u)

if [ -z "$CHANGED_SORTED" ] || [ -z "$GOVERNED_SORTED" ]; then
  exit 0
fi

VIOLATIONS=$(comm -12 <(printf '%s' "$CHANGED_SORTED") <(printf '%s' "$GOVERNED_SORTED"))

if [ -n "$VIOLATIONS" ]; then
  SOURCE_REPO=$(jq -r '.source_repo' "$GOVERNANCE_FILE")
  cat >&2 <<EOF
BLOCKED: "${COMMAND}" would affect governed file(s) managed by ${SOURCE_REPO}:
$(printf '%s\n' "$VIOLATIONS" | sed 's/^/  - /')

Governed files cannot be committed, pushed, or PR-submitted from
downstream repos. To change them, open an issue/PR in ${SOURCE_REPO} —
changes sync automatically to downstream repos.
EOF
  exit 2
fi

exit 0
