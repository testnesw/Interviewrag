# DEEP MECHANICS · Agent Evaluation

> 🧠 **Hook:** *Judging a road trip* — not just "did you arrive?" (outcome) but "was the route sane?" (trajectory).
>
> Level 2 — why agents are hard to evaluate, trajectory vs outcome metrics,
> tool-use correctness, and benchmarks.

---

## 0. The precise mental model
Evaluating an agent is harder than evaluating a single LLM call because an agent produces a **multi-step trajectory** (plan → tool calls → observations → more steps → final answer). You must judge **both the outcome** (did it achieve the goal?) **and the process** (did it take good steps, use tools correctly, not loop or waste money?). Non-determinism means you evaluate **distributions of runs**, not one.

---

## 1. Why it's hard
- **Multi-step + branching**: many valid paths to the goal; errors compound across steps.
- **Non-deterministic**: same input → different trajectories → evaluate with repeats.
- **Tool/environment coupling**: outcomes depend on external tools/state → need reproducible test environments.
- A correct final answer can come from a **bad/lucky path** (and vice versa) → outcome alone is insufficient.

## 2. Two axes: outcome vs trajectory
- **Outcome (end-to-end) metrics**: task **success rate** (did it accomplish the goal?), answer correctness, goal completion — the ultimate signal.
- **Trajectory (process) metrics**:
  - **Tool-call accuracy** — right tool, right arguments, right order.
  - **Step efficiency** — steps-to-completion (fewer = better); detect loops.
  - **Reasoning quality** — valid plan, no unnecessary actions.
  - **Cost & latency** — tokens + tool calls + wall time per task.
  - **Recovery** — does it self-correct after a tool error?

## 3. Reference-based trajectory scoring
- **Exact-match trajectory**: compare to a gold sequence of tool calls (brittle — many valid paths).
- **Better**: check **key milestones** were hit (did it call the DB with the right filter? did it get approval before acting?) rather than exact step order.
- **LLM-as-judge** over the trajectory: score plan coherence, tool appropriateness, final quality against a rubric.

## 4. Building agent evals
- **Scenario suite**: representative tasks + **edge/adversarial** cases (ambiguous goals, tool failures, injection attempts), each with success criteria.
- **Reproducible environment**: mocked/sandboxed tools with deterministic responses (or recorded) → isolate the agent from flaky externals.
- **Repeats + pass@k / pass^k**: run each task multiple times → measure **reliability** (pass^k = passes *every* time — reliability is often the real bar for production).
- Grow the suite from **production failures** (traces → new test cases).

## 5. Production monitoring (online)
- Trace every step (see LLM Observability): tool calls, tokens, latency, outcome, human interventions.
- Metrics: success rate, escalation/human-handoff rate, cost per task, loop/timeout rate, guardrail triggers.
- **Human feedback** + review of failed trajectories → feed back into eval set + prompts/tools.

## 6. Benchmarks (name-drop)
- **τ-bench (tau-bench)** (tool-agent-user interaction), **AgentBench**, **WebArena / VisualWebArena** (web tasks), **SWE-bench** (software engineering agents), **GAIA** (general assistants), **ToolBench** (tool use).
- Useful for comparison, but **custom domain evals** matter more for your app.

## 7. The hard follow-ups (with answers)
1. **"Why is agent eval harder than LLM eval?"** → multi-step trajectory + non-determinism + tool coupling; must judge process *and* outcome. (§1)
2. **"Outcome vs trajectory metrics?"** → success rate (goal) vs tool-call accuracy / step efficiency / recovery / cost. (§2)
3. **"Final answer right but path bad — does it pass?"** → outcome alone is insufficient → also score the trajectory (milestones/tool use). (§1/§3)
4. **"How compare to a gold trajectory without brittleness?"** → check **key milestones**, not exact step order; LLM-judge the process. (§3)
5. **"Measure reliability, not luck?"** → repeat runs; **pass^k** (passes every time), not just pass@1. (§4)
6. **"Isolate from flaky tools?"** → **mocked/sandboxed deterministic environment**. (§4)
7. **"Benchmarks?"** → τ-bench, AgentBench, WebArena, SWE-bench, GAIA — but custom domain evals matter more. (§6)
8. **"Monitor agents in prod?"** → trace steps; track success/escalation/cost/loop rates + review failed trajectories. (§5)

## 8. One-screen recall
- Agents = **multi-step, non-deterministic, tool-coupled** → evaluate **outcome AND trajectory**, over **repeated runs**.
- **Outcome**: task **success rate**, correctness, goal completion.
- **Trajectory**: **tool-call accuracy**, step efficiency (loops), reasoning quality, **cost/latency**, error recovery.
- Score process via **milestones** (not exact path) + **LLM-as-judge**; use **pass^k** for reliability.
- **Eval set**: scenarios (+ edge/adversarial) in a **reproducible sandboxed env**; grow from prod failures.
- **Prod**: trace steps, track success/escalation/cost/loop rates, review failures.
- **Benchmarks**: τ-bench, AgentBench, WebArena, SWE-bench, GAIA.

> Next: Multimodal & Vision Models.
