# 12 · Multi-Agent Architecture

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
Multi-agent architecture uses **several specialized AI agents that collaborate** — like a team where each member has a role (researcher, coder, reviewer) coordinated to solve a bigger task.

## 2. Architect-Level Explanation
Multiple agents, each with its own role/tools/prompt, coordinated by a topology:
- **Topologies**: orchestrator–worker (supervisor), sequential pipeline, hierarchical, group-chat/debate, blackboard.
- **Coordination**: a supervisor routes tasks; agents communicate via messages/shared state.
- **Frameworks**: AutoGen, Semantic Kernel Agent Framework, LangGraph, CrewAI, **Magentic-One**.
- Architect concerns: communication overhead/cost, error propagation, termination, state consistency, and observability across agents.

## 3. Real Enterprise Use Case
A software-modernization platform: a **Planner** agent breaks the task down, a **Coder** agent writes code, a **Tester** agent runs tests, a **Reviewer** agent critiques — a supervisor loops them until tests pass, with human sign-off before merge.

## 4. Architecture Diagram (ASCII)
```
                 Supervisor / Orchestrator
              ┌──────────┼───────────┬──────────┐
          Researcher   Coder       Tester    Reviewer
             (RAG)    (tools)     (sandbox)  (critique)
              └──────────┴───────────┴──────────┘
                 shared state / message bus
        Termination: goal met / max rounds ─► Result (+ human gate)
```

## 5. Interview Questions
1. When do multiple agents beat one agent?
2. Common multi-agent topologies?
3. How do you prevent runaway cost/loops across agents?
4. How do agents share state and avoid conflicts?
5. How do you debug a multi-agent system?

## 6. Strong Interview Answers
- **When**: "When a task decomposes into distinct specialties (research/code/test/review) or benefits from debate/critique. Otherwise a single agent is cheaper and simpler."
- **Topologies**: "Supervisor–worker for routing/control; sequential pipeline for staged tasks; group-chat/debate for quality via critique; hierarchical for large decompositions."
- **Cost/loops**: "Global round/token budgets, clear termination, a supervisor that prunes work, and smaller models for narrow roles."
- **State**: "Shared, versioned state (or message passing) with a single writer per artifact; a supervisor arbitrates conflicts to avoid divergent edits."
- **Debugging**: "Per-agent tracing with correlation IDs, transcript logging, and step-level evaluation — treat it like distributed systems observability."

## 7. Common Mistakes
- Multi-agent where a single agent (or plain workflow) suffices.
- No global termination → agents loop forever.
- Uncontrolled chatter → token explosion.
- No conflict resolution on shared state.
- No cross-agent tracing.

## 8. Trade-offs
| Aspect | Multi-agent | Single agent |
|--------|-------------|--------------|
| Capability on complex tasks | higher | lower |
| Cost/latency | higher | lower |
| Complexity | high | low |
| Debuggability | harder | easier |

## 9. Production Best Practices
- Clear roles, minimal necessary agents.
- Supervisor with global budgets + termination.
- Structured messages; single-writer state.
- Human-in-the-loop gates for high-impact output.
- Correlated tracing + per-role evaluation.

## 10. Security Considerations
- One compromised/injected agent can mislead others — validate inter-agent messages.
- Least-privilege tools per role.
- Audit all actions; sandbox executors.

## 11. Cost Optimization
- Right-size model per role (small for narrow tasks).
- Cap rounds and message length; summarize shared context.
- Short-circuit when a confident answer exists.

## 12. Troubleshooting Scenarios
- **Endless debate** → round cap + supervisor termination.
- **Contradictory outputs** → single source of truth + arbiter.
- **Cost spike** → reduce agents/rounds, smaller models.
- **Hard to trace** → correlation IDs + transcript store.

## 13. Hands-on Example (AutoGen-style)
```python
planner = Agent("planner"); coder = Agent("coder"); tester = Agent("tester")
supervisor.route(task, agents=[planner, coder, tester], max_rounds=6,
                 terminate_when=lambda s: s.tests_passed)
```

## 14. Terraform Example
```hcl
# Message bus for agent coordination
resource "azurerm_servicebus_namespace" "bus" {
  name = "agents-bus" location = "eastus"
  resource_group_name = azurerm_resource_group.rg.name sku = "Standard"
}
```

## 15. Azure Example
Use **Azure AI Agent Service** with **connected agents**, or AutoGen on Azure Container Apps; coordinate via Service Bus; trace to App Insights.

## 16. FastAPI / Python Example
```python
@app.post("/team")
def team(task: str):
    state = State(task=task)
    for rnd in range(6):
        state = planner.step(state)
        state = coder.step(state)
        state = tester.step(state)
        if state.tests_passed: break
    return {"result": state.result, "rounds": rnd + 1}
```

## 17. AKS Example
Deploy each agent role as its own Deployment/service in AKS; scale independently with HPA; coordinate via Service Bus/Redis; a supervisor service enforces global budgets.

## 18. How to Remember
**"A team of specialists with a manager."** Each agent = an expert; the supervisor keeps them on task and on budget.

## 19. Real-World Analogy
A film crew: director (supervisor), writer, cinematographer, editor — specialists collaborating, with the director deciding when the scene is done.

## 20. One-Page Cheat Sheet
- **What**: multiple specialized agents collaborating on a task.
- **Topologies**: supervisor–worker, pipeline, group-chat/debate, hierarchical.
- **Frameworks**: AutoGen, SK Agent Framework, LangGraph, CrewAI, Magentic-One.
- **Control**: global budgets, termination, single-writer state, human gates.
- **Debug**: correlation IDs + transcripts + per-role eval.
- **Rule**: only go multi-agent when the task genuinely decomposes.
