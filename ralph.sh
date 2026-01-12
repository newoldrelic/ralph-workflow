#!/bin/bash
# ralph.sh - Autonomous development loop with fresh context per iteration
# Usage: ./ralph.sh [max_iterations]
#
# Key insight: Each iteration gets FULL project context via @file syntax.
# Claude reads prd.json and progress.txt inline, making intelligent decisions
# about which feature to tackle next.

set -e

MAX_ITERATIONS=${1:-50}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/ralph.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔁 Starting Ralph Loop${NC}"
echo "Max iterations: $MAX_ITERATIONS"
echo "Working directory: $SCRIPT_DIR"
echo "Log file: $LOG_FILE"
echo "---"

for i in $(seq 1 $MAX_ITERATIONS); do
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🔁 Iteration $i of $MAX_ITERATIONS${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $i started" >> "$LOG_FILE"

    # Run Claude with fresh context
    # @prd.json and @progress.txt are inlined by Claude CLI
    # --permission-mode acceptEdits allows file modifications without prompts
    OUTPUT=$(cd "$SCRIPT_DIR" && claude --permission-mode acceptEdits -p "@prd.json @progress.txt
You are implementing features defined in prd.json. This is iteration $i.

INSTRUCTIONS:
1. Find the highest-priority incomplete feature to work on. Look for stories where passes=false and all dependsOn stories have passes=true. Use your judgment on what makes sense to tackle next.
2. Implement ONLY that single feature. Do not work on multiple features.
3. Verify your work: run 'npm run typecheck' and any relevant tests.
4. Update prd.json: set the story's passes to true, add notes about what you learned.
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
        exit 0
    fi

    # Check for blocked promise
    if echo "$OUTPUT" | grep -q "<promise>BLOCKED</promise>"; then
        echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}🚫 Ralph is blocked - human intervention needed${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] BLOCKED after $i iterations" >> "$LOG_FILE"
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
exit 1
