# 14 · Function Calling

> Domain: Generative AI & Azure AI · Level: Principal GenAI Architect

## 1. Beginner Explanation
Function calling lets an LLM **call your code**. You describe functions (name, params); the model decides which to call and returns structured arguments; your app runs it and feeds the result back.

## 2. Architect-Level Explanation
A structured-output mechanism for tool use:
- **Flow**: you pass tool schemas → model returns a `tool_call` (name + JSON args) → your app executes → append result as a `tool` message → model produces final answer.
- **Parallel tool calls**: model can request multiple functions at once.
- **Structured outputs**: JSON-schema-constrained results guarantee valid, parseable args.
- Foundation for **agents, RAG tools, and MCP**. Architect concerns: arg validation (injection), idempotency, error handling, and cost of multi-turn loops.

## 3. Real Enterprise Use Case
A banking assistant exposes `get_balance`, `transfer_funds`, `find_transactions`. The model maps natural language to the right function with typed args; the app validates and executes (with approval for transfers), then the model explains results — no brittle intent parsing.

## 4. Architecture Diagram (ASCII)
```
 User ─► LLM  (+ tool schemas)
            │  tool_call{name,args(JSON)}
            ▼
     App validates args ─► execute function ─► result
            │                                    │
            └──────── result appended ◄──────────┘
            ▼
        LLM ─► final grounded answer
```

## 5. Interview Questions
1. How does function calling actually work end-to-end?
2. Function calling vs structured outputs?
3. How do you handle unsafe/invalid arguments?
4. Parallel vs sequential tool calls?
5. How does this relate to agents and MCP?

## 6. Strong Interview Answers
- **Flow**: "I send tool JSON schemas; the model returns which tool and typed args; I validate and execute, append the result, and the model finalizes. It's a loop, not one shot."
- **vs structured outputs**: "Structured outputs guarantee the *format* (valid JSON to a schema); function calling adds *tool selection*. Combine them — schema-constrained function args are the most reliable."
- **Safety**: "Never trust model args — validate types/ranges, enforce authz, use allow-lists, and require human approval for irreversible actions. The model suggests; the app decides."
- **Parallel**: "Parallel calls cut latency for independent tools; sequential when one output feeds the next. Cap total calls."
- **Agents/MCP**: "Function calling is the primitive; agents wrap it in a loop; MCP standardizes and externalizes the tools across apps."

## 7. Common Mistakes
- Executing model args without validation/authz.
- Vague function descriptions → wrong tool choice.
- No error path back to the model.
- Unbounded tool-call loops (cost).

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Auto tool choice | flexible | less predictable |
| Forced/required tool | deterministic | rigid |
| Parallel calls | faster | harder to reason/debug |

## 9. Production Best Practices
- Schema-constrained args + server-side validation.
- Clear, specific function descriptions and param docs.
- Idempotent functions; return structured errors to the model.
- Cap iterations; log every tool call.
- Human approval for high-impact actions.

## 10. Security Considerations
- Validate/sanitize all args (injection via user or retrieved text).
- Least-privilege on what each function can do.
- Authz checks bound to the real user, not the model.
- Audit trail of all invocations.

## 11. Cost Optimization
- Fewer, well-scoped tools (less token overhead).
- Smaller model for tool routing.
- Cache tool results; cap tool-call rounds.

## 12. Troubleshooting Scenarios
- **Model won't call tool** → improve descriptions/schemas, set tool_choice.
- **Bad args** → tighten JSON schema + validation, use structured outputs.
- **Loop won't end** → iteration cap + final-answer detection.
- **Wrong tool** → disambiguate names/descriptions.

## 13. Hands-on Example (OpenAI SDK)
```python
tools = [{"type":"function","function":{
  "name":"get_balance","description":"Get account balance",
  "parameters":{"type":"object","properties":{"account_id":{"type":"string"}},
  "required":["account_id"]}}}]
r = client.chat.completions.create(model="gpt-4o", tools=tools,
    messages=[{"role":"user","content":"What's my balance for A123?"}])
call = r.choices[0].message.tool_calls[0]   # name + JSON args
```

## 14. Terraform Example
```hcl
# The functions often live in Azure Functions the LLM app calls
resource "azurerm_linux_function_app" "tools" {
  name = "llm-tools" resource_group_name = azurerm_resource_group.rg.name
  location = "eastus" service_plan_id = azurerm_service_plan.plan.id
  storage_account_name = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  identity { type = "SystemAssigned" }
  site_config {}
}
```

## 15. Azure Example
Expose tools as Azure Functions secured by Managed Identity; the AOAI app validates args then invokes them; log tool calls to App Insights.

## 16. FastAPI / Python Example
```python
import json
TOOLS = {"get_balance": get_balance}

@app.post("/chat")
def chat(msg: str):
    r = client.chat.completions.create(model="gpt-4o", tools=tools,
        messages=[{"role": "user", "content": msg}])
    tc = r.choices[0].message.tool_calls
    if tc:
        args = validate(json.loads(tc[0].function.arguments))  # validate!
        result = TOOLS[tc[0].function.name](**args)
        return {"result": result}
    return {"answer": r.choices[0].message.content}
```

## 17. AKS Example
Tool endpoints run as microservices in AKS; the LLM gateway validates args and calls them via internal services with Workload Identity; HPA scales hot tools.

## 18. How to Remember
**"The model asks, your code acts."** It picks the function and fills the form; you check and execute it.

## 19. Real-World Analogy
A smart receptionist who fills out the right request form (function + fields) and hands it to the right department — but the department still verifies and processes it.

## 20. One-Page Cheat Sheet
- **What**: LLM selects a function and returns typed JSON args; app executes.
- **Loop**: schemas → tool_call → validate → execute → result → final answer.
- **Reliable**: structured outputs + schema + server-side validation.
- **Safe**: never trust args; authz to real user; approval for risky actions.
- **Scales into**: agents (loop) and MCP (standardized tools).
- **Cost**: few scoped tools, small router model, cap rounds.
