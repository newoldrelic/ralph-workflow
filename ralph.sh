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

# ============================================================================
# AUTO-TMUX: Restart inside tmux if not already in a session
# ============================================================================
if [ -z "$TMUX" ] && [ -z "$RALPH_NO_TMUX" ]; then
    SESSION_NAME="ralph-$(basename "$(pwd)")"
    echo -e "${CYAN}Starting Ralph in tmux session: $SESSION_NAME${NC}"
    echo -e "${CYAN}To detach: Ctrl+B, then D${NC}"
    echo -e "${CYAN}To reattach: tmux attach -t $SESSION_NAME${NC}"
    echo ""
    sleep 2
    exec tmux new-session -s "$SESSION_NAME" "$0" "$@"
fi

# ============================================================================
# ARGUMENT HANDLING
# ============================================================================
if [ -z "$1" ]; then
    echo -e "${RED}Error: prd.json path required${NC}"
    echo "Usage: ralph.sh <prd.json> [max_iterations]"
    echo ""
    echo "Examples:"
    echo "  ralph.sh prd.json 50"
    echo "  ralph.sh features/auth-prd.json 30"
    echo ""
    echo "Environment variables:"
    echo "  RALPH_NO_TMUX=1  - Don't auto-wrap in tmux"
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
SESSION_LOG="$WORK_DIR/ralph-session-$(date +%Y%m%d-%H%M%S).log"
PROGRESS_FILE="$WORK_DIR/progress.txt"
MANIFEST_FILE="$WORK_DIR/ralph-manifest.json"
STATUS_FILE="$WORK_DIR/ralph-status.txt"

# Extract feature info from prd.json
FEATURE_NAME=$(cat "$PRD_FILE" | grep -o '"project"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)"/\1/' || echo "unknown")
STORY_COUNT=$(cat "$PRD_FILE" | grep -o '"id"[[:space:]]*:' | wc -l | tr -d ' ')

# ============================================================================
# CTRL+C HANDLING: Skip iteration on first, exit on second
# ============================================================================
LAST_INTERRUPT=0

handle_interrupt() {
    local NOW=$(date +%s)
    local DIFF=$((NOW - LAST_INTERRUPT))

    if [ $DIFF -lt 2 ]; then
        echo -e "\n${RED}Double Ctrl+C detected - exiting Ralph${NC}"
        update_manifest_status "in_progress" "Manually stopped"
        exit 130
    else
        echo -e "\n${YELLOW}Ctrl+C - skipping current iteration (press again within 2s to exit)${NC}"
        LAST_INTERRUPT=$NOW
        # Just return - Claude will be killed by the signal, loop continues
    fi
}

trap handle_interrupt INT

# ============================================================================
# STATUS FILE: Quick check on current state
# ============================================================================
update_status() {
    local iteration="$1"
    local story="$2"
    local status="$3"

    cat > "$STATUS_FILE" << EOF
Last updated: $(date '+%Y-%m-%d %H:%M:%S')
Iteration: $iteration of $MAX_ITERATIONS
Current story: $story
Status: $status
Session log: $SESSION_LOG
EOF
}

# ============================================================================
# STARTUP
# ============================================================================
echo -e "${YELLOW}🔁 Starting Ralph Loop${NC}"
echo "PRD file: $PRD_FILE"
echo "Feature: $FEATURE_NAME"
echo "Stories: $STORY_COUNT"
echo "Max iterations: $MAX_ITERATIONS"
echo "Working directory: $WORK_DIR"
echo "Log file: $LOG_FILE"
echo "Session log: $SESSION_LOG"
echo "---"
echo ""
echo -e "${CYAN}Full output will be displayed below and logged to: $SESSION_LOG${NC}"
echo ""

# Initialize progress.txt if not exists
if [ ! -f "$PROGRESS_FILE" ]; then
    cat > "$PROGRESS_FILE" << EOF
# Ralph Progress Log
Started: $(date '+%Y-%m-%d')
Project: $FEATURE_NAME

## Codebase Patterns
(Patterns discovered during implementation)

## Testing Approach
- Test framework: (to be discovered)
- Test location: (to be discovered)
- Run tests: (to be discovered)

## Documentation
- ARCHITECTURE.md: (exists/created/not needed)
- Key files to read first: (to be filled)

## TDD Reminders
- Write test FIRST, watch it fail (RED)
- Minimal code to pass (GREEN)
- Refactor only after green
- Check testSpec in prd.json for each story

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

