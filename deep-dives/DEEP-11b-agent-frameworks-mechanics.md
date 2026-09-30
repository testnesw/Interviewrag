# DEEP MECHANICS · Agent Frameworks (AutoGen · CrewAI · Semantic Kernel · LangGraph)

> Level 2 — the major multi-agent frameworks, their models, and when to pick each.

---

## 0. The precise mental model
Agent frameworks orchestrate **multiple LLM "agents" + tools + memory** toward a goal. They differ mainly in **control model**: **conversation/emergent** (AutoGen), **role/process-based** (CrewAI), **graph/state-machine** (LangGraph), or **enterprise plugin/DI** (Semantic Kernel). Pick by how much **explicit control vs emergent autonomy** you want, plus your stack (Python vs .NET/Azure).

---

## 1. AutoGen (Microsoft)
- **Model**: **conversational multi-agent** — agents *talk to each other* (group chat) to solve tasks; a manager coordinates turns.
- Strong at **emergent collaboration**, code execution, human-in-the-loop.
- Patterns: two-agent chat, group chat + manager, nested chats.
- **Best for**: research/experimentation, dynamic agent-to-agent reasoning; v0.4 is event-driven/async.

## 2. CrewAI
- **Model**: **role-based "crew"** — you define **agents (role, goal, backstory)** + **tasks** + a **process** (sequential or hierarchical).
- Opinionated, quick to stand up; mental model = "a team with assigned jobs."
- **Best for**: fast, structured role-playing pipelines with clear division of labor.

## 3. LangGraph
- **Model**: **explicit stateful graph** (nodes/edges/cycles) — the most **controllable** (see its own deep file).
- **Best for**: production agents needing determinism, checkpointing, human-in-the-loop, bounded loops.

## 4. Semantic Kernel (Microsoft)
- **Model**: **enterprise orchestration SDK** — **plugins/functions**, planners, DI, filters; **.NET-first** (also Python). Has an **Agent Framework**.
- **Best for**: enterprise **Azure/.NET** apps needing governance, DI, observability, integration with existing code.

## 5. Choosing (the interview answer)
| Framework | Control model | Sweet spot |
|---|---|---|
| **AutoGen** | conversational/emergent | research, agent-to-agent, code gen |
| **CrewAI** | role + process | quick structured teams |
| **LangGraph** | explicit graph/state | **production, controllable, HITL** |
| **Semantic Kernel** | plugins/DI/planner | enterprise **.NET/Azure** |

- More **emergence** (AutoGen) = flexible but less predictable; more **structure** (LangGraph/SK) = reliable but more design effort.
- Azure enterprise → SK or LangGraph; rapid prototyping → CrewAI/AutoGen.

## 6. Cross-cutting concerns (all frameworks)
- **Tool/function calling** for actions; **memory** (short-term + vector long-term); **guardrails** + human approval for real actions; **loop/cost limits**; **tracing/eval** (LangSmith, App Insights). These matter more than the framework choice.

## 7. The hard follow-ups (with answers)
1. **"AutoGen vs CrewAI vs LangGraph?"** → conversational/emergent vs role+process vs explicit controllable graph. (§5)
2. **"Most control for production?"** → **LangGraph** (state, checkpoints, bounded loops, HITL). (§3/§5)
3. **"Enterprise .NET/Azure?"** → **Semantic Kernel** (DI, plugins, filters, governance). (§4)
4. **"Fastest to a working crew?"** → **CrewAI** (roles + tasks + process). (§2)
5. **"Emergent collaboration / agents debating?"** → **AutoGen** group chat. (§1)
6. **"What matters more than framework?"** → tools, memory, guardrails, cost limits, eval/tracing. (§6)

## 8. One-screen recall
- **AutoGen** = conversational/emergent multi-agent (research, code).
- **CrewAI** = role + task + process (quick structured teams).
- **LangGraph** = explicit stateful **graph** → most controllable (production, HITL).
- **Semantic Kernel** = enterprise plugins/DI/planner (**.NET/Azure**).
- Trade **emergence (flexible)** vs **structure (reliable)**; pick by control need + stack.
- Cross-cutting: tools, memory, **guardrails + approval**, cost limits, **eval/tracing** > framework choice.

> Next: MCP.
