---
name: wiggum-prd
description: "Create and validate a PRD for Ralph autonomous development. Creates PRD with story-by-story validation, runs 5-persona review, converts to prd.json, sets up git/manifest. Use before running ralph.sh."
---

# Wiggum PRD

Create and validate a PRD for autonomous development with Ralph. Chief Wiggum oversees the whole process!

This skill uses `/prd` under the hood for PRD generation, then adds persona review and project setup.

---

## Overview

This skill guides you through:
1. PRD creation (or review of existing PRD)
2. PRD review by 5 personas (in this context)
3. Human approval of reviewed PRD
4. Conversion to prd.json
5. Documentation scaffolding (if needed)
6. Manifest and git initialization
7. Instructions to run the TDD implementation loop

**After this skill completes, the user exits and runs `ralph.sh prd.json` in a separate terminal.**

---

## Arguments

- If a feature description is provided: Create new PRD
- If `existing` or a file path is provided: Use existing PRD
- If no argument: Ask the user

---

## Phase 1: PRD Creation or Review

### If Creating New PRD

Use the `/prd` skill approach:

1. Ask 3-5 clarifying questions about the feature (with lettered options A, B, C, D for quick answers)
2. Generate a structured PRD with user stories, **test specs, and docs requirements**
3. Save to `tasks/prd-[feature-name].md`

### If Using Existing PRD

1. Read the PRD file(s) in `tasks/prd-*.md`
2. Display a summary of user stories
3. Check for Test Spec and Docs Required fields - flag if missing
4. Ask: "Does this PRD capture what you want? Any changes needed?"

---

## Phase 2: PRD Review (In-Context, 5 Personas)

Run 5 persona reviews IN THIS CONTEXT (not as separate iterations). Each persona reviews and documents concerns.

### Persona 1: DEVELOPER
Review technical feasibility:
- Are stories well-scoped? Can each be completed in one focused session?
- Are there hidden complexities or dependencies?
- Any stories that should be split?
- **Are test specs realistic and achievable?**

### Persona 2: QA_ENGINEER
Review testability:
- Are acceptance criteria specific and verifiable?
- Can you write a test for each criterion?
- Flag vague criteria like "works correctly" or "performs well"
- **Is the test spec comprehensive? Missing edge cases?**
- **Are tests achievable with standard testing frameworks?**

### Persona 3: SECURITY_ENGINEER
Review security implications:
- Auth/authz requirements?
- Data privacy concerns? Input validation needs?
- Potential injection risks? API security?
- **Do test specs include security edge cases (auth bypass, injection)?**

### Persona 4: USER_ADVOCATE
Review from user perspective:
- Does this solve the actual user problem?
- UX concerns? Missing edge cases?
- Would a real user be satisfied?

### Persona 5: DOCUMENTATION_REVIEWER (NEW)
Review documentation completeness:
- Are `Docs Required` fields filled in for each story?
- For stories introducing new patterns: is ARCHITECTURE.md update flagged?
- For API changes: is API.md update flagged?
- Is there an existing ARCHITECTURE.md or docs/ folder? If not, should one be created?
- **Will an AI agent starting fresh understand this codebase after these docs exist?**

### Output Format

Create or update `prd-review.md` with all findings:

```markdown
# PRD Review Feedback

## DEVELOPER Review
[Findings or "No concerns"]
- Technical feasibility: [assessment]
- Story scoping: [assessment]
- Test spec review: [assessment]

## QA_ENGINEER Review
[Findings or "No concerns"]
- Acceptance criteria clarity: [assessment]
- Test spec completeness: [assessment]
- Missing edge cases: [list any]

## SECURITY_ENGINEER Review
[Findings or "No concerns"]
- Security considerations: [assessment]
- Test coverage for security: [assessment]

## USER_ADVOCATE Review
[Findings or "No concerns"]
- User value: [assessment]
- UX concerns: [list any]

## DOCUMENTATION_REVIEWER Review
[Findings or "No concerns"]
- Docs Required accuracy: [assessment]
- Missing documentation: [list any]
- AI context recommendation: [assessment]

---
Summary: [X concerns found / All clear]
```

---

## Phase 3: Human Approval

Present the review findings to the user:

