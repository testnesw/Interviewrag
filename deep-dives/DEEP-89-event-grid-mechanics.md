# DEEP MECHANICS · Azure Event Grid

> Level 2 — reactive event routing, push delivery, schemas, filtering, and
> retry/dead-letter.

---

## 0. The precise mental model
Event Grid is a **fully managed, serverless event router** for **reactive, discrete events** ("something happened"). Publishers send events to **topics**; Event Grid **pushes** them to **subscribers** based on **filters**, at massive fan-out and near-real-time, with **retry + dead-lettering**. It's lightweight notification routing — *not* a stream (Event Hubs) or a durable queue (Service Bus).

---

## 1. Model
```
Publisher → Topic → (filters) → Event Subscription → Handler
```
- **System topics**: Azure services emit events (Blob created, resource changed).
- **Custom topics**: your app publishes events.
- **Domains**: many topics under one endpoint (multi-tenant fan-out).
- **Event Subscription** = routing rule + destination + filter.

## 2. Push delivery (vs pull)
- Event Grid **pushes** to handlers: Functions, Logic Apps, Webhooks, Event Hubs, Service Bus, Storage Queues.
- Webhook handlers must pass **validation handshake** (prove ownership).
- (Event Grid also now offers **MQTT + pull** namespaces, but classic model is push.)

## 3. Schemas
- **Event Grid schema** or **CloudEvents 1.0** (CNCF standard — interoperable).
- Event = metadata (id, type, subject, time) + small `data` payload. Events are **small notifications**, not big payloads (fetch details from source if needed).

## 4. Filtering
- **Subject** prefix/suffix filters, **event type** filters, and **advanced filters** (on data fields) → subscribers only get relevant events → reduces noise + handler load.

## 5. Reliability
- **At-least-once** delivery → idempotent handlers.
- **Retry** with exponential backoff + jitter over up to 24h (configurable TTL).
- **Dead-letter** to Storage for undeliverable events.
- High throughput + low latency; **fan-out** to many subscribers.

## 6. Event Grid vs Event Hubs vs Service Bus
| | Event Grid | Event Hubs | Service Bus |
|---|---|---|---|
| Purpose | reactive **events** | **streaming** telemetry | enterprise **messaging** |
| Model | push, fan-out | pull, partitions | queue/topic, pull |
| Payload | small notification | high-volume stream | command/message |
| Ordering | no | per partition | sessions |
- **Event Grid**: "react to discrete events." **Event Hubs**: "ingest millions of events/sec." **Service Bus**: "reliable ordered commands/txn."

## 7. The hard follow-ups (with answers)
1. **"What's Event Grid for?"** → routing **discrete reactive events** with filtered push fan-out. (§0)
2. **"Push or pull?"** → **push** (with webhook validation handshake); newer MQTT/pull option exists. (§2)
3. **"Only get certain events?"** → subject/type/**advanced filters** per subscription. (§4)
4. **"Delivery guarantee + failures?"** → at-least-once, retry w/ backoff up to 24h, **dead-letter** to Storage. (§5)
5. **"CloudEvents?"** → standardized CNCF event format for interop. (§3)
6. **"vs Event Hubs vs Service Bus?"** → events/react vs streaming/ingest vs messaging/order-txn. (§6)

## 8. One-screen recall
- **Serverless event router**: reactive **discrete events**, filtered **push** fan-out.
- **Topics** (system/custom/domain) → **event subscriptions** (filter + destination).
- **Push** to Functions/Logic Apps/Webhooks/Event Hubs/Service Bus; webhook **validation handshake**.
- **Schema**: Event Grid or **CloudEvents**; small notification payloads.
- **Filter**: subject/type/advanced (on data).
- **Reliability**: at-least-once (idempotent), retry ≤24h, **dead-letter** to Storage.
- **vs**: Event Hubs (streaming), Service Bus (ordered/txn messaging).

> Next: Event Hubs.
