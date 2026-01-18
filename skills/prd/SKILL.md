---
name: prd
description: "Generate a Product Requirements Document (PRD) for a new feature. Use when planning a feature, starting a new project, or when asked to create a PRD. Triggers on: create a prd, write prd for, plan this feature, requirements for, spec out."
---

# PRD Generator

Create detailed Product Requirements Documents that are clear, actionable, and suitable for test-driven implementation.

---

## The Job

1. Receive a feature description from the user
2. Ask 3-5 essential clarifying questions (with lettered options)
3. Generate a DRAFT PRD based on answers
4. **Review each user story with the user** (approve, edit, or remove)
5. Save final PRD to `/tasks/prd-[feature-name].md`
6. **Show next steps** (use /wiggum-prd)

**Important:** Do NOT start implementing. Just create the PRD.

---

## Step 1: Clarifying Questions

Ask only critical questions where the initial prompt is ambiguous. Focus on:

- **Problem/Goal:** What problem does this solve?
- **Core Functionality:** What are the key actions?
- **Scope/Boundaries:** What should it NOT do?
- **Success Criteria:** How do we know it's done?
- **Testing Approach:** What kind of tests are needed?
- **Documentation:** Does this introduce new patterns?

### Format Questions Like This:

```
1. What is the primary goal of this feature?
   A. Improve user onboarding experience
   B. Increase user retention
   C. Reduce support burden
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

---

## Step 2: PRD Structure

Generate the PRD with these sections:

### 1. Introduction/Overview
Brief description of the feature and the problem it solves.

### 2. Goals
Specific, measurable objectives (bullet list).

### 3. User Stories

Each story needs:
- **Title:** Short descriptive name
- **Description:** "As a [user], I want [feature] so that [benefit]"
- **Acceptance Criteria:** Verifiable checklist of what "done" means
- **Test Spec:** What tests will prove this story works (TDD-first thinking)
- **Docs Required:** What documentation this story needs (if any)

Each story should be small enough to implement in one focused session.

**Format:**
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

**Important:**
- Acceptance criteria must be verifiable, not vague. "Works correctly" is bad. "Button shows confirmation dialog before deleting" is good.
- **For any story with UI changes:** Always include "Verify in browser using dev-browser skill" as acceptance criteria.
- **Test Spec is mandatory:** Forces TDD thinking at PRD time. If you can't define tests, the requirement isn't clear enough.

### Writing Testable Acceptance Criteria

Every acceptance criterion should be verifiable by an automated test. Apply the "How would I test this?" filter:

| Bad (Vague) | Good (Testable) |
|-------------|-----------------|
| "Works correctly" | "Returns 200 with user object when valid ID provided" |
| "Handles errors" | "Returns 400 with message 'Email required' when email is empty" |
| "Performs well" | "Responds in <200ms for 95th percentile" |
| "Is secure" | "Rejects requests without valid JWT token (401)" |
| "Looks good" | "Button has hover state with 0.2s transition" |

### When to Add Docs Required

Add documentation requirements when the story:

| Scenario | Documentation Needed |
|----------|---------------------|
| Introduces new architecture pattern | Update ARCHITECTURE.md |
| Adds/changes API endpoints | Update API.md |
| Creates new component pattern | Update COMPONENTS.md |
| Makes important design decision | Add ADR in docs/decisions/ |
| Changes deployment/config | Update README.md or DEPLOYMENT.md |
| None of the above | `Docs Required: None` |

### 4. Functional Requirements
Numbered list of specific functionalities:
- "FR-1: The system must allow users to..."
- "FR-2: When a user clicks X, the system must..."

Be explicit and unambiguous.

### 5. Non-Goals (Out of Scope)
What this feature will NOT include. Critical for managing scope.

### 6. Design Considerations (Optional)
- UI/UX requirements
- Link to mockups if available
- Relevant existing components to reuse

### 7. Technical Considerations (Optional)
- Known constraints or dependencies
- Integration points with existing systems
- Performance requirements

### 8. Success Metrics
How will success be measured?
- "Reduce time to complete X by 50%"
- "Increase conversion rate by 10%"

### 9. Open Questions
Remaining questions or areas needing clarification.

---

## Step 3: Story Review (REQUIRED)

Before saving the PRD, you MUST review each user story with the user. This catches scope issues early.

### Process

1. After drafting all stories, present them ONE AT A TIME:

```
### Story Review

**US-001: [Title]**
> As a [user], I want [feature] so that [benefit].

Acceptance Criteria:
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] npm run typecheck passes
- [ ] All tests pass

Test Spec:
- [ ] Test: [test case 1]
- [ ] Test: [test case 2]

Docs Required: [None | specific docs]

**Review Checklist:**
- Acceptance criteria are testable (not vague)?
- Test spec covers happy path + edge cases?
- Documentation identified if needed?

**Options:**
A. Approve this story
B. Edit this story (tell me what to change)
C. Remove this story
D. Split into multiple stories
E. Test spec needs more cases
```

2. Wait for user response before moving to next story
3. If user chooses B, D, or E, make the changes and re-present for approval
4. Continue until all stories are reviewed

### Quick Approval Option

If there are many stories (8+), offer a summary view first:

```
### Story Summary (12 stories)

1. US-001: Add email capture form (2 tests)
2. US-002: Validate email format (3 tests)
3. US-003: Store email in database (2 tests)
...

Total: 12 stories, 24 test cases, 3 require documentation updates

**Options:**
A. Review each story individually
B. Approve all and proceed (I trust you)
C. I want to edit some - show me #[numbers]
```

---

## Step 4: Next Steps (REQUIRED)

After saving the PRD, ALWAYS display:

```
## PRD Created!

Saved to: `/tasks/prd-[feature-name].md`
Stories: [X] user stories
Test cases: [Y] tests defined
Docs required: [Z] stories need documentation updates