```
## PRD Review Complete

### Concerns Found:
[List any concerns from the 5 personas]

### Recommended Changes:
[Specific suggestions if any]

**Do you want to:**
A. Proceed with current PRD (concerns noted but acceptable)
B. Update the PRD first (I'll help you edit it)
C. Cancel and start over
```

If user chooses B, help them update the PRD, then re-run the relevant persona reviews.

---

## Phase 4: Convert to prd.json

Once PRD is approved, convert to prd.json:

1. Extract all user stories from the PRD
2. **Extract test specs for each story**
3. **Extract docs requirements for each story**
4. Determine dependencies between stories:
   - Database/schema stories → no dependencies
   - API stories → depend on schema
   - UI stories → depend on APIs they consume
   - Integration stories → depend on both
5. Assign priorities (lower number = higher priority)
6. Create `prd.json` in project root

### prd.json Structure

```json
{
  "project": "Project Name",
  "branchName": "feature/kebab-case-name",
  "description": "One-line description",
  "userStories": [
    {
      "id": "US-001",
      "title": "Story title",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": ["criterion 1", "criterion 2"],
      "testSpec": [
        "Test: description of test case 1",
        "Test: description of test case 2",
        "Edge case: edge case description"
      ],
      "docsRequired": "None | ARCHITECTURE.md | API.md | etc.",
      "priority": 1,
      "dependsOn": [],
      "passes": false,
      "notes": ""
    }
  ]
}
```

---

## Phase 5: Documentation Scaffolding (NEW)

### 5a. Check for Existing Documentation

```bash
ls -la ARCHITECTURE.md PATTERNS.md API.md docs/ 2>/dev/null
```

### 5b. Offer Documentation Setup (if needed)

If no documentation exists and feature is non-trivial (5+ stories):

```
## Documentation Setup

This project doesn't have structured documentation yet. For AI-assisted development,
documentation helps each fresh Claude instance understand the codebase quickly.

**Recommended structure:**
- ARCHITECTURE.md - System overview, patterns, module responsibilities
- docs/api.md - API endpoint documentation (if applicable)

**Options:**
A. Create ARCHITECTURE.md scaffold now (recommended for new projects)
B. Skip - I'll document as I go
C. Skip - This project doesn't need it
```

### 5c. Create ARCHITECTURE.md Scaffold (if chosen)

```markdown
# Architecture Overview

## Tech Stack
- [Framework/language - to be filled]
- [Database - to be filled]
- [Key libraries - to be filled]

## Project Structure
```
project/
├── src/           # [describe]
├── tests/         # [describe]
└── ...
```

## Key Patterns
- [Pattern 1]: [description - to be filled]
- [Pattern 2]: [description - to be filled]

## Module Responsibilities
- `[module]` - [responsibility - to be filled]

## Important Files
- `[file:line]` - [what it does - to be filled]

## For AI Agents
When starting a new session, read this file first to understand:
1. The tech stack and project structure
2. Key patterns used in this codebase
3. Where to find important functionality

---
*Last updated: [DATE] during [FEATURE] implementation*
*Update this file when introducing new patterns or architecture changes.*
```

---

## Phase 6: Initialize Project

### 6a. Git Setup

```bash
# If not already a git repo
git init

# Create feature branch
git checkout -b [branchName from prd.json]

# Initial commit if needed
git add .
git commit -m "Initial commit before Ralph implementation"
```

### 6b. Create progress.txt

```markdown
# Ralph Progress Log
Started: [TODAY'S DATE]
Project: [PROJECT NAME]
Branch: [BRANCH NAME]

## Codebase Patterns
[Note any patterns discovered about the codebase - frameworks, conventions, etc.]

## Testing Approach
- Test framework: [jest/vitest/pytest/etc. - to be discovered]
- Test location: [alongside code/__tests__/tests/ - to be discovered]
- Run tests: [npm test/pytest/etc. - to be discovered]

## Documentation
- ARCHITECTURE.md: [exists/created/not needed]
- API docs: [location or N/A]
- Key files to read first: [list]

## TDD Reminders
- Write test FIRST, watch it fail (RED)
- Minimal code to pass (GREEN)
- Refactor only after green
- See /test-driven-development skill for full process

---
```

