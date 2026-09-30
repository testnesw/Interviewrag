# DEEP MECHANICS · Agentic AI

> Level 2 — how an agent loop actually executes, the exact tool-calling
> protocol, memory mechanics, multi-agent coordination, and the failure modes
> and safety controls interviewers drill.

---

## 0. The precise mental model
An agent is an **LLM in a loop with tools and memory**. The LLM doesn't "do" anything itself — it **emits a decision** (either a tool call or a final answer); your **orchestrator** executes tools and feeds results back into the context; repeat until the model emits a final answer or a stop condition trips. The intelligence is the model's next-token prediction; the **agency** is the loop your code runs around it. Understand the loop and the tool-calling protocol and everything else follows.

---

## 1. The agent loop (ReAct) — mechanically

**ReAct = Reasoning + Acting**, interleaved:
```
loop:
  1. Build prompt = system + tools schema + goal + scratchpad(history of thoughts/actions/observations)
  2. LLM call → returns either:
       (a) a TOOL CALL (name + JSON args), or
       (b) a FINAL ANSWER
  3. If tool call:
       - orchestrator EXECUTES the tool (API/DB/search)
       - append the OBSERVATION (tool result) to the scratchpad
       - go to 1  (the model now "sees" the result and reasons again)
  4. If final answer: return it
until: final answer OR max_iterations OR budget/time limit
```
**Key insight:** the model is called **repeatedly**, each time with the growing scratchpad. It "reasons" by generating a thought, "acts" by requesting a tool, and "observes" by reading the result you inject. The loop grounds each step in real tool feedback — that's why agents outperform single-shot on multi-step tasks.

**Deep follow-up: "Where does the actual tool execution happen — the model or your code?"**
Your code. The LLM only **emits** a structured request ("call `get_weather(city='London')`"). It has no ability to run anything. Your orchestrator parses that, executes the real function, and returns the result as the next observation. This separation is the whole security boundary.

---

## 2. Tool / function calling — the exact protocol

**Setup:** you pass the model a list of tools, each with a **JSON Schema** (name, description, parameters + types). The description is *prompt* — the model uses it to decide when/how to call.

**The round trip:**
1. You send messages + tool schemas.
2. Model responds with a **`tool_calls`** object: the chosen tool name + **arguments as JSON** (the model "fills in" the schema).
3. Your code **validates** the args (against the schema / Pydantic), **executes** the real function.
4. You append a **`tool` role message** with the result and call the model again.
5. Model either calls another tool or produces the final answer.

**Parallel tool calls:** modern models can emit **multiple tool calls at once** (e.g., look up 3 things) → you execute them concurrently and return all results.

**Why structured output matters:** the model returns **valid JSON matching your schema**, so you get typed, machine-usable actions instead of parsing free text. This is what makes tools reliable.

**Deep follow-up: "The model calls a tool with invalid/hallucinated arguments — what do you do?"**
Validate against the schema; on failure, **return the validation error as the observation** so the model can self-correct on the next turn (it re-reads the error and retries with fixed args). Never execute unvalidated args. Cap retries.

---

## 3. Memory — short-term vs long-term (mechanics)

- **Short-term (working memory)** = the **scratchpad / conversation buffer** in the context window: the running thought-action-observation history. It's bounded by tokens → for long tasks you must **summarize/compress** older steps or you overflow.
- **Long-term memory** = an **external store** (usually a **vector DB**) of past interactions/facts. The agent **retrieves** relevant memories (RAG-style) into context when needed, and **writes** new memories after steps. This is how an agent "remembers" across sessions beyond the window.

**The context-budget problem:** every loop iteration re-sends the growing scratchpad → tokens (and cost/latency) grow each step. Mitigations: summarize old steps, trim irrelevant observations, cap tool-result size, and retrieve long-term memory selectively.

**Deep follow-up: "A 30-step agent task blows the context window — fix?"**
Compress the scratchpad: summarize completed sub-steps into a short state, keep only recent raw steps, offload details to long-term memory and retrieve on demand. Essentially manage working memory like a cache.

---

## 4. Planning strategies
- **ReAct (reactive)** — decide the next action one step at a time based on the latest observation. Flexible, adapts to results; can wander.
- **Plan-and-execute** — the model first generates a **full plan** (list of steps), then executes them (optionally re-planning). More directed, fewer LLM calls for the reasoning, but brittle if the plan is wrong.
- **Reflection / self-critique** — after producing a result, a step (or a second "critic") evaluates and revises → higher quality at more cost.
- **Tree/graph search (ToT)** — explore multiple reasoning branches and pick the best — expensive, for hard problems.

**Architect judgment:** more autonomy = more capability *and* more cost, latency, and unpredictability. Prefer the **least autonomy** that solves the task; explicit orchestration beats "let the agent figure it out" for production reliability.

---

## 5. Multi-agent coordination

**When:** the task decomposes into **specialized roles** that benefit from separation (e.g., planner, researcher, coder, critic) or need isolation/parallelism.

