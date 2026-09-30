# DEEP MECHANICS · Agentic Memory Architectures

> Level 2 — short-term vs long-term memory, working/episodic/semantic/procedural,
> context management, and retrieval-based memory.

---

## 0. The precise mental model
An LLM is **stateless** — it only "knows" what's in the current context window. **Agent memory** is the machinery that gives an agent continuity across turns and sessions: decide **what to keep, where to store it, and how to retrieve the right piece back into context** at the right time. It's fundamentally a **context-management + retrieval** problem, because the window is finite.

---

## 1. The memory hierarchy
- **Working / short-term memory** = the **context window** itself (current conversation + scratchpad). Fast, but limited + ephemeral.
- **Long-term memory** = external store (vector DB, key-value, graph) persisted across sessions; retrieved on demand into context.
- The agent loop: perceive → **retrieve relevant memory** → reason/act → **write new memory**.

## 2. Types of memory (cognitive framing, common in interviews)
| Type | Holds | Example |
|---|---|---|
| **Working** | current task context | the live conversation |
| **Episodic** | past experiences/events | "last time the user asked X, we did Y" |
| **Semantic** | facts/knowledge | user preferences, domain facts |
| **Procedural** | how-to / skills | learned tool-use patterns, system prompt |
- Episodic + semantic long-term memory are usually **retrieval-augmented** (embed + vector search).

## 3. Short-term context management (finite window)
- Conversations exceed the window → strategies:
  - **Sliding window** (keep last N turns) — simple, loses old context.
  - **Summarization / progressive compression** — condense old turns into a running summary (recursive) → keep gist, save tokens.
  - **Token budgeting** — allocate window: system + summary + retrieved memory + recent turns.
- Trade recall vs cost; summarization can lose detail → keep key facts in long-term memory too.

## 4. Long-term memory (retrieval-based)
- **Write**: extract salient facts/events → embed → store (vector DB) with metadata (time, user, source).
- **Read**: embed current context → retrieve top-k relevant memories → inject into the prompt (RAG over the agent's own history).
- **What to store** (memory formation): not everything — extract durable facts (preferences, decisions, outcomes); dedup + update contradictions.
- **Forgetting/decay**: TTL, relevance/recency scoring, consolidation → avoid unbounded growth + stale memory.

## 5. Advanced structures
- **Reflection / self-consolidation**: periodically summarize episodic memories into higher-level semantic insights (à la Generative Agents).
- **Knowledge-graph memory**: store entities + relations (GraphRAG-style) → multi-hop recall of connected facts.
- **Hierarchical memory** (e.g., MemGPT): treat context like an OS with paging between "main context" and "external storage" — the agent decides what to page in/out.
- **Scoping**: per-user / per-session / shared — with access control (don't leak one user's memory to another).

## 6. Frameworks
- LangGraph **checkpointer** (thread-scoped state persistence), LangMem/mem0/Zep, Semantic Kernel memory, vector stores as the backing layer.

## 7. The hard follow-ups (with answers)
1. **"Why do agents need memory?"** → LLMs are **stateless** (only the window); memory gives continuity across turns/sessions. (§0)
2. **"Short-term vs long-term?"** → working = context window (ephemeral); long-term = external store retrieved on demand. (§1)
3. **"Conversation exceeds the window?"** → sliding window + **summarization/compression** + token budgeting; persist key facts long-term. (§3)
4. **"How is long-term memory retrieved?"** → embed current context → vector search over stored memories → inject top-k (RAG over history). (§4)
5. **"What do you store, and how avoid bloat?"** → extract durable facts, dedup, **decay/TTL + relevance scoring**, consolidate. (§4)
6. **"Episodic vs semantic memory?"** → episodic = past events; semantic = distilled facts/knowledge. (§2)
7. **"MemGPT idea?"** → OS-style **paging** between in-context and external memory, agent-managed. (§5)
8. **"Multi-user memory risk?"** → scope + access-control memory so one user's data never leaks to another. (§5)

## 8. One-screen recall
- LLMs are **stateless** → memory = **what to keep + where + how to retrieve** into a finite window.
- **Working** (context window) vs **long-term** (external store); types: **episodic / semantic / procedural**.
- **Short-term mgmt**: sliding window + **summarization/compression** + token budgeting.
- **Long-term**: extract salient facts → embed → vector store; retrieve top-k relevant → inject (RAG over history); **decay/TTL + dedup**.
- **Advanced**: reflection/consolidation, **graph memory**, **MemGPT paging**, per-user scoping + access control.
- Tools: LangGraph checkpointer, mem0/Zep/LangMem.

> Next: Agent Evaluation.
