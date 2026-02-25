#!/usr/bin/env bash
set -euo pipefail

cleanup() {
  exit 0
}
trap cleanup EXIT

if ! command -v jq &>/dev/null; then
  exit 0
fi

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
if [ -z "$SESSION_ID" ]; then
  exit 0
fi

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
export CWD

source "$(dirname "$0")/lib-stage.sh"

cleanup_stage "$SESSION_ID"
