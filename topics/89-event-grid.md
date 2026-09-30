# 89 · Azure Event Grid

> Domain: Integration & Messaging · Level: Principal Integration Architect

## 1. Beginner Explanation
Azure Event Grid is a **reactive event-routing service**. When something happens (a file is uploaded, a resource is created), Event Grid delivers a lightweight notification to whatever code should react — connecting event producers to subscribers without polling.

## 2. Architect-Level Explanation
A serverless, push-based pub-sub event router for reactive architectures:
- **Model**: **event sources** publish to **topics**; **event subscriptions** route (with filters) to **handlers** (Functions, Logic Apps, Webhooks, Service Bus, Event Hubs, storage queues).
- **Event vs data**: carries lightweight **event notifications** ("something happened" + metadata/reference), not the full payload/stream — small, discrete events.
- **Topic types**: **system topics** (Azure resource events — Blob created, resource changes), **custom topics** (your app events), **partner topics**, **domains** (multi-tenant fan-out at scale).
- **Delivery**: push with **retry + exponential backoff** and **dead-lettering** (to storage) on repeated failure; at-least-once.
- **MQTT / Event Grid namespaces**: newer namespace model adds MQTT broker + pull delivery for IoT.
- **Scale**: millions of events, near-real-time, low latency; serverless (no infra).
- **CloudEvents** schema support (interop standard).
- **Use for**: reactive glue, "when X happens do Y", eventing across Azure — not high-throughput streaming (Event Hub) or ordered commands (Service Bus).

## 3. Real Enterprise Use Case
When images land in Blob Storage, a **system topic** emits `BlobCreated`; an Event Grid subscription (filtered to a container/suffix) triggers an Azure Function to generate thumbnails and a Logic App to notify downstream systems. Failed deliveries dead-letter to a storage account for replay — fully serverless, reactive, no polling.

## 4. Architecture Diagram (ASCII)
```
   Event Sources ─► Event Grid Topic ─► Event Subscriptions (filters)
   ┌───────────────┐   (system/custom/    ┌──────────────────────────┐
   Blob/Resource    │    partner/domain)   ├─► Azure Function
   Custom app event │                      ├─► Logic App
   IoT (MQTT ns)    │                      ├─► Webhook / Service Bus / Event Hub
   push + retry/backoff ─► dead-letter (storage) on failure
   Lightweight notifications (not the full data stream)
```

## 5. Interview Questions
1. What is Event Grid and its model?
2. Event Grid vs Event Hub vs Service Bus?
3. System vs custom vs partner topics/domains?
4. How does delivery reliability work (retry/dead-letter)?
5. When would you choose Event Grid?

## 6. Strong Interview Answers
- **Model**: "Push-based pub-sub — sources publish events to topics, and event subscriptions with filters route them to handlers like Functions or Webhooks. It's serverless reactive glue: 'when X happens, trigger Y'."
- **Grid vs Hub vs Bus**: "Event Grid routes discrete reactive **event notifications** (small, 'something happened'). Event Hub ingests high-throughput **streams/telemetry** (millions/sec, replayable). Service Bus is enterprise **messaging/commands** with ordering, transactions, DLQ. Different jobs — notifications vs streaming vs reliable commands."
- **Topic types**: "**System topics** for built-in Azure resource events (Blob created, resource group changes); **custom topics** for my application's events; **partner topics** for SaaS integrations; **domains** for large-scale multi-tenant fan-out with per-tenant topics managed together."
- **Reliability**: "Push delivery with retries and exponential backoff; if a handler keeps failing (or events expire), Event Grid dead-letters them to a storage account so nothing is silently lost. Delivery is at-least-once, so handlers should be idempotent."
- **When**: "For reactive, event-driven integration across Azure services and apps — automating reactions to resource/app events with minimal code. Not for ordered command processing (Service Bus) or big data streaming (Event Hub)."