### Next Step

Run the init skill to set up for implementation:

    /wiggum-prd existing

This will:
1. Review your PRD with 5 personas (Developer, QA, Security, User Advocate, Documentation)
2. Verify test specs are comprehensive
3. Get your approval on persona feedback
4. Convert to prd.json with dependencies
5. Set up git branch and manifest
6. Give you the command to start TDD implementation

---
**Do NOT start implementing yet.** The init process validates your PRD first.
```

---

## Writing for Junior Developers

The PRD reader may be a junior developer or AI agent. Therefore:

- Be explicit and unambiguous
- Avoid jargon or explain it
- Provide enough detail to understand purpose and core logic
- Number requirements for easy reference
- Use concrete examples where helpful
- **Test specs help AI agents know exactly what to implement**

---

## Output

- **Format:** Markdown (`.md`)
- **Location:** `/tasks/`
- **Filename:** `prd-[feature-name].md` (kebab-case)

---

## Example PRD

```markdown
# PRD: Task Priority System

## Introduction

Add priority levels to tasks so users can focus on what matters most. Tasks can be marked as high, medium, or low priority, with visual indicators and filtering to help users manage their workload effectively.

## Goals

- Allow assigning priority (high/medium/low) to any task
- Provide clear visual differentiation between priority levels
- Enable filtering and sorting by priority
- Default new tasks to medium priority

## User Stories

### US-001: Add priority field to database
**Description:** As a developer, I need to store task priority so it persists across sessions.

**Acceptance Criteria:**
- [ ] Add priority column to tasks table: 'high' | 'medium' | 'low' (default 'medium')
- [ ] Generate and run migration successfully
- [ ] npm run typecheck passes
- [ ] All tests pass

**Test Spec:**
- [ ] Test: New task created without priority defaults to 'medium'
- [ ] Test: Task with priority 'high' persists and retrieves correctly
- [ ] Test: Invalid priority value rejected by schema

**Docs Required:** None (internal schema change)

---

### US-002: Display priority indicator on task cards
**Description:** As a user, I want to see task priority at a glance so I know what needs attention first.

**Acceptance Criteria:**
- [ ] Each task card shows colored priority badge (red=high, yellow=medium, gray=low)
- [ ] Badge includes icon for each level
- [ ] Priority visible without hovering or clicking
- [ ] npm run typecheck passes
- [ ] All tests pass
- [ ] Verify in browser using dev-browser skill

**Test Spec:**
- [ ] Test: TaskCard renders PriorityBadge with correct color for 'high'
- [ ] Test: TaskCard renders PriorityBadge with correct color for 'medium'
- [ ] Test: TaskCard renders PriorityBadge with correct color for 'low'
- [ ] Test: PriorityBadge displays correct icon for each level

**Docs Required:** Update COMPONENTS.md with PriorityBadge component

---

### US-003: Add priority selector to task edit
**Description:** As a user, I want to change a task's priority when editing it.

**Acceptance Criteria:**
- [ ] Priority dropdown in task edit modal
- [ ] Shows current priority as selected
- [ ] Saves immediately on selection change
- [ ] npm run typecheck passes
- [ ] All tests pass
- [ ] Verify in browser using dev-browser skill

**Test Spec:**
- [ ] Test: PrioritySelector shows current priority as selected
- [ ] Test: Selecting new priority calls onPriorityChange handler
- [ ] Test: updateTaskPriority action persists change to database
- [ ] Edge case: Rapid priority changes don't cause race conditions

**Docs Required:** None

---

### US-004: Filter tasks by priority
**Description:** As a user, I want to filter the task list to see only high-priority items when I'm focused.

**Acceptance Criteria:**
- [ ] Filter dropdown with options: All | High | Medium | Low
- [ ] Filter persists in URL params
- [ ] Empty state message when no tasks match filter
- [ ] npm run typecheck passes
- [ ] All tests pass
- [ ] Verify in browser using dev-browser skill

**Test Spec:**
- [ ] Test: Filter dropdown renders with all options
- [ ] Test: Selecting 'High' filters to only high-priority tasks
- [ ] Test: Filter value persists in URL search params
- [ ] Test: Empty state shown when no tasks match filter
- [ ] Edge case: Filter works correctly when combined with search

**Docs Required:** None

## Functional Requirements

- FR-1: Add `priority` field to tasks table ('high' | 'medium' | 'low', default 'medium')
- FR-2: Display colored priority badge on each task card
- FR-3: Include priority selector in task edit modal
- FR-4: Add priority filter dropdown to task list header
- FR-5: Sort by priority within each status column (high -> medium -> low)

## Non-Goals

- No priority-based notifications or reminders
- No automatic priority assignment based on due date
- No priority inheritance for subtasks

## Technical Considerations

- Reuse existing badge component with color variants
- Filter state managed via URL search params
- Priority stored in database, not computed

## Success Metrics

- Users can change priority in <2 clicks
- High-priority tasks immediately visible at top of lists
- No regression in task list performance

## Open Questions

- Should priority affect task ordering within a column?
- Should we add keyboard shortcuts for priority changes?
```

---

## Checklist

Before completing:

- [ ] Asked clarifying questions with lettered options
- [ ] Incorporated user's answers
- [ ] User stories are small and specific
- [ ] **Acceptance criteria are testable (not vague)**
- [ ] **Test spec included for each story**
- [ ] **Docs Required identified for each story**
- [ ] Functional requirements are numbered and unambiguous
- [ ] Non-goals section defines clear boundaries
- [ ] **Reviewed each story with user (or offered quick approval for 8+)**
- [ ] Saved to `/tasks/prd-[feature-name].md`
- [ ] **Showed next steps (/wiggum-prd existing)**
