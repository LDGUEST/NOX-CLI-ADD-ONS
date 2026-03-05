#!/bin/bash
# destructive-guard.sh — PreToolUse hook for Bash
# Blocks commands that are hard to reverse: rm -rf, git reset --hard,
# force push, DROP TABLE, docker system prune, git checkout .
#
# Install: Add to PreToolUse hooks with matcher "Bash"
# Config:  Set NOX_ALLOW_DESTRUCTIVE=1 to disable (not recommended)

[[ "$NOX_ALLOW_DESTRUCTIVE" == "1" ]] && exit 0

INPUT=$(cat)
TOOL=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name',''))" 2>/dev/null)

[[ "$TOOL" != "Bash" ]] && exit 0

CMD=$(echo "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null)
[[ -z "$CMD" ]] && exit 0

# rm -rf with broad targets (/, ~, .., /*, *)
if echo "$CMD" | grep -qE 'rm\s+(-[a-zA-Z]*r[a-zA-Z]*f|--force\s+--recursive|-[a-zA-Z]*f[a-zA-Z]*r)\s+(/|~|\.\.|\.\/\*|\*|\/[a-z]+$)'; then
    echo "BLOCKED: Destructive rm detected. Use targeted rm on specific files instead."
    exit 2
fi

# git reset --hard
if echo "$CMD" | grep -qE 'git\s+reset\s+--hard'; then
    echo "BLOCKED: git reset --hard discards all uncommitted changes permanently. Consider: git stash (reversible)"
    exit 2
fi

# git push --force to main/master
if echo "$CMD" | grep -qE 'git\s+push\s+.*(-f|--force)' && echo "$CMD" | grep -qE '\s(main|master)\b'; then
    echo "BLOCKED: Force push to main/master destroys shared history. Use --force-with-lease or push to a feature branch."
    exit 2
fi

# git clean -f
if echo "$CMD" | grep -qE 'git\s+clean\s+-[a-zA-Z]*f'; then
    echo "BLOCKED: git clean -f permanently deletes untracked files. Use git clean -n (dry run) first."
    exit 2
fi

# git checkout . / git restore . (discard all changes)
if echo "$CMD" | grep -qE 'git\s+(checkout|restore)\s+\.\s*$'; then
    echo "BLOCKED: This discards ALL uncommitted changes. Target specific files or git stash first."
    exit 2
fi

# DROP TABLE / DROP DATABASE / TRUNCATE
if echo "$CMD" | grep -qiE '(DROP\s+TABLE|DROP\s+DATABASE|TRUNCATE\s+TABLE)'; then
    echo "BLOCKED: Destructive database operation. Create a migration instead."
    exit 2
fi

# docker system prune
if echo "$CMD" | grep -qE 'docker\s+system\s+prune'; then
    echo "BLOCKED: docker system prune removes all unused containers, images, and volumes. Target specific resources."
    exit 2
fi

# pkill/killall -9 on broad process names
if echo "$CMD" | grep -qE '(pkill|killall)\s+-9\s+(node|python|docker|postgres)'; then
    echo "BLOCKED: Force-killing all processes of this type is dangerous. Target the specific PID instead."
    exit 2
fi

exit 0