## 7. Common Mistakes
- Using Event Grid for high-volume streaming (that's Event Hub).
- Expecting the full data payload (it carries notifications/references).
- Non-idempotent handlers (at-least-once delivery).
- No dead-letter destination → lost failed events.
- No event filtering → handlers flooded with irrelevant events.

## 8. Trade-offs
| Service | Best for | Not for |
|---------|----------|---------|
| Event Grid | reactive notifications | streaming/ordered commands |
| Event Hub | high-throughput streams | discrete reactions |
| Service Bus | ordered commands/workflows | massive fan-out eventing |

## 9. Production Best Practices
- Filter subscriptions (subject/event type) to reduce noise.
- Configure dead-lettering + retry policy; monitor DLQ.
- Idempotent handlers; validate event schema (CloudEvents).
- Use domains for multi-tenant fan-out at scale.
- Managed Identity + private endpoints (namespaces); least privilege.

## 10. Security Considerations
- Entra ID / Managed Identity; webhook validation handshake.
- Private endpoints (Event Grid namespaces); RBAC on topics.
- Validate/authenticate handlers; verify event source.
- Don't put sensitive data in event payloads (use references).

## 11. Cost Optimization
- Pay-per-operation (very cheap for notifications).
- Filtering avoids paying to deliver irrelevant events.
- Serverless — no idle infra cost.

## 12. Troubleshooting Scenarios
- **Events not delivered** → subscription filter too strict / handler validation handshake failed.
- **Dead-lettered events** → handler errors/timeouts; inspect DLQ storage.
- **Duplicate handling** → at-least-once; add idempotency.
- **Webhook rejected** → missing subscription validation response.
- **Wrong events** → filter by event type/subject.

## 13. Hands-on Example
```bash
az eventgrid event-subscription create --name blob-thumbnails \
  --source-resource-id $STORAGE_ID \
  --endpoint $FUNCTION_ENDPOINT --endpoint-type azurefunction \
  --subject-ends-with .jpg --deadletter-endpoint $DLQ_STORAGE
```

## 14. Terraform Example
```hcl
resource "azurerm_eventgrid_system_topic" "blob" {
  name = "blob-events" resource_group_name = var.rg location = "eastus"
  source_arm_resource_id = azurerm_storage_account.imgs.id
  topic_type = "Microsoft.Storage.StorageAccounts"
}
resource "azurerm_eventgrid_system_topic_event_subscription" "thumb" {
  name = "thumbnails" system_topic = azurerm_eventgrid_system_topic.blob.name
  resource_group_name = var.rg
  azure_function_endpoint { function_id = var.fn_id }
  subject_filter { subject_ends_with = ".jpg" }
  dead_letter_identity { type = "SystemAssigned" }
}
```

## 15. Azure Example
Event Grid **namespaces** add an MQTT broker + pull delivery for IoT scenarios — devices publish over MQTT, and backend consumers pull events, combining IoT ingestion with Event Grid routing under private endpoints.

## 16. FastAPI / Python Example
```python
# Webhook handler: respond to Event Grid validation + process events (idempotent)
@app.post("/events")
async def events(payload: list[dict]):
    for e in payload:
        if e.get("eventType") == "Microsoft.EventGrid.SubscriptionValidationEvent":
            return {"validationResponse": e["data"]["validationCode"]}  # handshake
        if not already_handled(e["id"]):           # at-least-once → idempotent
            await react_to(e)
    return {"status": "ok"}
```

## 17. AKS Example
Event Grid pushes `BlobCreated` events to an AKS-hosted webhook (via internal ingress) or into a Service Bus queue that KEDA-scaled AKS consumers drain. Dead-lettering to storage protects against handler downtime during cluster upgrades.

## 18. How to Remember
**"Reactive router: source → topic → filtered subscription → handler."** Notifications (not streams), push + retry + dead-letter. Grid=react, Hub=stream, Bus=command.

## 19. Real-World Analogy
A smart building alarm system: when a sensor trips (event), it instantly notifies exactly the right responders (filtered subscriptions) — fire dept, security — rather than everyone constantly checking every sensor (polling). It only sends the alert, not the whole camera feed (notification, not stream).

## 20. One-Page Cheat Sheet
- **What**: serverless push-based pub-sub event router for reactive architectures.
- **Model**: sources → topics → filtered event subscriptions → handlers (Functions/Logic Apps/Webhooks/Service Bus).
- **Topics**: system (Azure resource events), custom (app), partner, domains (multi-tenant fan-out).
- **Reliability**: push + retry/backoff + dead-letter (storage); at-least-once → idempotent handlers.
- **Carries**: lightweight notifications (not full data/streams); CloudEvents; MQTT via namespaces.
- **vs**: Event Hub (streaming), Service Bus (ordered commands). Filter to reduce noise/cost.
