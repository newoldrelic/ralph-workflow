#!/bin/bash
# ralph-code-review.sh - Code review with rotating personas
# Usage: ./ralph-code-review.sh <prd.json> [max_iterations]
#
# 6 personas rotate to review and improve the code.
# Must pass 2 full cycles (12 iterations) with no issues to complete.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Argument handling
if [ -z "$1" ]; then
    echo -e "${RED}Error: prd.json path required${NC}"
    echo "Usage: ralph-code-review.sh <prd.json> [max_iterations]"
    echo ""
    echo "Examples:"
    echo "  ralph-code-review.sh prd.json 25"
    echo "  ralph-code-review.sh features/auth-prd.json 30"
    exit 1
fi

PRD_FILE="$1"
MAX_ITERATIONS=${2:-25}

# Validate prd.json exists
if [ ! -f "$PRD_FILE" ]; then
    echo -e "${RED}Error: PRD file not found: $PRD_FILE${NC}"
    exit 1
fi

# Get working directory from PRD file location
WORK_DIR="$(cd "$(dirname "$PRD_FILE")" && pwd)"
PRD_BASENAME="$(basename "$PRD_FILE")"
LOG_FILE="$WORK_DIR/ralph-code-review.log"
PROGRESS_FILE="$WORK_DIR/progress.txt"
MANIFEST_FILE="$WORK_DIR/ralph-manifest.json"

# Extract feature info from prd.json
FEATURE_NAME=$(cat "$PRD_FILE" | grep -o '"project"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\([^"]*\)"/\1/' || echo "unknown")

# 6 Code Review Personas - Each references relevant skills for thorough review
PERSONAS=(
    "CODE_REVIEWER|You have access to the /requesting-code-review and /systematic-debugging skills. Use their principles to review code for bugs, edge cases, error handling. Check types are correct. Look for common issues: null checks, async/await errors, race conditions. Fix any issues found."
    "SECURITY_ENGINEER|Review for security vulnerabilities using OWASP top 10 as your guide: injection risks (SQL/XSS/command), broken auth, sensitive data exposure, XXE, broken access control, security misconfiguration, XSS, insecure deserialization, known vulnerabilities, insufficient logging. Check secrets handling - no hardcoded keys/passwords. Fix any issues."
    "SYSTEM_ARCHITECT|Review file structure and dependencies. Check separation of concerns - is business logic mixed with UI? Check module boundaries and import cycles. Look for code duplication that should be abstracted. Ensure consistent patterns across the codebase. Refactor if needed for maintainability."
    "FRONTEND_DESIGNER|You have access to the /frontend-design skill. Use its principles to review UI/UX quality. Check accessibility (a11y): aria labels, keyboard navigation, color contrast, screen reader support. Check responsiveness across breakpoints. Verify component consistency with design system. Improve visual polish."
    "QA_ENGINEER|You have access to the /test-driven-development skill. Use its principles. Run npm test. Check test coverage (aim 90%+). Write missing unit tests for edge cases and error paths. Run npm run lint && npm run build. Ensure all tests are meaningful, not just coverage padding. Fix any failures."
    "PROJECT_MANAGER|You have access to the /verification-before-completion skill. Use its principles. Verify ALL acceptance criteria from $PRD_BASENAME are met - check each one explicitly. Cross-reference the PRD requirements. Document any gaps between spec and implementation. Ensure nothing was missed or partially implemented."
)

echo -e "${CYAN}🔍 Starting Code Review Loop${NC}"
echo "PRD file: $PRD_FILE"
echo "Feature: $FEATURE_NAME"
echo "Max iterations: $MAX_ITERATIONS"
echo "Working directory: $WORK_DIR"
echo "---"

# Update manifest status
update_manifest_status() {
    local status="$1"
    local notes="$2"

    if [ -f "$MANIFEST_FILE" ]; then
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

# Mark as under review
update_manifest_status "reviewing" "Code review started"

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

    OUTPUT=$(cd "$WORK_DIR" && claude --permission-mode acceptEdits -p "@$PRD_BASENAME @progress.txt
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
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        # Update manifest
        update_manifest_status "complete" "Code review passed - ready for merge"

        echo ""
        echo -e "${GREEN}🚦 HUMAN GATE 4: Final approval${NC}"
        echo "  - git diff main...HEAD  # Review all changes"
        echo "  - npm test              # Full test suite"
        echo "  - gh pr create          # Create PR for final review"
        echo ""
        echo "<promise>CODE_REVIEW_COMPLETE</promise>"
        exit 0
    fi

    sleep 2
done

echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}⚠️ Max iterations reached (clean streak: $CLEAN_COUNT/$REQUIRED_CLEAN)${NC}"
echo -e "${YELLOW}Manual review recommended before proceeding.${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Update manifest
update_manifest_status "reviewing" "Max iterations reached - needs manual review"
exit 1