**Patterns:**
- **Orchestrator–workers (hierarchical)**: a lead agent decomposes and delegates sub-tasks to specialized workers, then synthesizes. Most common production pattern.
- **Sequential pipeline**: output of one agent feeds the next (research → draft → review).
- **Group chat / debate**: agents converse to reach consensus — powerful but token-expensive and can loop.
- **Blackboard**: agents read/write a shared state.

**Cost reality:** each agent turn is an LLM call; multi-agent multiplies calls → cost/latency balloon. **Only go multi-agent when a single agent genuinely can't handle the complexity.**

**Deep follow-up: "Two agents keep ping-ponging without converging — what's wrong and how do you fix it?"**
No stop condition / no authority. Add: a max-turns cap, a designated decider (orchestrator makes the final call), clearer role boundaries, and a convergence check. Unbounded agent conversations are a classic failure.

---

## 6. Failure modes & safety controls (the production part)

**Failure modes:**
- **Infinite/long loops** → cap `max_iterations`, add budget/time limits.
- **Hallucinated tool calls / wrong args** → schema validation + error-as-observation retry.
- **Tool errors cascading** → wrap tools with retry/backoff/timeout; feed failures back so the agent adapts or aborts gracefully.
- **Prompt injection via tool results** → a web page/doc the agent reads can contain "ignore your instructions" → treat **all tool output as untrusted data**, not instructions.
- **Cost explosion** → each step is tokens; monitor per-task cost.

**Safety controls (say these):**
- **Least-privilege tools** — the agent can only call what you expose; scope each tool's permissions tightly (read-only where possible).
- **Human-in-the-loop** approval for high-impact/irreversible actions (payments, deletes, emails).
- **Sandboxing** for code-execution tools.
- **Guardrails** on inputs/outputs (content filters, injection detection).
- **Iteration/budget caps** and **audit logging** of every thought/action/observation.

**Deep follow-up: "How do you stop prompt injection through a tool result?"**
Never treat tool/retrieved content as instructions — keep it in a clearly delimited data channel, instruct the model that tool output is untrusted, validate/sanitize, and require human approval for sensitive actions. The agent should *use* the data, not *obey* it.

---

## 7. Observability for agents
- **Trace every step**: thought, tool name, args, observation, tokens, latency — per iteration. Without this, non-deterministic agents are undebuggable.
- **Metrics**: loop length (steps/task), tool error rate, cost per task, success rate, human-intervention rate.
- **Replay**: store full traces so you can reproduce and debug a bad run.
- Tools: OpenTelemetry + LLM-tracing (e.g., Azure AI Foundry tracing / OTel GenAI semantics).

---

## 8. The hard follow-up questions (with answers)
1. **"Walk one full ReAct iteration."** → build prompt (system+tools+goal+scratchpad) → LLM emits tool call → orchestrator validates+executes → append observation → loop; stop on final answer / max iters. (§1)
2. **"Who executes the tool — the model?"** → No; the model only emits a structured request; your orchestrator runs it. That's the security boundary. (§1)
3. **"Model returns invalid tool args — recover?"** → validate; return the error as the observation so it self-corrects; cap retries. (§2)
4. **"Long agent task overflows context — fix?"** → summarize/compress scratchpad + long-term vector memory + trim tool results. (§3)
5. **"ReAct vs plan-and-execute — when each?"** → ReAct for adaptive/uncertain tasks; plan-and-execute for well-structured multi-step with fewer reasoning calls. (§4)
6. **"When multi-agent vs single?"** → only when specialized roles/parallelism justify the extra calls; else single agent. (§5)
7. **"Prompt injection via a fetched web page — defend?"** → treat tool output as untrusted data, delimit it, don't obey it, HITL for sensitive actions. (§6)
8. **"Agent runs forever / costs explode — controls?"** → max_iterations, budget/time caps, convergence checks, per-task cost monitoring. (§6)

---

## 9. One-screen deep-recall sheet
- **Agent = LLM in a loop with tools + memory.** Model **emits** decisions; **your orchestrator executes**. Agency = the loop, not the model.
- **ReAct loop**: prompt(system+tools+goal+**scratchpad**) → LLM → **tool call** or **final answer** → execute tool → append **observation** → repeat until answer/max-iters/budget.
- **Tool calling**: pass **JSON-Schema** tools; model returns `tool_calls` (name+JSON args); **validate → execute → return `tool` message** → loop. Parallel calls possible. Invalid args → **error-as-observation** retry.
- **Memory**: short-term = scratchpad (token-bounded → **summarize/compress**); long-term = **vector store** (retrieve/write). Manage context budget every iteration.
- **Planning**: ReAct (reactive) · plan-and-execute (directed) · reflection (quality) · ToT (expensive). **Least autonomy that works.**
- **Multi-agent**: orchestrator-workers / pipeline / debate / blackboard — only when justified (each turn = an LLM call). Need stop conditions + a decider to avoid ping-pong.
- **Failure/safety**: cap iterations+budget; validate args; retry/timeout tools; **treat tool output as untrusted (injection)**; **least-privilege tools**; **human-in-the-loop** for irreversible actions; sandbox code; audit-trace everything.
- **Observability**: trace thought/tool/args/observation/tokens per step; metrics = loop length, tool error rate, cost/task, success rate.

---

> Next: **Microservices**.
