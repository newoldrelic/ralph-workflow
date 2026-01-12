#!/bin/bash
# ralph-prd-review.sh - PRD review with rotating personas
# Usage: ./ralph-prd-review.sh [max_iterations]
#
# Personas rotate to review PRD from different perspectives.
# Concerns are documented in prd-review.md for human review.

set -e

MAX_ITERATIONS=${1:-12}  # 2 full cycles through 4 personas
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/ralph-prd-review.log"

# 4 PRD Review Personas
PERSONAS=(
    "DEVELOPER|Review technical feasibility. Are stories well-scoped? Are there hidden complexities? Can each be completed in one focused session? Flag any that need splitting or clarification."
    "QA_ENGINEER|Review testability. Are acceptance criteria specific and verifiable? Can you write a test for each criterion? Flag vague criteria like 'works correctly' or 'performs well'."
    "SECURITY_ENGINEER|Review security implications. Are there auth/authz requirements? Data privacy concerns? Input validation needs? Potential injection risks? Flag any security gaps."
    "USER_ADVOCATE|Review from user perspective. Does this solve the actual problem? Are there UX concerns? Missing edge cases? Would a real user be satisfied with this scope?"
)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}📋 Starting PRD Review Loop${NC}"
echo "Max iterations: $MAX_ITERATIONS"
echo "---"

# Initialize review file if not exists
if [ ! -f "$SCRIPT_DIR/prd-review.md" ]; then
    cat > "$SCRIPT_DIR/prd-review.md" << 'EOF'
# PRD Review Feedback

This file contains feedback from rotating persona reviews.
Human should review this before proceeding to implementation.

---

EOF
fi

for i in $(seq 1 $MAX_ITERATIONS); do
    PERSONA_INDEX=$(( (i - 1) % 4 ))
    PERSONA_DATA="${PERSONAS[$PERSONA_INDEX]}"
    PERSONA_NAME="${PERSONA_DATA%%|*}"
    PERSONA_INSTRUCTIONS="${PERSONA_DATA#*|}"

    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🔁 Iteration $i of $MAX_ITERATIONS - ${CYAN}$PERSONA_NAME${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $i - $PERSONA_NAME" >> "$LOG_FILE"

    OUTPUT=$(cd "$SCRIPT_DIR" && claude --permission-mode acceptEdits -p "@tasks/prd-*.md @prd-review.md
You are a $PERSONA_NAME reviewing this PRD before implementation begins.

YOUR FOCUS: $PERSONA_INSTRUCTIONS

INSTRUCTIONS:
1. Read the PRD carefully from your persona's perspective
2. Read prd-review.md to see what other personas have already flagged
3. If you find NEW concerns not already documented:
   - Append them to prd-review.md under a '## $PERSONA_NAME Review' section
   - Be specific: reference story IDs, quote problematic text
   - Suggest improvements where possible
4. If all your concerns are already addressed or you have none, note 'No new concerns' in your section

DO NOT:
- Ask interactive questions (document concerns instead)
- Modify the PRD itself (only add to prd-review.md)
- Repeat concerns already documented by other personas

COMPLETION:
- If prd-review.md shows 'No new concerns' from ALL 4 personas in the last full cycle, output: <promise>PRD_REVIEW_COMPLETE</promise>
- Otherwise, complete your review and exit normally." 2>&1 | tee /dev/stderr)

    if echo "$OUTPUT" | grep -q "<promise>PRD_REVIEW_COMPLETE</promise>"; then
        echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✅ PRD Review complete - all personas satisfied${NC}"
        echo -e "${GREEN}Review prd-review.md and proceed to HUMAN GATE 2${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        exit 0
    fi

    sleep 2
done

echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📋 PRD Review iterations complete${NC}"
echo -e "${YELLOW}Review prd-review.md and proceed to HUMAN GATE 2${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
exit 0
