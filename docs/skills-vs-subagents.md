# Skills vs Subagents vs ralph.sh

A quick reference for when to use each approach in the Ralph Workflow.

## The Three Approaches

| Approach | Context | Orchestration | Best For |
|----------|---------|---------------|----------|
| **Skills** | Main conversation | Claude in-session | Accumulated context (persona reviews) |
| **Subagents** | Isolated per-agent | Claude parent session | Parallel research, tool restrictions |
| **ralph.sh** | Fresh per-iteration | Bash script (external) | Unattended execution, 50+ iterations |

## Skills

Prompts injected into the main conversation context.

**Use when:** You want accumulated context - each step sees what came before.

**Example:** PRD review with 5 personas. Each persona sees what others found, building on their insights.

```
Persona 1 finds issue → Persona 2 sees it and finds related issue → ...
```

## Subagents

Isolated context windows spawned by a parent Claude session.

**Use when:** You need isolation, tool restrictions, or parallel work - but the parent session can stay alive.

**Limitations:** Parent session accumulates subagent results. Over 50+ iterations, parent hits context limits.

```
[Parent Claude] → spawns subagent → result returns to parent → parent context grows
```

**Good for:**
- Codebase exploration (isolate verbose output)
- Parallel research tasks
- Tool-restricted operations (read-only DB queries)

## ralph.sh (Bash Loop)

External bash script spawns fresh Claude instances.

**Use when:** You need truly unattended execution with zero context accumulation.

```
[Bash script] → spawns Claude → exits → spawns Claude → exits → ...
```

**Advantages:**
- No parent session needed
- Runs overnight, survives disconnects (tmux)
- Zero accumulation - iteration 50 is as fresh as iteration 1
- Simple and predictable

**This is why ralph.sh exists** - subagents can't do unattended 50+ iteration loops without the parent accumulating context.

## Summary

| Need | Use |
|------|-----|
| Personas building on each other's findings | Skills |
| Isolated research without polluting main context | Subagents |
| Parallel independent tasks | Subagents |
| Unattended multi-hour execution | ralph.sh |
| 50+ iterations with fresh context each time | ralph.sh |

## In the Ralph Workflow

- **PLAN phase** (`/wiggum-prd`): Skills - personas need accumulated context
- **BUILD phase** (`ralph.sh`): Bash loop - fresh context per iteration, unattended
- **REVIEW phase** (`/wiggum-review`): Skills - personas need accumulated context
