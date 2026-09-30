# 88 · Azure Service Bus

> Domain: Integration & Messaging · Level: Principal Integration Architect

## 1. Beginner Explanation
Azure Service Bus is an **enterprise message broker**. It lets applications communicate by sending messages to queues or topics, so a sender and receiver don't have to be online at the same time — reliable, decoupled communication.

## 2. Architect-Level Explanation
A fully managed enterprise message broker for reliable async messaging:
- **Queues**: point-to-point (competing consumers); **Topics/Subscriptions**: publish-subscribe with per-subscription filters (rules).
- **Guarantees**: at-least-once (default) with **duplicate detection**; **sessions** for ordered/FIFO + stateful processing; **transactions** across entities.
- **Reliability features**: **dead-letter queue (DLQ)**, message deferral, scheduled messages, TTL, auto-forwarding, peek-lock vs receive-and-delete.
- **Delivery model**: **PeekLock** (lock → process → complete/abandon/dead-letter) enables safe at-least-once; **max delivery count** → DLQ.
- **Tiers**: Standard (shared, pay-per-op) vs **Premium** (dedicated capacity, predictable latency, VNet/private endpoint, larger messages, geo-DR).
- **Security**: Entra ID + RBAC / Managed Identity, private endpoints.
- **Use for**: commands, workflows, order processing — where you need ordering, transactions, DLQ, and rich enterprise semantics (vs Event Grid/Event Hub).

## 3. Real Enterprise Use Case
An order system publishes `OrderPlaced` to a Service Bus **topic**; subscriptions with filters route to inventory, billing, and shipping consumers independently. **Sessions** guarantee per-customer ordering, PeekLock + max-delivery routes poison messages to the **DLQ** for investigation, and Premium tier with private endpoints meets latency + compliance requirements.

## 4. Architecture Diagram (ASCII)
```
   Producer ─► Topic (OrderPlaced)
                 ├─[filter: region=EU]─► Sub: inventory ─► consumers (competing)
                 ├─[filter: type=B2B ]─► Sub: billing
                 └─────────────────────► Sub: shipping
   Queue (point-to-point): Producer ─► [PeekLock] ─► competing consumers
   PeekLock: lock→complete/abandon/deadletter | maxDelivery → DLQ
   Sessions = FIFO/ordered | Duplicate detection | Premium=VNet+geo-DR
```

## 5. Interview Questions
1. Queue vs topic/subscription?
2. How does PeekLock enable at-least-once safely?
3. What are sessions and when do you need them?
4. What is the dead-letter queue?
5. Service Bus vs Event Grid vs Event Hub?

## 6. Strong Interview Answers
- **Queue vs topic**: "A queue is point-to-point — competing consumers each take different messages. A topic is pub-sub — every subscription gets a copy (filtered by rules), so multiple independent consumers react to the same event."
- **PeekLock**: "The consumer locks a message (invisible to others), processes it, then completes it (removed) or abandons/dead-letters it. If it crashes, the lock expires and the message reappears — giving at-least-once delivery, so handlers must be idempotent. Repeated failures past max-delivery go to the DLQ."
- **Sessions**: "Sessions group related messages (by SessionId) and guarantee ordered, single-consumer processing per session — needed for FIFO or stateful workflows like per-order or per-customer sequencing. Without sessions, queues don't guarantee strict ordering under concurrency."
- **DLQ**: "A sub-queue for messages that can't be processed — exceeded max delivery, expired TTL, or explicitly dead-lettered. It isolates poison messages so the main flow keeps moving, and I monitor/replay the DLQ."
- **SB vs Event Grid vs Event Hub**: "Service Bus = enterprise messaging (commands/workflows, ordering, transactions, DLQ). Event Grid = lightweight reactive event routing (pub-sub notifications). Event Hub = high-throughput streaming/telemetry ingestion (millions/sec). I pick by semantics: reliable commands → Service Bus, event notifications → Event Grid, streaming → Event Hub."

## 7. Common Mistakes
- Non-idempotent consumers with at-least-once delivery.
- Using ReceiveAndDelete (message loss on crash) instead of PeekLock.
- Ignoring the DLQ (poison messages pile up silently).
- Expecting FIFO without sessions.
- Using Service Bus for high-volume streaming (use Event Hub).

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| PeekLock | safe, at-least-once | needs idempotency, lock mgmt |
| Sessions | ordering | throughput per session |
| Premium | VNet, low latency | higher cost |

