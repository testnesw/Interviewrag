# 91 · Messaging Patterns

> Domain: Integration & Messaging · Level: Principal Integration Architect

## 1. Beginner Explanation
Messaging patterns are proven ways to design how services communicate asynchronously — like publish/subscribe, request/reply, or retrying failed messages. They solve common problems in distributed systems reliably.

## 2. Architect-Level Explanation
A toolbox of async integration patterns (enterprise integration patterns):
- **Point-to-point** (queue, competing consumers) vs **Publish/Subscribe** (topic, fan-out).
- **Request/Reply**: async correlation via reply queue + correlation ID.
- **Competing Consumers**: scale throughput by parallel consumers on a queue.
- **Claim Check**: store large payload externally (Blob), pass a reference in the message.
- **Saga**: manage distributed transactions via a sequence of local transactions + compensations (orchestration vs choreography).
- **Outbox pattern**: atomically persist state + event in the DB, then publish reliably (avoids dual-write inconsistency).
- **Idempotent Consumer**: dedupe by message ID (needed for at-least-once delivery).
- **Dead Letter / Poison message** handling + retry with **exponential backoff**.
- **Message routing / Content-based router / Filter**: route by content (topic filters).
- **Priority, sequencing (sessions/FIFO), scatter-gather, aggregator**.
- **Delivery guarantees**: at-most-once / at-least-once / (effectively) exactly-once via idempotency + dedupe.
- **CQRS/Event Sourcing** (see topics 126/125) build on these.

## 3. Real Enterprise Use Case
An order platform uses the **Outbox pattern** (DB write + event in one transaction, relay publishes to Service Bus), **Saga** orchestration for order→payment→shipping with compensations on failure, **Claim Check** for large document attachments (Blob + reference), **idempotent consumers** for at-least-once safety, and **DLQ + backoff** for poison messages — resilient, consistent distributed workflow.

## 4. Architecture Diagram (ASCII)
```
   Point-to-point:  Producer ─► Queue ─► competing consumers (scale)
   Pub/Sub:         Producer ─► Topic ─► many subscribers (fan-out)
   Outbox:  [DB tx: state + event] ─► relay ─► broker (no dual-write loss)
   Saga:    Order ─► Payment ─► Shipping   (compensate ◄ on failure)
   Claim Check: msg = {ref} ; big payload ─► Blob (fetch by ref)
   Idempotent consumer (dedupe by id) + Retry/backoff + DLQ (poison)
```

## 5. Interview Questions
1. Point-to-point vs pub/sub?
2. What delivery guarantees exist; how do you get "exactly-once"?
3. What problem does the Outbox pattern solve?
4. How do sagas handle distributed transactions?
5. What is the Claim Check pattern?

## 6. Strong Interview Answers
- **P2P vs pub/sub**: "Point-to-point (queue) delivers each message to one consumer among competing consumers — good for work distribution. Pub/sub (topic) fans out a copy to every subscriber — good for broadcasting events to multiple independent reactions."
- **Guarantees**: "At-most-once (may lose), at-least-once (may duplicate — the common default), and exactly-once which is hard end-to-end. I achieve *effectively* exactly-once by combining at-least-once delivery with **idempotent consumers** (dedupe by message ID) so duplicates are harmless."
- **Outbox**: "It fixes the dual-write problem — you can't atomically write to a DB and a broker. Instead I write state and the event to an outbox table in one DB transaction, then a relay reliably publishes from the outbox. No lost or phantom events if the broker or app crashes mid-operation."
- **Saga**: "For transactions spanning services (no distributed 2PC), a saga is a sequence of local transactions, each with a **compensating action** to undo prior steps on failure. Orchestration uses a central coordinator; choreography uses events between services. Choose orchestration for visibility/control, choreography for loose coupling."
- **Claim Check**: "For large payloads, store the data externally (Blob) and put only a reference (the 'claim check') in the message — keeping messages small/fast and within broker size limits, while consumers fetch the payload on demand."

## 7. Common Mistakes
- Dual-writes (DB + broker) without Outbox → inconsistency.
- Assuming exactly-once without idempotency.
- Large payloads in messages (no Claim Check) hitting size limits.
- Distributed 2PC instead of sagas.
- No DLQ/backoff → poison messages block or flood.

