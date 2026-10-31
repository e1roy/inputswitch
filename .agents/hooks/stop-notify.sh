#!/bin/bash

INPUT=$(cat)
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')

# 防止无限循环
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

osascript -e 'display notification "Claude 已完成回复" with title "Claude Code" sound name "Glass"'

exit 0