## 9. Production Best Practices
- PeekLock + idempotent handlers; tune lock duration/max delivery.
- Topics + filters for pub-sub routing; sessions for ordering.
- Monitor + auto-replay DLQ; duplicate detection where needed.
- Premium + private endpoints for prod/compliance; geo-DR.
- Managed Identity + RBAC (no connection-string secrets).

## 10. Security Considerations
- Entra ID + RBAC / Managed Identity instead of SAS keys.
- Private endpoints (Premium); no public exposure.
- Least-privilege (send vs listen) per app.
- Encrypt sensitive payloads; audit access.

## 11. Cost Optimization
- Standard for low/variable volume; Premium for steady high throughput/latency SLA.
- Right-size Premium messaging units.
- Batch send/receive; prefetch to reduce round-trips.

## 12. Troubleshooting Scenarios
- **Messages reprocessed** → non-idempotent handler + lock expiry/crash.
- **Growing DLQ** → poison messages / downstream failures; inspect + replay.
- **Out-of-order** → no sessions; enable sessions.
- **Lock lost / MessageLockLost** → processing exceeds lock duration; renew or extend.
- **Throttling** → Standard limits; move to Premium / batch.

## 13. Hands-on Example
```bash
az servicebus queue create -g rg --namespace-name sb-prod -n orders \
  --enable-session true --max-delivery-count 5 --enable-dead-lettering-on-message-expiration true
```

## 14. Terraform Example
```hcl
resource "azurerm_servicebus_namespace" "sb" {
  name = "sb-prod" resource_group_name = var.rg location = "eastus"
  sku = "Premium" capacity = 1
}
resource "azurerm_servicebus_topic" "orders" {
  name = "order-placed" namespace_id = azurerm_servicebus_namespace.sb.id
  requires_duplicate_detection = true
}
resource "azurerm_servicebus_subscription" "inventory" {
  name = "inventory" topic_id = azurerm_servicebus_topic.orders.id
  max_delivery_count = 5 dead_lettering_on_message_expiration = true
}
```

## 15. Azure Example
```bash
# KEDA scales AKS consumers on Service Bus queue depth (scale-to-zero when empty)
az aks update -g rg-aks -n prod-aks --enable-keda
```

## 16. FastAPI / Python Example
```python
from azure.servicebus.aio import ServiceBusClient
from azure.identity.aio import DefaultAzureCredential

async def consume():
    async with ServiceBusClient("sb-prod.servicebus.windows.net",
                                DefaultAzureCredential()) as client:   # Managed Identity
        receiver = client.get_queue_receiver("orders", max_wait_time=5)
        async with receiver:
            async for msg in receiver:                 # PeekLock
                try:
                    await handle(str(msg))
                    await receiver.complete_message(msg)     # done
                except Exception:
                    await receiver.abandon_message(msg)      # retry → eventually DLQ
```

## 17. AKS Example
AKS consumer Deployment scales via **KEDA** `azure-servicebus` trigger on queue depth (min 0 → max N). Workload Identity authenticates to Service Bus (no secrets); PeekLock + idempotency handle at-least-once safely; poison messages land in the DLQ for a separate replay job.

## 18. How to Remember
**"Queues = point-to-point; Topics = pub-sub; PeekLock + idempotent; Sessions = FIFO; DLQ = poison."** Commands/workflows, not streaming.

## 19. Real-World Analogy
A reliable postal system with certified mail: letters wait safely in a P.O. box (queue) until you collect them (PeekLock), you sign to confirm receipt (complete), undeliverable mail goes to a returns office (DLQ), and a topic is like a subscription magazine where every subscriber gets their own copy.

## 20. One-Page Cheat Sheet
- **What**: enterprise message broker for reliable async messaging (commands/workflows).
- **Queues** (point-to-point) vs **Topics/Subscriptions** (pub-sub + filters).
- **PeekLock**: lock→complete/abandon/dead-letter → safe at-least-once (idempotent handlers).
- **Sessions**: FIFO/ordered; **DLQ**: poison messages; duplicate detection; scheduled/deferral/TTL.
- **Premium**: VNet/private endpoint, low latency, geo-DR; Entra ID + Managed Identity.
- **vs**: Event Grid (event routing), Event Hub (streaming); scale consumers with KEDA.
