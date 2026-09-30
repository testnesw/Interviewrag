# DEEP MECHANICS · Function / Tool Calling

> Level 2 — the exact request/response protocol, how the model decides, JSON
> schema, parallel calls, the execution loop, and error/validation handling.

---

## 0. The precise mental model
Function calling lets an LLM **request that your code run a function** by emitting a **structured JSON call** (name + arguments) instead of prose. The model **never executes anything** — it only *decides which function to call and with what args*, matching the user's intent to the **JSON schemas** you provide. Your app executes, returns the result, and the model continues. It's the bridge from "text generator" to "system that acts."

---

## 1. The protocol — step by step
```
1. You send: messages + tools=[{name, description, parameters(JSON Schema)}]
2. Model returns: either a normal message OR tool_calls=[{name, arguments(JSON)}]
3. You: parse args → VALIDATE → execute the real function
4. You append the result as a tool message and call the model again
5. Model uses the result to produce the final answer (or more tool_calls)
```
The **description** and **parameter schema** are effectively prompt — the model reads them to decide when/how to call. Good descriptions = good tool selection.

## 2. The JSON Schema contract
Each tool declares typed parameters:
```json
{"name":"get_weather",
 "description":"Get current weather for a city",
 "parameters":{"type":"object",
   "properties":{"city":{"type":"string"},"unit":{"enum":["C","F"]}},
   "required":["city"]}}
```
The model returns arguments conforming to this. **Strict/structured mode** (constrained decoding) guarantees schema-valid JSON — otherwise you must validate & handle malformed output.

## 3. Tool choice control
- **auto** — model decides whether to call a tool or answer directly (default).
- **required** — must call some tool.
- **none** — never call.
- **named** — force a specific tool.
Use `required`/named when you know a tool is needed (e.g., always retrieve before answering).

## 4. Parallel tool calls
Modern models can return **multiple tool_calls in one response** (e.g., weather for 3 cities). You execute them (often concurrently) and return all results. Reduces round-trips/latency.

## 5. The execution loop = agents
Chaining "model → tool_call → execute → feed back → model" in a loop **is** an agent (ReAct). Bound it with a **max-iterations** cap to prevent runaway loops. This is what Semantic Kernel's auto-invocation and LangChain agents automate.

## 6. Validation, errors & safety
- **Always validate arguments** before executing (never trust model JSON blindly — types, ranges, injection).
- **Return errors as tool results** ("error: city not found") so the model can recover/retry rather than crashing.
- **Least privilege** — the function itself enforces authorization; the model choosing to call it doesn't mean it's allowed. Critical against prompt injection tricking the model into a dangerous call.
- **Idempotency** for actions that might be retried.

## 7. The hard follow-ups (with answers)
1. **"Does the model execute the function?"** → no — it emits a JSON call; your code executes. (§0)
2. **"How does the model know which tool?"** → from the **description + JSON schema** (they're prompt) matched to intent. (§1)
3. **"Guarantee valid arguments?"** → strict/structured mode (constrained decoding) + your own validation. (§2)
4. **"Force or forbid tool use?"** → tool_choice auto/required/none/named. (§3)
5. **"Multiple tools at once?"** → parallel tool_calls in one response, execute concurrently. (§4)
6. **"Model tries a dangerous call via injection — protection?"** → least-privilege authorization in the function itself; validate args; human-in-loop for high-impact. (§6)
7. **"How does this become an agent?"** → loop model↔tool with a max-iteration cap. (§5)

## 8. One-screen recall
- Function calling = model emits **structured JSON (name+args)**; **your code executes**, never the model.
- Protocol: send **tools(JSON Schema)** → model returns **tool_calls** → validate+execute → append result → model continues.
- **Description + schema = prompt** → drive tool selection. **Strict mode** = schema-valid JSON.
- **tool_choice**: auto / required / none / named.
- **Parallel tool_calls** cut round-trips.
- Loop model↔tool (+ **max-iterations**) = **agent** (ReAct).
- Safety: **validate args**, return errors as tool results, **least-privilege authorization in the function**, idempotency.

> Next: AI Guardrails.
