# DEEP MECHANICS · Multi-Agent Architecture

> Level 2 — orchestration topologies, how agents communicate, when multi-agent
> beats a single agent, and the failure modes (loops, cost blow-up, error
> propagation).

---

## 0. The precise mental model
A multi-agent system splits a problem across **multiple specialized agents** (each = an LLM + role + tools + memory) that **collaborate** via messages. The bet: **decomposition + specialization** beats one over-loaded agent, the same way microservices split a monolith. The cost: **coordination complexity, more tokens/latency, and compounding errors**. Use it only when a single agent with tools genuinely can't cope.

---

## 1. Why multi-agent (and the trade-off)
- **Specialization** — a Researcher, a Coder, a Reviewer each with focused prompts/tools outperform one generalist prompt.
- **Separation of concerns** — smaller prompts, easier to test/improve each agent.
- **Parallelism** — independent subtasks run concurrently.
- **Cost:** every hop is more LLM calls → **latency + $ multiply**, and one agent's error **propagates** downstream. Default to a single agent + tools first.

## 2. Orchestration topologies
- **Sequential (pipeline)** — agent A → B → C. Simple, predictable (e.g., research → draft → review).
- **Supervisor / orchestrator-worker** — a **manager agent** decomposes the task, routes subtasks to workers, aggregates results. Most common controllable pattern.
- **Hierarchical** — supervisors of supervisors for large tasks.
- **Group chat / collaborative** — agents converse in a shared thread until consensus (AutoGen style). Powerful but can loop.
- **Network/peer** — any agent talks to any agent. Most flexible, hardest to control.

```
Supervisor pattern:
      ┌──────────── Supervisor ────────────┐
      ▼             ▼              ▼
  Researcher      Coder        Reviewer
      └────── results back to Supervisor ──→ final
```

## 3. How agents communicate
- **Shared message history / blackboard** — agents read/write a common conversation state.
- **Structured hand-off** — one agent passes a typed result + task to the next.
- **Tool/function boundaries** — an "agent" can be exposed as a tool another agent calls.
Frameworks: **AutoGen** (conversational multi-agent), **LangGraph** (graph/state-machine), **Semantic Kernel Agent Framework**, **CrewAI**.

## 4. Control mechanisms (to stop chaos)
- **Max turns / step budget** — hard cap to prevent infinite loops.
- **Termination conditions** — explicit "done" signal / a judge agent.
- **Roles & allowed tools per agent** — least privilege.
- **A deterministic orchestrator** where possible (code routes, LLM decides within a step) beats fully free-form chat.

## 5. Failure modes (interviewers probe these)
- **Infinite loops / ping-pong** — agents never converge → step budget + termination.
- **Error propagation** — a bad intermediate result poisons the chain → add a **reviewer/validator** agent, structured checks.
- **Cost/latency explosion** — N agents × M turns of LLM calls → monitor token cost; prefer fewer agents.
- **Context loss** — shared history overflows the window → summarize/route only relevant context.

## 6. Single vs multi-agent — when to escalate
Single agent + tools handles most tasks. Go multi-agent when: distinct expertise/tools per subtask, long workflows benefiting from separation, or parallelizable independent subtasks — **and** you can afford the coordination cost.

## 7. The hard follow-ups (with answers)
1. **"Why multi-agent over one agent?"** → specialization + separation + parallelism; but more cost/latency/error-propagation. (§1)
2. **"Common topologies?"** → sequential, **supervisor/orchestrator-worker**, hierarchical, group chat, network. (§2)
3. **"Stop agents looping forever?"** → step/turn budget + explicit termination + judge agent. (§4,5)
4. **"How do agents share state?"** → shared history/blackboard or structured hand-offs; agents-as-tools. (§3)
5. **"Biggest risks?"** → loops, error propagation, cost blow-up, context overflow. (§5)
6. **"When NOT to use multi-agent?"** → when a single agent+tools suffices — avoid needless coordination cost. (§6)

## 8. One-screen recall
- Multi-agent = specialized agents collaborating via messages; **decomposition+specialization** vs **coordination cost**.
- **Topologies**: sequential · **supervisor/orchestrator-worker** (most controllable) · hierarchical · group-chat · network.
- **Comms**: shared history/blackboard, structured hand-off, agent-as-tool. Frameworks: AutoGen, LangGraph, SK Agent Framework, CrewAI.
- **Control**: **max turns/step budget**, termination conditions, per-agent roles/tools (least privilege), deterministic orchestrator.
- **Failure modes**: infinite loops, error propagation (→ reviewer agent), cost/latency explosion, context overflow.
- **Default to single agent + tools**; escalate only when specialization/parallelism justifies cost.

> Next: MCP (Model Context Protocol).
