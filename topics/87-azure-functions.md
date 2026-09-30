# 87 · Azure Functions

> Domain: Integration & Messaging · Level: Principal Integration Architect

## 1. Beginner Explanation
Azure Functions is **serverless compute** — you write small pieces of code (functions) that run in response to events (an HTTP request, a queue message, a timer) without managing servers. You pay only for what runs.

## 2. Architect-Level Explanation
Event-driven, serverless Functions-as-a-Service:
- **Triggers + bindings**: one **trigger** per function (HTTP, Timer, Queue/Service Bus, Event Grid, Event Hub, Blob, Cosmos DB change feed) + declarative **input/output bindings** (reduce boilerplate to connect services).
- **Hosting plans**: **Consumption** (scale-to-zero, per-execution billing, cold starts), **Premium** (pre-warmed instances, VNet, no cold start, longer runs), **Flex Consumption** (fast elastic + VNet, modern default), **Dedicated/ASE** (predictable/isolated), **Container Apps** hosting.
- **Scaling**: event-driven auto-scale; Consumption/Flex scale on load, Premium keeps warm instances.
- **Durable Functions**: stateful orchestrations (chaining, fan-out/fan-in, human interaction, sagas) on top of stateless functions.
- **Best for**: event processing, glue/integration, lightweight APIs, scheduled jobs, async back-ends.
- **Constraints**: execution time limits (Consumption), cold starts, statelessness — use Premium/Flex + Durable for heavier/stateful needs.
- **Security**: Managed Identity, Key Vault references, private endpoints, Entra ID auth (Easy Auth).

## 3. Real Enterprise Use Case
An order pipeline uses Functions: a Service Bus-triggered function processes orders, an Event Grid-triggered function reacts to blob uploads for image processing, a Timer function runs nightly reconciliation, and a **Durable Functions** orchestration coordinates a multi-step fulfillment saga — all scaling to zero when idle on Flex Consumption with VNet + Managed Identity.

## 4. Architecture Diagram (ASCII)
```
   Events ─► Trigger ─► Function (stateless) ─► Output binding ─► Service
   ┌─────────────┬───────────────┬──────────────┬──────────────┐
   HTTP        Timer          Service Bus     Event Grid     Blob/Cosmos
   │                                                            │
   Bindings (in/out) auto-connect to Storage/DB/Queue (less code)
   Durable Functions: orchestrator ─► fan-out/fan-in, saga, chaining
   Plan: Consumption (scale-to-0) | Premium/Flex (warm + VNet)
```

## 5. Interview Questions
1. What are triggers and bindings?
2. Compare the hosting plans.
3. How do you handle cold starts?
4. What are Durable Functions for?
5. When would you NOT use Functions?

## 6. Strong Interview Answers
- **Triggers/bindings**: "Each function has exactly one trigger (what invokes it — HTTP, queue, timer, event). Bindings declaratively connect inputs/outputs (read from Blob, write to Cosmos) without SDK boilerplate — the platform handles the plumbing."
- **Plans**: "Consumption scales to zero with per-execution billing but has cold starts and time limits; Premium keeps pre-warmed instances with VNet and longer runs; **Flex Consumption** is the modern elastic option with fast scale + VNet + scale-to-zero; Dedicated/ASE for predictable or isolated workloads. I default to Flex for most event-driven work, Premium when I need always-warm."
- **Cold starts**: "Use Premium/Flex with pre-warmed or always-ready instances, keep dependencies light, and avoid heavy init. For latency-sensitive HTTP I'd pick Premium/Flex over Consumption."
- **Durable**: "Durable Functions add stateful orchestration on stateless functions — patterns like function chaining, fan-out/fan-in, async HTTP, human-in-the-loop, and sagas — with checkpointed state, so I can build long-running workflows without managing state myself."
- **Not use**: "Long-running CPU-heavy jobs, workloads needing fine-grained control or steady high throughput (a container/AKS service may be cheaper), or when cold-start latency is unacceptable and always-on is needed — though Premium mitigates that."

## 7. Common Mistakes
- Consumption plan for latency-sensitive APIs (cold starts).
- Long-running/CPU-heavy work in Functions (time limits/cost).
- Storing state in a stateless function (use Durable/DB).
- Secrets in app settings instead of Key Vault references/MI.
- Ignoring concurrency/host scaling settings → downstream overload.

