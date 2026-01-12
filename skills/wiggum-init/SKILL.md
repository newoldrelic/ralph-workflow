---
name: wiggum-init
description: "Initialize a feature for Ralph autonomous development. Creates PRD, runs 4-persona review, converts to prd.json, sets up git/manifest. Use before running ralph.sh."
---

# Wiggum Init

Initialize a new feature for autonomous development with Ralph. Chief Wiggum oversees the whole process!

---

## Overview

This skill guides you through:
1. PRD creation (or review of existing PRD)
2. PRD review by 4 personas (in this context)
3. Human approval of reviewed PRD
4. Conversion to prd.json
5. Manifest and git initialization
6. Instructions to run the implementation loop

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
2. Generate a structured PRD with user stories
3. Save to `tasks/prd-[feature-name].md`

### If Using Existing PRD

1. Read the PRD file(s) in `tasks/prd-*.md`
2. Display a summary of user stories
3. Ask: "Does this PRD capture what you want? Any changes needed?"

---

## Phase 2: PRD Review (In-Context)

Run 4 persona reviews IN THIS CONTEXT (not as separate iterations). Each persona reviews and documents concerns.

### Persona 1: DEVELOPER
Review technical feasibility:
- Are stories well-scoped? Can each be completed in one focused session?
- Are there hidden complexities or dependencies?
- Any stories that should be split?

### Persona 2: QA_ENGINEER
Review testability:
- Are acceptance criteria specific and verifiable?
- Can you write a test for each criterion?
- Flag vague criteria like "works correctly" or "performs well"

### Persona 3: SECURITY_ENGINEER
Review security implications:
- Auth/authz requirements?
- Data privacy concerns? Input validation needs?
- Potential injection risks? API security?

### Persona 4: USER_ADVOCATE
Review from user perspective:
- Does this solve the actual user problem?
- UX concerns? Missing edge cases?
- Would a real user be satisfied?

### Output Format

Create or update `prd-review.md` with all findings:

```markdown
# PRD Review Feedback

## DEVELOPER Review
[Findings or "No concerns"]

## QA_ENGINEER Review
[Findings or "No concerns"]

## SECURITY_ENGINEER Review
[Findings or "No concerns"]

## USER_ADVOCATE Review
[Findings or "No concerns"]

---
Summary: [X concerns found / All clear]
```

---

## Phase 3: Human Approval

Present the review findings to the user:

```
## PRD Review Complete

### Concerns Found:
[List any concerns from the 4 personas]

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
2. Determine dependencies between stories:
   - Database/schema stories → no dependencies
   - API stories → depend on schema
   - UI stories → depend on APIs they consume
   - Integration stories → depend on both
3. Assign priorities (lower number = higher priority)
4. Create `prd.json` in project root

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
      "priority": 1,
      "dependsOn": [],
      "passes": false,
      "notes": ""
    }
  ]
}
```

---

## Phase 5: Initialize Project

### 5a. Git Setup

```bash
# If not already a git repo
git init

# Create feature branch
git checkout -b [branchName from prd.json]

# Initial commit if needed
git add .
git commit -m "Initial commit before Ralph implementation"
```

### 5b. Create progress.txt

```markdown
# Ralph Progress Log
Started: [TODAY'S DATE]
Project: [PROJECT NAME]
Branch: [BRANCH NAME]

## Codebase Patterns
[Note any patterns discovered about the codebase - frameworks, conventions, etc.]

---
```

### 5c. Update Manifest

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

### 5d. Ensure Scripts Are Accessible

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

## Phase 6: Final Instructions

Display to the user:

```
## Ralph Init Complete! ✅

### Summary:
- PRD: tasks/prd-[name].md (reviewed by 4 personas)
- Tasks: prd.json ([X] stories, [Y] with dependencies)
- Branch: [branch-name]
- Progress log: progress.txt
- Manifest: ralph-manifest.json (feature added)

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

Good luck! 🚀
```

---

## Important Notes

- This entire init process happens in ONE context window
- The accumulated context is valuable - each persona sees what others found
- Only the implementation loop (ralph.sh) needs fresh context per iteration
- If the PRD is large (20+ stories), consider splitting into phases
- The manifest tracks multiple features - useful for projects with several concurrent features

---

## Example Usage

```bash
# New feature
/wiggum-init "Add user authentication with OAuth"

# Existing PRD
/wiggum-init existing

# Specific PRD file
/wiggum-init tasks/prd-auth-system.md
```

---

## Script Commands Reference

| Command | Purpose |
|---------|---------|
| `ralph.sh <prd.json> [iterations]` | Run implementation loop |
| `ralph-prd-review.sh <prd.md> [iterations]` | Review PRD with 4 personas |
| `ralph-code-review.sh <prd.json> [iterations]` | Review code with 6 personas |
| `ralph-status.sh [manifest]` | Show all feature statuses |
| `ralph-release.sh <prd.json> [commit] [notes]` | Record partial/full release |
| `ralph-manifest-add.sh <name> <prd> <branch> [status]` | Add feature to manifest |
