---
name: wiggum-prd
description: "Create and validate a PRD for Ralph autonomous development. Creates PRD with story-by-story validation, runs 5-persona review, converts to prd.json, sets up git/manifest. Use before running ralph.sh."
---

# Wiggum PRD

Create and validate a PRD for autonomous development with Ralph. Chief Wiggum oversees the whole process!

---

## CRITICAL: CREATE PRD, DO NOT IMPLEMENT

**STOP. READ THIS FIRST.**

This skill creates a PRD (Product Requirements Document). It does NOT implement anything.

**You MUST NOT:**
- Make any code changes
- Use Edit or Write tools on source files
- Implement the feature yourself

**You MAY:**
- Search/read the codebase to understand context
- Read existing files to inform the PRD
- This helps write better, more informed PRDs

**You MUST:**
1. Ask clarifying questions FIRST (even for "simple" requests)
2. Generate a PRD document with user stories
3. Review each story with the user
4. Run 5-persona review
5. Create prd.json
6. Tell user to run `ralph.sh` for implementation

**Even simple requests need PRDs.** A request like "update pricing to £249" still needs:
- A PRD (even if just 1-2 stories)
- Story-by-story review
- 5-persona review
- prd.json for tracking

This ensures proper review, testing, and documentation.

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

#### Step 1a: Clarifying Questions

Ask 3-5 essential clarifying questions with lettered options:

```
1. What is the primary goal of this feature?
   A. [Option based on context]
   B. [Option]
   C. [Option]
   D. Other: [please specify]

2. Who is the target user?
   A. New users only
   B. Existing users only
   C. All users
   D. Admin users only

3. What is the scope?
   A. Minimal viable version
   B. Full-featured implementation
   C. Just the backend/API
   D. Just the UI

4. Does this feature introduce new patterns or architecture?
   A. Yes - new backend pattern (needs ARCHITECTURE.md update)
   B. Yes - new frontend pattern (needs COMPONENTS.md update)
   C. Yes - new API endpoints (needs API.md update)
   D. No - follows existing patterns

5. What's the testing approach?
   A. Unit tests for business logic
   B. Integration tests for API endpoints
   C. E2E tests for user flows
   D. All of the above
```

This lets users respond with "1A, 2C, 3D, 4D, 5A" for quick iteration.

#### Step 1b: Generate PRD with Stories

Each story needs:
- **Title:** Short descriptive name
- **Description:** "As a [user], I want [feature] so that [benefit]"
- **Acceptance Criteria:** Verifiable checklist (not vague)
- **Test Spec:** What tests will prove this works (TDD-first)
- **Docs Required:** What documentation this story needs

**Story Format:**
```markdown
### US-001: [Title]
**Description:** As a [user], I want [feature] so that [benefit].

**Acceptance Criteria:**
- [ ] Specific verifiable criterion
- [ ] Another criterion
- [ ] npm run typecheck passes
- [ ] All tests pass (see Test Spec)
- [ ] **[UI stories only]** Verify in browser using dev-browser skill

**Test Spec:**
- [ ] Test: [describe what test should verify]
- [ ] Test: [another test case]
- [ ] Edge case: [edge case to test]

**Docs Required:** [None | Update ARCHITECTURE.md | Add to API.md | etc.]
```

**Writing Testable Acceptance Criteria:**

| Bad (Vague) | Good (Testable) |
|-------------|-----------------|
| "Works correctly" | "Returns 200 with user object when valid ID provided" |
| "Handles errors" | "Returns 400 with message 'Email required' when email is empty" |
| "Performs well" | "Responds in <200ms for 95th percentile" |
| "Is secure" | "Rejects requests without valid JWT token (401)" |

**When to Add Docs Required:**

| Scenario | Documentation Needed |
|----------|---------------------|
| Introduces new architecture pattern | Update ARCHITECTURE.md |
| Adds/changes API endpoints | Update API.md |
| Creates new component pattern | Update COMPONENTS.md |
| Makes important design decision | Add ADR in docs/decisions/ |
| None of the above | `Docs Required: None` |

#### Step 1c: Story-by-Story Review (REQUIRED)

Present each story ONE AT A TIME for user validation.

**Use the AskUserQuestion tool** for interactive selection (arrow keys UI, not plain text options).

For each story, first display the story details:

```
### Story Review: US-001

**[Title]**
> As a [user]
> I want [feature]
> So that [benefit]

**Acceptance Criteria:**
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] npm run typecheck passes
- [ ] All tests pass

**Test Spec:**
- [ ] Test: [test case 1]
- [ ] Test: [test case 2]

**Docs Required:** [None | specific docs]
```

Then use the **AskUserQuestion tool** with these options:
- "Approve this story"
- "Edit this story"
- "Remove this story"
- "Split into multiple stories"

The tool provides an interactive UI where users can use arrow keys to select, or type custom input via "Other".

Wait for user response before moving to next story.

**Quick Approval Option (for 8+ stories):**

For larger PRDs, first show a summary:

```
### Story Summary (12 stories)

1. US-001: Add email capture form (2 tests)
2. US-002: Validate email format (3 tests)
3. US-003: Store email in database (2 tests)
...

Total: 12 stories, 24 test cases, 3 require documentation updates
```

Then use **AskUserQuestion tool** with options:
- "Review each story individually"
- "Approve all and proceed"
- "Edit specific stories (I'll tell you which)"

#### Step 1d: Save PRD

Save to `tasks/prd-[feature-name].md`

### If Using Existing PRD

1. Read the PRD file(s) in `tasks/prd-*.md`
2. Display a summary of user stories with test spec and docs counts
3. Check for Test Spec and Docs Required fields - flag if missing
4. Ask: "Does this PRD capture what you want? Any changes needed?"
5. If changes needed, go through story-by-story review for affected stories

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
```

Then use **AskUserQuestion tool** with options:
- "Proceed with current PRD (concerns noted)"
- "Update the PRD first"
- "Cancel and start over"

If user chooses to update, help them edit the PRD, then re-run the relevant persona reviews.

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
