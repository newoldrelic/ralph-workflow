---
name: wiggum-review
description: "In-context code review with 6 personas after Ralph implementation. For smaller projects (<20 stories). Fixes issues and verifies acceptance criteria."
---

# Wiggum Review

In-context code review after Ralph implementation completes. Chief Wiggum runs 6 personas to polish the code.

---

## When to Use

- **Use this skill** for smaller projects (< 20 stories) where accumulated context is valuable
- **Use `ralph-code-review.sh prd.json`** for larger projects where fresh context per iteration is needed

---

## Arguments

- If a prd.json path is provided: Use that file for acceptance criteria verification
- If no argument: Look for `prd.json` in current directory

Example:
```bash
/wiggum-review
/wiggum-review prd.json
/wiggum-review features/auth-prd.json
```

---

## Overview

This skill runs 6 persona reviews IN THIS CONTEXT:
1. Each persona reviews the codebase
2. Makes one fix/improvement at a time
3. Continues until all personas find no issues for 2 rounds

---

## The 6 Personas

### 1. CODE_REVIEWER
Use principles from `/requesting-code-review` and `/systematic-debugging` skills.

**Focus:**
- Bugs, edge cases, error handling
- Type correctness
- Null checks, async/await errors, race conditions
- Code clarity and readability

### 2. SECURITY_ENGINEER
Use OWASP Top 10 as your guide.

**Focus:**
- Injection risks (SQL, XSS, command)
- Broken authentication/authorization
- Sensitive data exposure
- Security misconfiguration
- Secrets handling (no hardcoded keys)
- Input validation at boundaries

### 3. SYSTEM_ARCHITECT
**Focus:**
- File structure and dependencies
- Separation of concerns
- Module boundaries and import cycles
- Code duplication that should be abstracted
- Consistent patterns across codebase

### 4. FRONTEND_DESIGNER
Use principles from `/frontend-design` skill.

**Focus:**
- Accessibility (a11y): aria labels, keyboard nav, color contrast
- Responsiveness across breakpoints
- Component consistency with design system
- Visual polish and UX quality

### 5. QA_ENGINEER
Use principles from `/test-driven-development` skill.

**Focus:**
- Run `npm test`
- Test coverage (aim for 90%+)
- Missing unit tests for edge cases
- Run `npm run lint && npm run build`
- Meaningful tests, not just coverage padding

### 6. PROJECT_MANAGER
Use principles from `/verification-before-completion` skill.

**Focus:**
- Verify ALL acceptance criteria from prd.json
- Cross-reference each criterion explicitly
- Document any gaps between spec and implementation
- Ensure nothing was missed or partially implemented

---

## Process

### Step 1: Initial Assessment
Read `prd.json` (or specified file) and `progress.txt` to understand what was built.

### Step 2: Run Each Persona
For each persona in order:
1. Review from that persona's perspective
2. If issues found:
   - Make exactly ONE fix
   - Commit with message: `[PERSONA_NAME] description of fix`
   - Note the fix
3. If no issues: Note "No issues found"

### Step 3: Track Clean Rounds
- Each persona must pass with "No issues" for 2 consecutive rounds
- If any persona finds an issue, the count resets
- This ensures convergence to quality

### Step 4: Update Manifest
When review is complete, update ralph-manifest.json:
- Set feature status to "complete"
- Add notes about the review

### Step 5: Complete
When all 6 personas pass 2 rounds (12 consecutive clean checks):

```
## Wiggum Review Complete! ✅

All 6 personas passed 2 consecutive rounds with no issues.

### Summary of Fixes Made:
[List all fixes made during review]

### Ready for HUMAN GATE 4:
- Review the git diff: git diff main...HEAD
- Run full test suite: npm test
- Create PR: gh pr create

### To record this release:
ralph-release.sh prd.json
```

---

## Example Flow

```
🔍 Starting Wiggum Review

PRD file: prd.json
Stories: 12

[Round 1]
CODE_REVIEWER: Found null check missing in userService.ts
  → Fixed, committed: [CODE_REVIEWER] Add null check for user.email

SECURITY_ENGINEER: Found hardcoded API key in config.ts
  → Fixed, committed: [SECURITY_ENGINEER] Move API key to env variable

SYSTEM_ARCHITECT: No issues found ✓

FRONTEND_DESIGNER: Missing aria-label on icon button
  → Fixed, committed: [FRONTEND_DESIGNER] Add aria-label to settings button

QA_ENGINEER: Test coverage at 75%, missing edge case tests
  → Fixed, committed: [QA_ENGINEER] Add tests for error handling in auth flow

PROJECT_MANAGER: AC for US-003 not fully met (missing loading state)
  → Fixed, committed: [PROJECT_MANAGER] Add loading state to meal plan page

[Round 2]
CODE_REVIEWER: No issues found ✓
SECURITY_ENGINEER: No issues found ✓
... (continue until 2 clean rounds)
```

---

## Usage

```bash
/wiggum-review
/wiggum-review prd.json
/wiggum-review features/my-feature-prd.json
```

The prd.json file is used by the PROJECT_MANAGER persona to verify acceptance criteria.
