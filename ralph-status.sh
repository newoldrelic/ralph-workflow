#!/bin/bash
# ralph-status.sh - Quick check on Ralph's progress
# Usage: ./ralph-status.sh [project-dir]

WORK_DIR="${1:-.}"
STATUS_FILE="$WORK_DIR/ralph-status.txt"
PRD_FILE="$WORK_DIR/prd.json"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Ralph Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Show status file if exists
if [ -f "$STATUS_FILE" ]; then
    cat "$STATUS_FILE"
else
    echo "No active Ralph session found"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Story Progress"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -f "$PRD_FILE" ]; then
    TOTAL=$(grep -c '"id":' "$PRD_FILE" 2>/dev/null || echo "0")
    COMPLETE=$(grep -c '"passes": true' "$PRD_FILE" 2>/dev/null || echo "0")
    echo "Complete: $COMPLETE / $TOTAL stories"
    echo ""
    echo "Completed:"
    grep -B5 '"passes": true' "$PRD_FILE" | grep '"title"' | sed 's/.*"title": "\([^"]*\)".*/  ✅ \1/' || echo "  (none yet)"
    echo ""
    echo "Remaining:"
    grep -B5 '"passes": false' "$PRD_FILE" | grep '"title"' | sed 's/.*"title": "\([^"]*\)".*/  ⬜ \1/' | head -10
else
    echo "No prd.json found in $WORK_DIR"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Recent Commits"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd "$WORK_DIR" && git log --oneline -5 2>/dev/null || echo "Not a git repo"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔗 Tmux Session"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
tmux list-sessions 2>/dev/null | grep ralph || echo "No Ralph tmux session found"
echo ""
echo "To reattach: tmux attach -t <session-name>"
