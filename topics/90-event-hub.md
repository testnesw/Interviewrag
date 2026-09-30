# 90 · Azure Event Hubs

> Domain: Integration & Messaging · Level: Principal Integration Architect

## 1. Beginner Explanation
Azure Event Hubs is a **big-data streaming platform** that can ingest millions of events per second — like telemetry, logs, clickstreams, or IoT data. Many producers write a continuous stream, and consumers read it, often for real-time analytics.

## 2. Architect-Level Explanation
A high-throughput, partitioned event-streaming / ingestion service (Kafka-compatible):
- **Log-based streaming**: events appended to **partitions**; consumers read by **offset** and can **replay** (retention-based), unlike a delete-on-read queue.
- **Partitions**: unit of parallelism + ordering (ordered within a partition, keyed by **partition key**). Choose count for target throughput/consumers.
- **Consumer groups**: independent views of the stream; each consumer group tracks its own offset (**checkpointing** to storage).
- **Throughput**: **Throughput Units** (Standard) / **Processing Units** (Premium) / **Capacity Units** (Dedicated); **Auto-Inflate** to scale.
- **Kafka endpoint**: works with Kafka clients/ecosystem without running Kafka.
- **Capture**: auto-archive stream to Blob/Data Lake (Avro) for batch/analytics.
- **Integrations**: Stream Analytics, Databricks/Spark, Functions, Fabric — real-time pipelines.
- **vs Service Bus/Event Grid**: Event Hub = high-volume streaming/telemetry with replay; not per-message commands or reactive notifications.
- **Delivery**: at-least-once; consumers handle idempotency + checkpointing.

## 3. Real Enterprise Use Case
An IoT/telemetry platform ingests millions of device events/sec into Event Hubs (partitioned by device), Stream Analytics/Databricks does real-time aggregation and anomaly detection, **Capture** archives raw events to Data Lake for batch ML, and multiple consumer groups let analytics, alerting, and archival read the same stream independently.

## 4. Architecture Diagram (ASCII)
```
   Millions of producers (IoT/logs/clickstream)
        │ partition key
   Event Hub ── Partition 0 ─┐
              ── Partition 1 ─┤ append-only log (replayable, retention)
              ── Partition N ─┘
        │ consumer groups (independent offsets/checkpoints)
   ┌─────┴───────┬───────────────┬─────────────┐
   Stream Analytics  Databricks/Spark  Functions  Capture ─► Data Lake (Avro)
   Kafka endpoint (use Kafka clients) | TU/PU auto-inflate
```

## 5. Interview Questions
1. How does Event Hubs differ from a queue?
2. What are partitions and consumer groups?
3. How do you scale throughput?
4. What is checkpointing and why does it matter?
5. Event Hubs vs Kafka vs Service Bus?

## 6. Strong Interview Answers
- **vs queue**: "Event Hubs is an append-only log — events aren't deleted on read; consumers read by offset and can replay within the retention window. A queue is delete-on-consume, point-to-point. Event Hubs is built for high-volume streaming and multiple independent readers, not per-message commands."
- **Partitions/consumer groups**: "Partitions are the unit of parallelism and ordering — events with the same partition key stay ordered in one partition, and you scale consumers up to the partition count. Consumer groups are independent views of the whole stream, each tracking its own offset, so analytics and archival can read the same data separately."
- **Scale**: "Throughput Units (Standard) or Processing/Capacity Units (Premium/Dedicated) with **Auto-Inflate**. I also pick enough partitions upfront since they bound consumer parallelism (and are hard to reduce later)."
- **Checkpointing**: "Consumers persist their processed offset (to Blob) so on restart/rebalance they resume where they left off, not from the start. It gives at-least-once processing; combined with idempotency it avoids reprocessing chaos."
- **vs Kafka/Service Bus**: "Event Hubs is a managed, Kafka-protocol-compatible streaming service — same concepts, no cluster to run. Service Bus is enterprise messaging (ordered commands, transactions, DLQ). Streaming/telemetry → Event Hubs; reliable commands → Service Bus."