## 8. Trade-offs
| Plan | Pro | Con |
|------|-----|-----|
| Consumption | scale-to-0, cheap idle | cold starts, limits |
| Premium | warm, VNet, long runs | higher fixed cost |
| Flex | elastic + VNet + scale-to-0 | newer |

## 9. Production Best Practices
- Flex/Premium for VNet + reduced cold starts.
- One responsibility per function; idempotent handlers (retries/at-least-once).
- Managed Identity + Key Vault references; private endpoints.
- Durable Functions for orchestration/sagas.
- Tune host concurrency; App Insights monitoring; dead-letter handling.

## 10. Security Considerations
- Managed Identity to Azure services (no secrets).
- Key Vault references for config; private endpoints/VNet.
- Entra ID auth (Easy Auth) or APIM in front for HTTP.
- Validate input; least-privilege bindings/roles.

## 11. Cost Optimization
- Scale-to-zero (Consumption/Flex) for spiky/low-volume.
- Right plan: don't over-provision Premium for light loads.
- Efficient code (less execution time = less cost); batch where possible.

## 12. Troubleshooting Scenarios
- **Cold-start latency** → move to Premium/Flex; trim deps.
- **Timeouts** → exceeds plan limit; use Durable/split work.
- **Messages reprocessed** → non-idempotent handler + at-least-once delivery.
- **Can't reach private resource** → need VNet (Premium/Flex) + private endpoint.
- **Throttled downstream** → host concurrency too high; add limits.

## 13. Hands-on Example
```bash
func init orderfn --python && cd orderfn
func new --name ProcessOrder --template "Azure Service Bus Queue trigger"
func start
```

## 14. Terraform Example
```hcl
resource "azurerm_function_app_flex_consumption" "fn" {
  name = "orders-fn" resource_group_name = var.rg location = "eastus"
  service_plan_id = azurerm_service_plan.flex.id
  storage_account_name = azurerm_storage_account.fn.name
  runtime_name = "python" runtime_version = "3.12"
  identity { type = "SystemAssigned" }        # Managed Identity
}
```

## 15. Azure Example
```bash
az functionapp create -g rg -n orders-fn --flexconsumption-location eastus \
  --runtime python --runtime-version 3.12 --storage-account stfn --assign-identity
```

## 16. FastAPI / Python Example
```python
# Azure Functions (Python v2 model) — Service Bus trigger, idempotent
import azure.functions as func
app = func.FunctionApp()

@app.service_bus_queue_trigger(arg_name="msg", queue_name="orders",
                               connection="SB_CONN")
def process_order(msg: func.ServiceBusMessage):
    order = msg.get_body().decode()
    if already_processed(msg.message_id):   # idempotency (at-least-once delivery)
        return
    handle(order)
```

## 17. AKS Example
For teams standardizing on Kubernetes, host Functions on **Azure Container Apps** or run the Functions runtime in AKS with **KEDA** scaling on the same triggers (Service Bus queue depth) — unifying serverless event processing with the container platform and scaling to zero.

## 18. How to Remember
**"One trigger + bindings; scale-to-zero; Durable for stateful; Flex/Premium for VNet + no cold start."**

## 19. Real-World Analogy
Motion-sensor lights: they stay off (scale-to-zero, no cost) until someone walks by (an event), instantly switch on to do their job, then turn off again. Durable Functions are like a guided tour where the lights turn on in sequence, remembering which room you're in.

## 20. One-Page Cheat Sheet
- **What**: event-driven serverless FaaS; one **trigger** + declarative **bindings** per function.
- **Triggers**: HTTP, Timer, Service Bus/Queue, Event Grid/Hub, Blob, Cosmos change feed.
- **Plans**: Consumption (scale-to-0, cold starts), Premium (warm+VNet), **Flex** (elastic+VNet+scale-to-0), Dedicated/ASE.
- **Durable Functions**: stateful orchestration (chaining, fan-out/in, saga).
- **Secure**: Managed Identity + Key Vault refs + private endpoints; idempotent handlers.
- **Avoid**: long CPU-heavy jobs, latency-sensitive on Consumption, state in stateless funcs.
