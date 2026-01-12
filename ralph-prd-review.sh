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

# 4 PRD Review Personas - Thorough requirements review before implementation
PERSONAS=(
    "DEVELOPER|Review technical feasibility with /test-driven-development principles in mind. Are stories well-scoped for one focused session? Hidden complexities or dependencies? Database migrations needed? API contracts clear? External service integrations specified? Flag stories that should be split (>1 day work) or need technical clarification."
    "QA_ENGINEER|Review testability - every acceptance criterion must be testable. Can you write an automated test for each criterion? Flag vague criteria: 'works correctly', 'performs well', 'user-friendly'. Each criterion should specify: input, action, expected output. Check for missing error cases, edge cases, boundary conditions."
    "SECURITY_ENGINEER|Review security with OWASP top 10 in mind. Auth requirements specified? Data classification (PII, sensitive)? Input validation requirements? API security (rate limiting, auth tokens)? Secrets management? GDPR/privacy implications? Flag any story touching user data, auth, or external APIs without security criteria."
    "USER_ADVOCATE|Review from user perspective using /frontend-design principles. Does this solve the REAL user problem or just the stated one? UX flow make sense? Accessibility considered? Error states defined? Loading states? Empty states? Mobile experience? Would a real user find this valuable and usable? Flag missing user-facing requirements."
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