## 7. Common Mistakes
- Too few partitions → limited consumer parallelism (can't easily increase).
- Using Event Hubs for per-message commands/workflows (use Service Bus).
- No checkpointing → reprocessing from start on restart.
- Hot partitions from a skewed partition key.
- Ignoring retention/replay semantics.

## 8. Trade-offs
| Aspect | Event Hubs | Service Bus |
|--------|-----------|-------------|
| Model | streaming log (replay) | queue/topic (consume) |
| Throughput | very high | moderate |
| Ordering | per partition | per session |
| DLQ/commands | no | yes |

## 9. Production Best Practices
- Size partitions for target throughput + consumer parallelism.
- Good partition key (even distribution, ordering where needed).
- Checkpoint reliably; idempotent consumers.
- Auto-Inflate / Premium for scale; Capture for archival.
- Managed Identity + private endpoints; monitor lag.

## 10. Security Considerations
- Entra ID + RBAC / Managed Identity (avoid SAS keys).
- Private endpoints; no public exposure.
- Least-privilege (send vs listen); encrypt sensitive fields.
- Network isolation for IoT ingestion.

## 11. Cost Optimization
- Right TU/PU + Auto-Inflate (don't over-provision).
- Capture for cheap long-term storage vs long retention.
- Batch producers; compress payloads.

## 12. Troubleshooting Scenarios
- **Consumer lag growing** → too few partitions/consumers; scale out.
- **Reprocessing from start** → checkpoint not persisted.
- **Hot partition** → skewed partition key; rebalance keying.
- **Throttling** → TU/PU limit; enable Auto-Inflate / upgrade.
- **Can't add consumers** → capped by partition count.

## 13. Hands-on Example
```bash
az eventhubs eventhub create -g rg --namespace-name eh-prod -n telemetry \
  --partition-count 16 --retention-time-in-hours 24 --enable-capture true \
  --capture-interval 300 --destination-name EventHubArchive.AzureBlockBlob
```

## 14. Terraform Example
```hcl
resource "azurerm_eventhub_namespace" "eh" {
  name = "eh-prod" resource_group_name = var.rg location = "eastus"
  sku = "Standard" capacity = 2 auto_inflate_enabled = true maximum_throughput_units = 10
}
resource "azurerm_eventhub" "telemetry" {
  name = "telemetry" namespace_id = azurerm_eventhub_namespace.eh.id
  partition_count = 16 message_retention = 1
}
```

## 15. Azure Example
Producers use the **Kafka endpoint** (`bootstrap.servers=eh-prod.servicebus.windows.net:9093`) so existing Kafka apps stream to Event Hubs unchanged; Stream Analytics or Databricks consumes for real-time processing, and Capture lands raw Avro in Data Lake.

## 16. FastAPI / Python Example
```python
from azure.eventhub.aio import EventHubProducerClient, EventData
from azure.identity.aio import DefaultAzureCredential

async def emit(events: list[dict]):
    producer = EventHubProducerClient(
        "eh-prod.servicebus.windows.net", "telemetry", DefaultAzureCredential())
    async with producer:
        batch = await producer.create_batch(partition_key="device-42")  # ordering
        for e in events:
            batch.add(EventData(str(e)))
        await producer.send_batch(batch)      # high-throughput batched send
```

## 17. AKS Example
An AKS stream-processing Deployment (one consumer per partition, scaled via **KEDA** `azure-eventhub` trigger on lag) reads with checkpointing to Blob via Workload Identity. KEDA scales consumers toward the partition count as lag grows, then back down — elastic real-time processing.

## 18. How to Remember
**"Streaming log: partitions = parallelism+order, consumer groups = independent readers, offsets/checkpoints = resume, replayable."** Millions/sec; Kafka-compatible.

## 19. Real-World Analogy
A newspaper printing press with numbered editions on a conveyor (append-only log): many reporters feed stories (producers), copies stream out continuously, and different departments (consumer groups) each read from their own bookmark (offset). Old editions stay archived (retention) so you can re-read them (replay) — unlike mail that's gone once opened.

## 20. One-Page Cheat Sheet
- **What**: high-throughput (millions/sec) partitioned event-streaming/ingestion; Kafka-compatible.
- **Log-based**: append-only, read by **offset**, **replayable** within retention (not delete-on-read).
- **Partitions**: parallelism + ordering (partition key); **consumer groups**: independent offsets + **checkpointing**.
- **Scale**: TU/PU/CU + Auto-Inflate; size partitions upfront.
- **Extras**: Capture → Data Lake (Avro); integrates Stream Analytics/Databricks/Functions.
- **vs**: Service Bus (commands), Event Grid (notifications). Scale consumers with KEDA on lag.