## 8. Trade-offs
| Pattern | Pro | Con |
|---------|-----|-----|
| Orchestration saga | visibility/control | central coupling |
| Choreography saga | loose coupling | hard to trace |
| Outbox | consistency | relay/CDC complexity |

## 9. Production Best Practices
- Idempotent consumers (dedupe) for at-least-once.
- Outbox (or CDC/transactional messaging) to avoid dual-write.
- Sagas + compensations for distributed workflows.
- Claim Check for large payloads; DLQ + exponential backoff.
- Correlation IDs + tracing across the message flow.

## 10. Security Considerations
- Least-privilege send/listen; Managed Identity.
- Sensitive data via Claim Check + encrypted storage (not in messages).
- Validate/authenticate message sources; sign where needed.
- Protect DLQ (may contain sensitive poison messages).

## 11. Cost Optimization
- Claim Check keeps messages small (lower broker cost).
- Competing consumers + scale-to-zero (KEDA) match load.
- Batch send/receive; right delivery guarantee (don't over-engineer).

## 12. Troubleshooting Scenarios
- **Lost/phantom events** → dual-write; adopt Outbox.
- **Duplicate side effects** → non-idempotent consumer.
- **Stuck workflow** → saga step failed without compensation.
- **Message too large** → use Claim Check.
- **Poison loop** → missing DLQ/max-delivery/backoff.

## 13. Hands-on Example
```sql
-- Outbox table: written in the same transaction as business state
INSERT INTO orders(id, status) VALUES (@id, 'placed');
INSERT INTO outbox(id, type, payload, published)
VALUES (@evt, 'OrderPlaced', @json, 0);   -- relay publishes rows where published=0
```

## 14. Terraform Example
```hcl
# Topic (pub/sub) + subscription with DLQ for poison-message handling
resource "azurerm_servicebus_subscription" "billing" {
  name = "billing" topic_id = azurerm_servicebus_topic.orders.id
  max_delivery_count = 5                     # → DLQ after retries (backoff)
  dead_lettering_on_message_expiration = true
}
```

## 15. Azure Example
Map patterns to Azure: **Service Bus** (P2P/pub-sub, sessions=FIFO, DLQ), **Event Grid** (reactive routing/filter), **Event Hubs** (streaming), **Blob** (Claim Check store), **Durable Functions** (saga orchestration), **Cosmos/SQL change feed or outbox relay** (Outbox/CDC).

## 16. FastAPI / Python Example
```python
# Idempotent consumer: dedupe by message id (at-least-once → effectively once)
processed: set[str] = set()   # backed by Redis/DB in prod

async def handle(message_id: str, payload: dict):
    if message_id in processed:
        return                 # duplicate → no-op (idempotent)
    await apply(payload)
    processed.add(message_id)
```

## 17. AKS Example
A saga orchestrator (Durable Functions or a stateful service) coordinates AKS microservices via Service Bus: each step publishes a command, consumers (KEDA-scaled) process idempotently, and failures trigger compensating commands. Claim Check offloads large payloads to Blob; DLQ + backoff isolate poison messages.

## 18. How to Remember
**"P2P vs pub/sub; at-least-once + idempotent = effectively once; Outbox stops dual-write; Saga+compensation for distributed tx; Claim Check for big payloads; DLQ+backoff for poison."**

## 19. Real-World Analogy
A well-run logistics network: parcels to one courier (queue) vs flyers to every mailbox (pub/sub); a manifest ensures the warehouse record and shipment always agree (Outbox); a multi-leg delivery that can recall parcels if a leg fails (saga + compensation); and for a huge shipment you send a pickup ticket instead of the crate (Claim Check).

## 20. One-Page Cheat Sheet
- **Topologies**: point-to-point (queue, competing consumers) vs pub/sub (topic, fan-out); request/reply (correlation ID).
- **Guarantees**: at-least-once (default) + **idempotent consumer** (dedupe) ⇒ effectively exactly-once.
- **Consistency**: **Outbox** (avoid dual-write); **Saga** + compensations for distributed transactions (orchestration vs choreography).
- **Payloads**: **Claim Check** (ref in message, data in Blob).
- **Resilience**: DLQ + retry with exponential backoff; correlation IDs + tracing.
- **Azure**: Service Bus (commands), Event Grid (notify), Event Hubs (stream), Durable Functions (saga).
