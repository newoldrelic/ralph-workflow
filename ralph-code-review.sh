#!/bin/bash
# ralph-code-review.sh - Code review with rotating personas
# Usage: ./ralph-code-review.sh [max_iterations]
#
# 6 personas rotate to review and improve the code.
# Must pass 2 full cycles (12 iterations) with no issues to complete.

set -e

MAX_ITERATIONS=${1:-25}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/ralph-code-review.log"

# 6 Code Review Personas - Each references relevant skills for thorough review
PERSONAS=(
    "CODE_REVIEWER|You have access to the /requesting-code-review and /systematic-debugging skills. Use their principles to review code for bugs, edge cases, error handling. Check types are correct. Look for common issues: null checks, async/await errors, race conditions. Fix any issues found."
    "SECURITY_ENGINEER|Review for security vulnerabilities using OWASP top 10 as your guide: injection risks (SQL/XSS/command), broken auth, sensitive data exposure, XXE, broken access control, security misconfiguration, XSS, insecure deserialization, known vulnerabilities, insufficient logging. Check secrets handling - no hardcoded keys/passwords. Fix any issues."
    "SYSTEM_ARCHITECT|Review file structure and dependencies. Check separation of concerns - is business logic mixed with UI? Check module boundaries and import cycles. Look for code duplication that should be abstracted. Ensure consistent patterns across the codebase. Refactor if needed for maintainability."
    "FRONTEND_DESIGNER|You have access to the /frontend-design skill. Use its principles to review UI/UX quality. Check accessibility (a11y): aria labels, keyboard navigation, color contrast, screen reader support. Check responsiveness across breakpoints. Verify component consistency with design system. Improve visual polish."
    "QA_ENGINEER|You have access to the /test-driven-development skill. Use its principles. Run npm test. Check test coverage (aim 90%+). Write missing unit tests for edge cases and error paths. Run npm run lint && npm run build. Ensure all tests are meaningful, not just coverage padding. Fix any failures."
    "PROJECT_MANAGER|You have access to the /verification-before-completion skill. Use its principles. Verify ALL acceptance criteria from prd.json are met - check each one explicitly. Cross-reference the PRD requirements. Document any gaps between spec and implementation. Ensure nothing was missed or partially implemented."
)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🔍 Starting Code Review Loop${NC}"
echo "Max iterations: $MAX_ITERATIONS"
echo "---"

# Track consecutive clean iterations
CLEAN_COUNT=0
REQUIRED_CLEAN=12  # 2 full cycles through 6 personas

for i in $(seq 1 $MAX_ITERATIONS); do
    PERSONA_INDEX=$(( (i - 1) % 6 ))
    PERSONA_DATA="${PERSONAS[$PERSONA_INDEX]}"
    PERSONA_NAME="${PERSONA_DATA%%|*}"
    PERSONA_INSTRUCTIONS="${PERSONA_DATA#*|}"

    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}🔁 Iteration $i of $MAX_ITERATIONS - ${CYAN}$PERSONA_NAME${NC}"
    echo -e "${YELLOW}Clean streak: $CLEAN_COUNT/$REQUIRED_CLEAN${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iteration $i - $PERSONA_NAME (clean: $CLEAN_COUNT)" >> "$LOG_FILE"

    OUTPUT=$(cd "$SCRIPT_DIR" && claude --permission-mode acceptEdits -p "@prd.json @progress.txt
You are a $PERSONA_NAME reviewing code after implementation.

YOUR FOCUS: $PERSONA_INSTRUCTIONS

INSTRUCTIONS:
1. Review the codebase from your persona's perspective
2. If you find an issue:
   - Make exactly ONE fix or improvement
   - Commit with message: '[$PERSONA_NAME] description of fix'
   - Output: ISSUES_FOUND
3. If you find NO issues from your perspective:
   - Output: NO_ISSUES

Be thorough but focused. Quality over quantity.

OUTPUT FORMAT (required on last line):
- If you made a fix: ISSUES_FOUND
- If everything looks good: NO_ISSUES" 2>&1 | tee /dev/stderr)

    # Check if this iteration found issues
    if echo "$OUTPUT" | grep -q "NO_ISSUES"; then
        CLEAN_COUNT=$((CLEAN_COUNT + 1))
        echo -e "${GREEN}✓ $PERSONA_NAME found no issues (clean: $CLEAN_COUNT/$REQUIRED_CLEAN)${NC}"
    else
        CLEAN_COUNT=0
        echo -e "${YELLOW}⚡ $PERSONA_NAME made improvements (clean streak reset)${NC}"
    fi

    # Check if we've achieved required clean streak
    if [ $CLEAN_COUNT -ge $REQUIRED_CLEAN ]; then
        echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✅ Code Review complete!${NC}"
        echo -e "${GREEN}All 6 personas passed 2 full cycles with no issues.${NC}"
        echo -e "${GREEN}Proceed to HUMAN GATE 4 for final approval.${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo "<promise>CODE_REVIEW_COMPLETE</promise>"
        exit 0
    fi

    sleep 2
done

echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}⚠️ Max iterations reached (clean streak: $CLEAN_COUNT/$REQUIRED_CLEAN)${NC}"
echo -e "${YELLOW}Manual review recommended before proceeding.${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
exit 1
