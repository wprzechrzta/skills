#!/usr/bin/env bash

set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
extractor="$repo_dir/skills/engineering/agent-self-improvement/scripts/extract-user-turns.py"
root=$(mktemp -d "${TMPDIR:-/tmp}/self-improvement-test.XXXXXX")
trap 'rm -rf "$root"' EXIT

project="$root/-Users-someone-repo"
mkdir -p "$project"

cat > "$project/session.jsonl" <<'EOF'
{"type":"user","sessionId":"s1","timestamp":"2026-09-10T10:00:00.000Z","cwd":"/repo","message":{"role":"user","content":[{"type":"text","text":"keep this one"}]}}
{"type":"assistant","sessionId":"s1","timestamp":"2026-09-10T10:00:05.000Z","message":{"role":"assistant","content":[{"type":"text","text":"prior assistant turn"}]}}
{"type":"user","sessionId":"s1","timestamp":"2026-09-10T10:01:00.000Z","isMeta":true,"message":{"role":"user","content":[{"type":"text","text":"meta turn"}]}}
{"type":"user","sessionId":"s1","timestamp":"2026-09-10T10:02:00.000Z","isSidechain":true,"message":{"role":"user","content":[{"type":"text","text":"sidechain turn"}]}}
{"type":"user","sessionId":"s1","timestamp":"2026-09-10T10:03:00.000Z","message":{"role":"user","content":[{"type":"text","text":"<command-name>/exit</command-name>"}]}}
{"type":"user","sessionId":"s1","timestamp":"2026-09-10T10:04:00.000Z","message":{"role":"user","content":[{"type":"tool_result","content":"tool output"}]}}
{"type":"user","sessionId":"s1","timestamp":"2026-09-10T10:05:00.000Z","message":{"role":"user","content":[{"type":"text","text":"<system-reminder>injected</system-reminder>"},{"type":"text","text":"typed alongside a reminder"}]}}
{"type":"user","sessionId":"s1","timestamp":"2026-09-10T10:06:00.000Z","message":{"role":"user","content":[{"type":"text","text":"Another Claude session sent a message:\n<teammate-message teammate_id=\"fix-thing\">done</teammate-message>"}]}}
{"type":"user","sessionId":"s1","timestamp":"2026-09-01T10:07:00.000Z","message":{"role":"user","content":[{"type":"text","text":"before the window"}]}}
{"type":"queue-operation","operation":"remove","timestamp":"2026-09-10T10:08:00.000Z","sessionId":"s1","content":"typed mid-turn","reason":"absorbed_mid_turn"}
{"type":"queue-operation","operation":"remove","timestamp":"2026-09-10T10:09:00.000Z","sessionId":"s1","content":"<task-notification>\n<task-id>x</task-id>","reason":"absorbed_mid_turn"}
EOF

stale="$root/-Users-someone-old"
mkdir -p "$stale"
cp "$project/session.jsonl" "$stale/session.jsonl"
touch -t 202601010000 "$stale/session.jsonl"

output=$(python3 "$extractor" --since 2026-09-05 --until 2026-09-11 --root "$root" 2>/dev/null)

lines=$(printf '%s\n' "$output" | grep -c . || true)
if [ "$lines" -ne 3 ]; then
  echo "expected 3 authored turns, got $lines" >&2
  printf '%s\n' "$output" >&2
  exit 1
fi

case "$output" in
  *'"keep this one"'*) ;;
  *) echo "authored turn missing from output" >&2; exit 1 ;;
esac

case "$output" in
  *injected*) echo "injected block survived alongside typed text" >&2; exit 1 ;;
esac

case "$output" in
  *'typed alongside a reminder'*) ;;
  *) echo "typed text dropped when an injected block shared the message" >&2; exit 1 ;;
esac

case "$output" in
  *'"text": "typed mid-turn", "mid_turn": true'*) ;;
  *) echo "message typed mid-turn missing or not flagged" >&2; exit 1 ;;
esac

second=$(python3 "$extractor" --since 2026-09-10 --until 2026-09-11 --root "$root" --context 5 2>/dev/null)
case "$second" in
  *'"preceding_assistant": ""'*) ;;
  *) echo "expected empty preceding assistant before the first assistant turn" >&2; exit 1 ;;
esac

summary=$(python3 "$extractor" --since 2026-09-05 --until 2026-09-11 --root "$root" 2>&1 >/dev/null)
case "$summary" in
  *"3 turns from 1 sessions"*) ;;
  *) echo "summary did not skip the stale session directory: $summary" >&2; exit 1 ;;
esac
