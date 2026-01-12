#!/bin/bash
# ralph.sh - Autonomous development loop with fresh context per iteration
# Usage: ./ralph.sh <prd.json> [max_iterations]
#
# Key insight: Each iteration gets FULL project context via @file syntax.
# Claude reads prd.json and progress.txt inline, making intelligent decisions
# about which feature to tackle next.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Argument handling
if [ -z "$1" ]; then
    echo -e "${RED}Error: prd.json path required${NC}"
    echo "Usage: ralph.sh <prd.json> [max_iterations]"
    echo ""
    echo "Examples:"
    echo "  ralph.sh prd.json 50"
    echo "  ralph.sh features/auth-prd.json 30"
    exit 1
fi

PRD_FILE="$1"
MAX_ITERATIONS=${2:-50}

# Validate prd.json exists
if [ ! -f "$PRD_FILE" ]; then
    echo -e "${RED}Error: PRD file not found: $PRD_FILE${NC}"
    exit 1
fi

# Get working directory from PRD file location
WORK_DIR="$(cd "$(dirname "$PRD_FILE")" && pwd)"
PRD_BASENAME="$(basename "$PRD_FILE")"
LOG_FILE="$WORK_DIR/ralph.log"
PROGRESS_FILE="$WORK_DIR/progress.txt"
MANIFEST_FILE="$WORK_DIR/ralph-manifest.json"

# Extract feature info from prd.json
FEATURE_NAME=$(cat "$PRD_FILE" | grep -o '"project"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)"/\1/' || echo "unknown")
STORY_COUNT=$(cat "$PRD_FILE" | grep -o '"id"[[:space:]]*:' | wc -l | tr -d ' ')

echo -e "${YELLOW}🔁 Starting Ralph Loop${NC}"
echo "PRD file: $PRD_FILE"
echo "Feature: $FEATURE_NAME"
echo "Stories: $STORY_COUNT"
echo "Max iterations: $MAX_ITERATIONS"
echo "Working directory: $WORK_DIR"
echo "Log file: $LOG_FILE"
echo "---"

# Initialize progress.txt if not exists
if [ ! -f "$PROGRESS_FILE" ]; then
    cat > "$PROGRESS_FILE" << EOF
# Ralph Progress Log
Started: $(date '+%Y-%m-%d')
Project: $FEATURE_NAME

## Codebase Patterns
(Patterns discovered during implementation)

---
EOF
    echo -e "${CYAN}Created progress.txt${NC}"
fi

# Update manifest - set feature to in_progress
update_manifest_status() {
    local status="$1"
    local notes="$2"

    if [ -f "$MANIFEST_FILE" ]; then
        # Use node for reliable JSON manipulation
        node -e "
        const fs = require('fs');
        const manifest = JSON.parse(fs.readFileSync('$MANIFEST_FILE', 'utf8'));
        const feature = manifest.features.find(f => f.prdFile === '$PRD_BASENAME');
        if (feature) {
            feature.status = '$status';
            feature.lastUpdated = new Date().toISOString();
            if ('$notes') feature.notes = '$notes';
        }
        fs.writeFileSync('$MANIFEST_FILE', JSON.stringify(manifest, null, 2));
        " 2>/dev/null || true
    fi
}

# Suggest review type based on story count
suggest_review_type() {
    if [ "$STORY_COUNT" -lt 20 ]; then
        echo -e "${CYAN}📋 Recommended: Use /ralph-review (in-context)${NC}"
        echo -e "${CYAN}   Reason: $STORY_COUNT stories - accumulated context is valuable${NC}"
    else
        echo -e "${CYAN}📋 Recommended: Use ./ralph-code-review.sh $PRD_FILE${NC}"
        echo -e "${CYAN}   Reason: $STORY_COUNT stories - fresh context prevents overflow${NC}"
    fi
}

# Mark as in_progress
update_manifest_status "in_progress" "Started implementation"

for i in $(seq 1 $MAX_ITERATIONS); do
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🔁 Iteration $i of $MAX_ITERATIONS${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $i started" >> "$LOG_FILE"

    # Run Claude with fresh context
    # @prd.json and @progress.txt are inlined by Claude CLI
    # --permission-mode acceptEdits allows file modifications without prompts
    OUTPUT=$(cd "$WORK_DIR" && claude --permission-mode acceptEdits -p "@$PRD_BASENAME @progress.txt
You are implementing features defined in $PRD_BASENAME. This is iteration $i.

INSTRUCTIONS:
1. Find the highest-priority incomplete feature to work on. Look for stories where passes=false and all dependsOn stories have passes=true. Use your judgment on what makes sense to tackle next.
2. Implement ONLY that single feature. Do not work on multiple features.
3. Verify your work: run 'npm run typecheck' and any relevant tests.
4. Update $PRD_BASENAME: set the story's passes to true, add notes about what you learned.
5. Append your progress to progress.txt with: date, story ID, what was done, files changed.
6. Make a git commit for this feature.

COMPLETION:
- If ALL stories have passes=true, output: <promise>COMPLETE</promise>
- If you're blocked after 5 attempts on the same story, output: <promise>BLOCKED</promise>
- Otherwise, just complete the single feature and exit normally.

ONLY WORK ON A SINGLE FEATURE PER ITERATION." 2>&1 | tee /dev/stderr)

    # Check for completion promise
    if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
        echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✅ Ralph completed successfully!${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] COMPLETE after $i iterations" >> "$LOG_FILE"

        # Update manifest
        update_manifest_status "implemented" "Completed in $i iterations"

        # Suggest review type
        echo ""
        echo -e "${GREEN}🚦 HUMAN GATE 3: Quick sanity check${NC}"
        echo "  - npm run dev  # Does it run?"
        echo "  - git log --oneline -10  # Do commits make sense?"
        echo ""
        suggest_review_type
        exit 0
    fi

    # Check for blocked promise
    if echo "$OUTPUT" | grep -q "<promise>BLOCKED</promise>"; then
        echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}🚫 Ralph is blocked - human intervention needed${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] BLOCKED after $i iterations" >> "$LOG_FILE"

        # Update manifest
        update_manifest_status "blocked" "Blocked after $i iterations"
        exit 1
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $i completed, continuing..." >> "$LOG_FILE"

    # Brief pause between iterations
    sleep 2
done

echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}⚠️  Max iterations ($MAX_ITERATIONS) reached${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Max iterations reached" >> "$LOG_FILE"

# Update manifest
update_manifest_status "in_progress" "Max iterations reached, may need continuation"
exit 1
