# DEEP MECHANICS · LangGraph

> Level 2 — the graph model, state, nodes/edges, cycles, checkpointing,
> human-in-the-loop, and LangGraph vs chains/agents.

---

## 0. The precise mental model
LangGraph models an agent as a **stateful directed graph**: **nodes** are functions that read/update a **shared state**, and **edges** (including **conditional** ones) decide what runs next — **cycles allowed**. Where a LangChain "agent" is an opaque LLM loop, LangGraph makes the loop **explicit, inspectable, and controllable**. Think **state machine for LLM workflows** with built-in persistence, streaming, and human-in-the-loop.

---

## 1. The core primitives
- **State** — a shared, typed object (often a `TypedDict`) passed through the graph. Nodes return partial updates that are **merged** via **reducers** (e.g., `add_messages` appends instead of overwrites).
- **Node** — a Python function (or LLM/tool call) that takes state → returns a state update.
- **Edge** — connects nodes. **Normal edge** = always go A→B. **Conditional edge** = a router function inspects state → returns the next node name (branching).
- **Entry point** + **END** sentinel. Cycles = an edge pointing back → loops (agent reasoning).

```python
graph = StateGraph(State)
graph.add_node("retrieve", retrieve)
graph.add_node("generate", generate)
graph.add_conditional_edges("grade", route)   # branch on state
graph.add_edge("retrieve", "grade")
app = graph.compile(checkpointer=saver)
```

## 2. Why a graph (vs a plain agent loop)
- **Controllability**: you define the allowed transitions → no runaway "LLM decides everything." Add **step limits / termination** explicitly.
- **Inspectability**: every node/transition is traceable → debug + eval each step.
- **Cycles with control**: agent "think→act→observe" loops are first-class but bounded.
- **Determinism where you want it**: mix deterministic nodes (code) with LLM nodes.

## 3. State & reducers (commonly misunderstood)
- Default: a node's returned keys **overwrite** state.
- A **reducer** changes merge behavior — e.g., messages use `add_messages` to **append** conversation turns.
- This is how conversation history accumulates across cycles without you manually concatenating.

## 4. Persistence & checkpointing (big differentiator)
- A **checkpointer** (memory, SQLite, Postgres, Redis) **saves state after every step**, keyed by a **thread_id**.
- Enables: **durable, resumable** executions (crash → resume), **multi-turn memory** (same thread continues), **time-travel** (rewind to a prior checkpoint), and **human-in-the-loop** pauses.

## 5. Human-in-the-loop
- **Interrupt** before/after a node (`interrupt_before=["tools"]`) → graph **pauses**, persists state, waits.
- A human reviews/edits state (e.g., approve a tool action) → resume from the checkpoint.
- Critical for agents that take real-world actions (approval gates).

## 6. Multi-agent patterns
- Model each agent as a node (or a subgraph); a **supervisor/router** node uses conditional edges to delegate → orchestrator-worker, hierarchical, or network topologies.
- Shared state passes findings between agents; subgraphs compose.

## 7. Execution features
- **Streaming**: stream state updates / tokens / node events as they happen.
- **Parallelism**: fan-out to multiple nodes then fan-in (merge via reducers).
- **Async** + retries per node; integrates with **LangSmith** for tracing/eval.

## 8. LangGraph vs chains vs agents
| | Chain (LCEL) | Agent (classic) | **LangGraph** |
|---|---|---|---|
| Flow | fixed DAG | LLM-chosen, opaque | **explicit graph + cycles** |
| State | pass-through | hidden | **shared, persisted** |
| Control | high | low | **high (defined edges)** |
| Loops | no | yes (unbounded-ish) | **yes, bounded** |
| Best for | predictable pipelines | quick flexible tools | **reliable multi-step/agentic** |

## 9. The hard follow-ups (with answers)
1. **"Why LangGraph over a LangChain agent?"** → explicit, **controllable + inspectable** state machine with bounded cycles vs an opaque LLM loop. (§2)
2. **"What's the state and how does it update?"** → a typed shared object; nodes return partial updates merged via **reducers** (e.g., append messages). (§1/§3)
3. **"Conditional edge?"** → a router function reads state → returns next node name → branching/looping. (§1)
4. **"How is memory/durability handled?"** → **checkpointer** persists state per **thread_id** → resumable, multi-turn, time-travel. (§4)
5. **"Add an approval step before a tool runs?"** → **interrupt** before the node → pause/persist → human edits state → resume. (§5)
6. **"Stop an infinite agent loop?"** → explicit termination/step-count in edges (graph controls transitions). (§2)
7. **"Multi-agent in LangGraph?"** → supervisor node + conditional routing to agent nodes/subgraphs sharing state. (§6)
8. **"LangGraph vs chain?"** → chain = fixed DAG (no cycles/state); LangGraph = stateful graph with controlled loops. (§8)

## 10. One-screen recall
- **Stateful directed graph**: **nodes** (fn: state→update) + **edges** (normal / **conditional** router) + **cycles**.
- **State** = typed shared object; **reducers** control merge (`add_messages` appends).
- **vs agent**: explicit, inspectable, **bounded** loops — a state machine, not an opaque loop.
- **Checkpointer** (thread_id) → durable, resumable, multi-turn memory, time-travel.
- **Human-in-the-loop**: **interrupt** → pause/persist → resume (approval gates).
- **Multi-agent**: supervisor + conditional edges + subgraphs; streaming, parallel, LangSmith tracing.
- **vs chain**: fixed DAG (no state/cycles) vs stateful controllable graph.

> Next: Multi-Agent Architecture.