# ============================================================================
# HELPER: Show story status
# ============================================================================
show_story_status() {
    local prd="$1"

    # Count stories
    local complete=$(grep -c '"passes": true' "$prd" 2>/dev/null || echo "0")
    local total=$(grep -c '"id":' "$prd" 2>/dev/null || echo "0")

    echo -e "${CYAN}Progress: $complete/$total stories complete${NC}"

    # Show next available stories (passes=false and dependencies met)
    echo -e "${CYAN}Available stories:${NC}"

    # Use node for proper JSON parsing
    node -e "
    const fs = require('fs');
    const prd = JSON.parse(fs.readFileSync('$prd', 'utf8'));
    const complete = new Set(prd.userStories.filter(s => s.passes).map(s => s.id));
    const available = prd.userStories.filter(s =>
        !s.passes &&
        (s.dependsOn || []).every(dep => complete.has(dep))
    ).sort((a, b) => a.priority - b.priority);

    if (available.length === 0) {
        console.log('  (none - check dependencies)');
    } else {
        available.slice(0, 3).forEach(s => {
            console.log('  → ' + s.id + ': ' + s.title + ' (priority ' + s.priority + ')');
        });
        if (available.length > 3) {
            console.log('  ... and ' + (available.length - 3) + ' more');
        }
    }
    " 2>/dev/null || echo "  (could not parse prd.json)"
}

# ============================================================================
# MAIN LOOP
# ============================================================================
for i in $(seq 1 $MAX_ITERATIONS); do
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🔁 Iteration $i of $MAX_ITERATIONS${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    # Show what's available
    show_story_status "$WORK_DIR/$PRD_BASENAME"
    echo ""

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $i started" >> "$LOG_FILE"

    # Update status file
    update_status "$i" "Starting..." "Finding next story"

    # Run Claude with fresh context
    # @prd.json and @progress.txt are inlined by Claude CLI
    # --permission-mode bypassPermissions allows ALL operations without prompts
    cd "$WORK_DIR"

    # Run Claude with --output-format text for readable streaming output
    # tee captures to log while showing on terminal
    claude --permission-mode bypassPermissions --output-format text -p "@$PRD_BASENAME @progress.txt
You are implementing features defined in $PRD_BASENAME using TDD. This is iteration $i.

FIRST: Announce which story you're working on by outputting:
>>> WORKING ON: [Story ID] - [Story Title]

INSTRUCTIONS:
1. Find the highest-priority incomplete feature to work on. Look for stories where passes=false and all dependsOn stories have passes=true.
2. Implement ONLY that single feature. Do not work on multiple features.

TDD IMPLEMENTATION (MANDATORY):
For the selected story, follow test-driven development:
a. READ the testSpec array from the story in $PRD_BASENAME
b. For EACH test in testSpec:
   - Write the test FIRST
   - Run the test - verify it FAILS (RED)
   - Write minimal code to make it pass
   - Run the test - verify it PASSES (GREEN)
   - Refactor if needed (stay GREEN)
c. If testSpec is empty or missing, define tests based on acceptanceCriteria before implementing.

THE IRON LAW: No production code without a failing test first.
If you write code before the test: delete it and start over with the test.

DOCUMENTATION:
- Check the docsRequired field for the story
- If not 'None', update the specified documentation file BEFORE marking the story complete
- Documentation is an acceptance criterion - the story fails without it

VERIFICATION:
3. Run 'npm run typecheck' and all tests.
4. Verify all tests from testSpec are written and passing.
5. Verify docsRequired documentation is updated (if applicable).

COMPLETION:
6. Update $PRD_BASENAME: set the story's passes to true, add notes about what you learned.
7. Append your progress to progress.txt with: date, story ID, tests written, files changed.
8. Make a git commit for this feature.

END CONDITIONS:
- If ALL stories have passes=true, output: <promise>COMPLETE</promise>
- If you're blocked after 5 attempts on the same story, output: <promise>BLOCKED</promise>
- Otherwise, just complete the single feature and exit normally.

ONLY WORK ON A SINGLE FEATURE PER ITERATION." 2>&1 | tee -a "$SESSION_LOG"

    EXIT_CODE=${PIPESTATUS[0]}

    # Read last part of session log to check for promises
    RECENT_OUTPUT=$(tail -100 "$SESSION_LOG")

    # Check for completion promise
    if echo "$RECENT_OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
        echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✅ Ralph completed successfully!${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] COMPLETE after $i iterations" >> "$LOG_FILE"

        # Update manifest and status
        update_manifest_status "implemented" "Completed in $i iterations"
        update_status "$i" "ALL COMPLETE" "Finished"

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
    if echo "$RECENT_OUTPUT" | grep -q "<promise>BLOCKED</promise>"; then
        echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}🚫 Ralph is blocked - human intervention needed${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] BLOCKED after $i iterations" >> "$LOG_FILE"

        # Update manifest and status
        update_manifest_status "blocked" "Blocked after $i iterations"
        update_status "$i" "BLOCKED" "Needs human help"
        exit 1
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $i completed, continuing..." >> "$LOG_FILE"
    update_status "$i" "Completed" "Moving to next iteration"

    # Brief pause between iterations
    sleep 2
done

echo -e "\n${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${RED}⚠️  Max iterations ($MAX_ITERATIONS) reached${NC}"
echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Max iterations reached" >> "$LOG_FILE"

# Update manifest and status
update_manifest_status "in_progress" "Max iterations reached, may need continuation"
update_status "$MAX_ITERATIONS" "Max reached" "May need more iterations"
exit 1
