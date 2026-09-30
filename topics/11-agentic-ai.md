# 11 · Agentic AI

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
Agentic AI is an LLM that can **plan and act** — it decides steps, calls tools, observes results, and loops until the goal is done, instead of answering in one shot.

## 2. Architect-Level Explanation
An **agent** = LLM (reasoner) + tools + memory + a control loop.
- **Loop patterns**: ReAct (reason→act→observe), Plan-and-Execute, Reflexion (self-critique).
- **Components**: goal, planner, tool executor (function calling), short/long-term memory, termination criteria.
- **Autonomy spectrum**: from tool-augmented chat → semi-autonomous workflows → fully autonomous agents.
- Architect concerns: **non-determinism**, cost of loops, safety of actions, observability, and guardrails/human-in-the-loop for irreversible actions.

## 3. Real Enterprise Use Case
An IT ops agent triages incidents: reads the alert, queries logs (tool), checks runbooks (RAG), proposes a fix, and — with human approval — executes a remediation script. Bounded steps, full audit trace, approval gate for destructive actions.

## 4. Architecture Diagram (ASCII)
```
        Goal
         │
   ┌─────▼──────────────── Agent Loop ─────────────┐
   │  Reason (LLM) ─► Choose tool ─► Execute ─► Observe
   │      ▲                                      │
   │      └──────────── memory ◄─────────────────┘
   └───────────────────────────────────────────────┘
   Termination (goal met / max steps) ─► Answer/Action
   Guardrails + human approval for risky actions
```

## 5. Interview Questions
1. What makes a system "agentic" vs a plain LLM call?
2. ReAct vs Plan-and-Execute vs Reflexion?
3. How do you control cost and non-determinism?
4. How do you make agent actions safe?
5. When should you NOT use an agent?

## 6. Strong Interview Answers
- **Agentic**: "It has autonomy — a loop where the LLM plans, calls tools, observes, and decides next steps toward a goal, rather than a single request/response."
- **Patterns**: "ReAct interleaves reasoning and actions (good default); Plan-and-Execute plans upfront then runs (cheaper, more predictable); Reflexion adds self-critique to improve quality on hard tasks."
- **Control**: "Cap steps and token budget, prefer deterministic tools, use a smaller model for routing, and add termination/guardrails. Log every step."
- **Safety**: "Least-privilege tools, validate args, human-in-the-loop approval for irreversible/destructive actions, dry-run modes, and full audit trails."
- **When not to**: "If a fixed chain/workflow solves it, use that — agents add cost, latency, and unpredictability. Reserve autonomy for genuinely dynamic tasks."

## 7. Common Mistakes
- Using agents where a deterministic pipeline works.
- No step/token caps → runaway loops and cost.
- Giving agents powerful tools without approval gates.
- No observability → impossible to debug.

## 8. Trade-offs
| Aspect | Agent | Fixed workflow |
|--------|-------|----------------|
| Flexibility | high | low |
| Predictability | low | high |
| Cost/latency | higher | lower |
| Debuggability | harder | easier |

## 9. Production Best Practices
- Bound steps, budget, and time; explicit termination.
- Human-in-the-loop for risky actions.
- Deterministic, typed, idempotent tools.
- Full tracing (each thought/action/observation).
- Evaluate end-to-end on task success, not vibes.

## 10. Security Considerations
- Prompt injection can hijack the loop — treat tool inputs/outputs as untrusted.
- Least-privilege tool scopes; approval gates.
- Sandbox code/exec tools; audit every action.

## 11. Cost Optimization
- Fewer, higher-quality tools; cap iterations.
- Small model for planning/routing, big model only when needed.
- Cache tool results; reuse memory instead of re-querying.

## 12. Troubleshooting Scenarios
- **Loops/stuck** → step limit + termination + reflection.
- **Wrong tool use** → better tool descriptions/schemas.
- **Runaway cost** → token/step budget, cheaper router model.
- **Unsafe action** → add approval gate + dry run.

## 13. Hands-on Example
```python
# ReAct-style pseudo-loop
for step in range(MAX_STEPS):
    thought, action, args = llm_decide(goal, memory)
    if action == "final": break
    obs = TOOLS[action](**args)          # validated tools
    memory.append((thought, action, obs))
```

## 14. Terraform Example
```hcl
# Durable state + queue for agent workflows
resource "azurerm_cosmosdb_account" "state" {
  name = "agent-state" resource_group_name = azurerm_resource_group.rg.name
  location = "eastus" offer_type = "Standard" kind = "GlobalDocumentDB"
  consistency_policy { consistency_level = "Session" }
  geo_location { location = "eastus" failover_priority = 0 }
}
```

## 15. Azure Example
Use **Azure AI Agent Service** (in AI Foundry) for managed agents with tools (code interpreter, AI Search, functions), threads, and tracing — offloads the loop/state plumbing.

## 16. FastAPI / Python Example
```python
@app.post("/agent")
def run_agent(goal: str):
    trace = []
    for _ in range(8):                      # bounded loop
        decision = plan(goal, trace)
        if decision.done: return {"result": decision.answer, "trace": trace}
        result = TOOLS[decision.tool](**decision.args)
        trace.append({"tool": decision.tool, "result": result})
    return {"result": "max steps reached", "trace": trace}
```

## 17. AKS Example
Run agents as Deployments in AKS; use KEDA to scale on task-queue depth; persist agent state in Cosmos/Redis; approval gates via a separate human-task service.

## 18. How to Remember
**"Think → act → observe → repeat."** An agent is an LLM in a loop with tools and a stop button.

## 19. Real-World Analogy
A junior employee given a goal and a toolbox: they figure out steps, use tools, check results, and ask for sign-off before doing anything irreversible.

## 20. One-Page Cheat Sheet
- **What**: LLM + tools + memory + control loop that plans and acts.
- **Patterns**: ReAct, Plan-and-Execute, Reflexion.
- **Control**: cap steps/tokens/time; explicit termination.
- **Safe**: least-privilege tools, validate args, human approval for risky actions.
- **Observe**: trace every thought/action/observation.
- **Rule**: use fixed workflows unless the task truly needs autonomy.