### 6c. Update Manifest

Add this feature to the ralph-manifest.json:

```bash
# Using the helper script (if ralph-workflow is in PATH):
ralph-manifest-add.sh "[Feature Name]" "prd.json" "[branch-name]" "planned"

# Or manually create/update ralph-manifest.json:
```

The manifest tracks all features across the project:

```json
{
  "project": "Project Name",
  "created": "2026-01-12T00:00:00Z",
  "features": [
    {
      "name": "Feature Name",
      "prdFile": "prd.json",
      "branch": "feature/branch-name",
      "status": "planned",
      "created": "2026-01-12T00:00:00Z",
      "lastUpdated": "2026-01-12T00:00:00Z",
      "notes": "",
      "releases": []
    }
  ]
}
```

**Valid statuses:** planned, prd_review, in_progress, implemented, reviewing, complete, partial_release, blocked, abandoned

### 6d. Ensure Scripts Are Accessible

Check if ralph scripts are in PATH. If not, inform the user:

```
Ralph scripts not found in PATH. Either:

Option A: Add to PATH (recommended):
  export PATH="$PATH:$HOME/Documents/GitHub/ralph-workflow"
  # Add to ~/.zshrc or ~/.bashrc for persistence

Option B: Copy scripts to project:
  cp ~/Documents/GitHub/ralph-workflow/ralph*.sh ./
  chmod +x ralph*.sh
```

---

## Phase 7: Final Instructions

Display to the user:

```
## Ralph Init Complete!

### Summary:
- PRD: tasks/prd-[name].md (reviewed by 5 personas)
- Tasks: prd.json ([X] stories, [Y] with dependencies)
- Test specs: [Z] test cases defined across all stories
- Docs required: [N] stories need documentation updates
- Branch: [branch-name]
- Progress log: progress.txt
- Manifest: ralph-manifest.json (feature added)
- Documentation: [ARCHITECTURE.md created | existing | skipped]

### TDD Implementation:
Ralph will follow test-driven development for each story:
1. Read Test Spec from prd.json
2. Write test FIRST (RED)
3. Watch it fail
4. Write minimal code to pass (GREEN)
5. Refactor if needed
6. Update docs if docsRequired is set

### Next Steps:

1. **Exit this Claude session**

2. **In a new terminal, run:**
   ```bash
   cd [project-path]
   ralph.sh prd.json 50
   ```

3. **Monitor progress** (in another terminal):
   ```bash
   tail -f ralph.log
   watch -n 5 'git log --oneline -10'
   ralph-status.sh  # View all features
   ```

4. **When complete**, run code review:
   ```bash
   /wiggum-review
   ```
   Or for larger projects (20+ stories):
   ```bash
   ralph-code-review.sh prd.json 25
   ```

5. **For partial releases** (if client needs early merge):
   ```bash
   ralph-release.sh prd.json [commit-hash] "Notes about release"
   ```

Good luck!
```

---

## Important Notes

- This entire init process happens in ONE context window
- The accumulated context is valuable - each persona sees what others found
- Only the implementation loop (ralph.sh) needs fresh context per iteration
- If the PRD is large (20+ stories), consider splitting into phases
- The manifest tracks multiple features - useful for projects with several concurrent features
- **Test specs defined now will guide TDD implementation later**
- **Documentation requirements ensure the shadow system gets built**

---

## Example Usage

```bash
# New feature - creates PRD with story-by-story validation
/wiggum-prd "Add user authentication with OAuth"

# Existing PRD - skip to persona review
/wiggum-prd existing

# Specific PRD file
/wiggum-prd tasks/prd-auth-system.md
```

---

## Script Commands Reference

| Command | Purpose |
|---------|---------|
| `ralph.sh <prd.json> [iterations]` | Run TDD implementation loop |
| `ralph-prd-review.sh <prd.md> [iterations]` | Review PRD with 4 personas |
| `ralph-code-review.sh <prd.json> [iterations]` | Review code with 6 personas |
| `ralph-status.sh [manifest]` | Show all feature statuses |
| `ralph-release.sh <prd.json> [commit] [notes]` | Record partial/full release |
| `ralph-manifest-add.sh <name> <prd> <branch> [status]` | Add feature to manifest |
