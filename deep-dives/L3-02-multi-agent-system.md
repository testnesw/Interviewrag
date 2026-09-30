# LEVEL 3 · System Design — Production Multi-Agent System

> Synthesis scenario. Combines: agentic AI · multi-agent · function calling · MCP ·
> guardrails · orchestration · observability.

---

## 0. The prompt
> *"Design an autonomous 'operations assistant' that can investigate an incident: read logs, query databases, call internal APIs, summarize, and (with approval) execute remediation. Multiple specialized agents collaborate."*

---

## 1. Clarify — requirements
**Functional**: multi-step reasoning; tool use (logs, DB, APIs, runbooks); specialist agents (triage, diagnostics, remediation); human approval for actions.
**Non-functional**: safety (no destructive action without approval), determinism/traceability, bounded cost/latency, auditability.
**Killer constraints**: **autonomy vs safety** (agents take actions) + **cost/loop control** (agents can spiral).

## 2. Architecture — orchestration pattern
```
                ┌── Orchestrator / Planner ──┐
                │  (routes, decomposes goal)  │
      ┌─────────┼───────────────┬─────────────┤
  Triage Agent  Diagnostics    Remediation   Summarizer
   (classify)   (tools: logs,   (tools: API,   (report)
                 DB, metrics)    with APPROVAL)
                │
         Shared memory / state (context, findings)
         Tools via function calling / MCP servers
```
- **Pattern choice**: **orchestrator-worker** (a planner delegates to specialists) — more controllable than free-for-all group chat. Alternatives: sequential pipeline, hierarchical, group-chat (debate).

## 3. Key design decisions (with "why")
- **Specialized agents** > one mega-agent → focused prompts/tools, better accuracy, easier eval (separation of concerns).
- **Tools via MCP / function calling**: define typed tool schemas; **MCP** standardizes tool servers so agents share a tool catalog. Each tool = least-privilege identity.
- **Human-in-the-loop gate**: remediation agent proposes an action → **approval step** (like a Durable Functions "wait for external event") before execution.
- **State/memory**: shared scratchpad (findings) + short-term conversation + long-term vector memory (past incidents) for retrieval.
- **Planner**: explicit plan (ReAct / plan-and-execute) so steps are inspectable, not a black box.

## 4. Safety & control (the make-or-break)
- **Guardrails**: allow-list of tools per agent; destructive actions require approval + are **idempotent**; dry-run mode.
- **Loop/cost control**: max steps, max tokens, timeout, budget per investigation; circuit-breaker if no progress.
- **Content Safety / prompt shields**: defend against prompt injection from tool outputs (logs can contain malicious text → treat tool output as untrusted).
- **Determinism aids**: low temperature for routing/decisions; structured outputs (JSON schema) for tool calls.

## 5. Reliability & scale
- Each agent call = retriable; **saga-style** compensation if a multi-step action partially fails.
- Stateless agent workers behind a queue; orchestrator persists state (Durable Functions / workflow engine) → survives restarts.
- Parallel fan-out for independent diagnostics; fan-in to summarizer.

## 6. Observability & evaluation
- **Trace every step**: agent, prompt, tool call, tokens, decision, latency → App Insights / LangSmith-style tracing.
- **Eval**: task success rate, steps-to-resolution, tool-call accuracy, cost per incident; replay traces on regressions.
- Full **audit trail** (what each agent did, what was approved) for compliance.

## 7. The follow-ups
1. **"Why multiple agents not one?"** → separation of concerns → focused tools/prompts, better accuracy + testability. (§3)
2. **"Stop an agent taking a destructive action?"** → tool allow-lists + **human approval gate** + idempotent/dry-run. (§4)
3. **"Prompt injection from a log line?"** → treat tool output as untrusted, prompt shields, don't grant raw exec. (§4)
4. **"Agent loops forever / burns cost?"** → max steps/tokens/budget + circuit breaker. (§4)
5. **"How do agents share findings?"** → shared state/memory + long-term vector memory of past incidents. (§3)
6. **"Orchestration pattern?"** → orchestrator-worker (controllable) vs group-chat (emergent). (§2)
7. **"Survive a crash mid-investigation?"** → durable orchestrator persists state; retriable steps + saga compensation. (§5)
8. **"Evaluate it?"** → task success, steps, tool accuracy, cost/incident + trace replay. (§6)

## 8. One-screen recall
- **Orchestrator-worker**: planner delegates to **specialized agents** (triage/diagnostics/remediation/summary).
- **Tools** via **function calling / MCP**, least-privilege per tool.
- **Safety**: tool allow-lists, **human approval** for actions, idempotent/dry-run, prompt shields (untrusted tool output).
- **Control**: max steps/tokens/budget + circuit breaker; low temp + structured outputs.
- **Reliability**: durable stateful orchestrator, retriable steps, saga compensation, queue+parallel.
- **Observe**: trace every step; eval success/steps/cost; full audit.

> Next L3: Enterprise LLM Gateway.
