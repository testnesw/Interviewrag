# 96 · Azure Cosmos DB

> Domain: Data & Storage · Level: Principal Data Platform Architect

## 1. Beginner Explanation
Azure Cosmos DB is a **globally distributed NoSQL database**. It replicates your data across regions automatically, offers very low latency, and scales massively — great for global apps that need fast reads/writes anywhere.

## 2. Architect-Level Explanation
Globally distributed, multi-model, horizontally scalable NoSQL PaaS:
- **APIs**: **NoSQL (Core)** (native, recommended), MongoDB, Cassandra, Gremlin (graph), Table.
- **Partitioning**: **partition key** determines physical partitions; scales throughput + storage horizontally. Good key = high cardinality + even access (avoid hot partitions).
- **Throughput**: **RU/s** (Request Units) — provisioned (manual/autoscale) or **serverless**. RUs abstract CPU/IO/memory cost per operation.
- **Global distribution**: turnkey multi-region replication; **multi-region writes** (multi-master) for local low-latency writes; automatic failover.
- **Consistency levels (5)**: Strong → Bounded Staleness → Session (default) → Consistent Prefix → Eventual — trade consistency for latency/availability.
- **SLA**: 99.999% availability (multi-region), single-digit-ms latency.
- **Change feed**: ordered log of changes → event-driven pipelines, materialized views, Functions.
- **Features**: TTL, auto-indexing (all fields by default, tunable), analytical store (**Synapse Link** — HTAP, no ETL), integrated cache, vector search (AI).
- **Security**: Entra ID RBAC + Managed Identity, private endpoints, CMK.

## 3. Real Enterprise Use Case
A global retail app stores product/cart data in Cosmos DB **NoSQL API**, partitioned by `customerId`, with **multi-region writes** for low-latency writes worldwide, **Session** consistency for user experience, **autoscale RU/s** for traffic spikes, **change feed** driving real-time inventory Functions, and **Synapse Link** for analytics without ETL — all on private endpoints with Managed Identity.

## 4. Architecture Diagram (ASCII)
```
   Global clients ─► nearest region (single-digit-ms)
   ┌────────── Cosmos DB (multi-region writes) ──────────┐
   Region A ⇄ Region B ⇄ Region C   (turnkey replication)
   └─────────────────────────────────────────────────────┘
   Container ─► partitions (by partition key) ─► RU/s (autoscale/serverless)
   Consistency: Strong│Bounded│Session│Prefix│Eventual
   Change feed ─► Functions (event-driven) | Synapse Link ─► analytics (HTAP)
```

## 5. Interview Questions
1. What is a partition key and why is it critical?
2. Explain RU/s and how to optimize cost.
3. Walk through the 5 consistency levels.
4. What is multi-region writes vs single-region?
5. What is the change feed used for?

## 6. Strong Interview Answers
- **Partition key**: "It's the single most important design decision — it determines how data is distributed across physical partitions. A good key has high cardinality and spreads reads/writes evenly; a bad one creates hot partitions that throttle. It should also match your most common query filter to avoid cross-partition fan-out. You can't change it later, so I model it carefully."
- **RU/s**: "Request Units abstract the cost of operations (CPU/IO/memory). I provision RU/s manually, use **autoscale** (scales 10%–100% of a max) for variable load, or **serverless** for spiky/dev workloads. Optimize by efficient queries (point reads are cheapest — 1 RU), good partition keys, right indexing, and TTL to purge old data."
- **Consistency**: "Five levels: **Strong** (linearizable, highest latency), **Bounded Staleness** (lag bounded by time/versions), **Session** (default — read-your-writes per client), **Consistent Prefix** (never out of order), **Eventual** (lowest latency/cost). I pick per workload — Session is a great default; Strong only when correctness demands it."
- **Multi-region writes**: "Single-region write has one write region and read replicas elsewhere. Multi-region writes (multi-master) let every region accept writes for local low latency and higher write availability, with conflict resolution (last-write-wins or custom). Trade-off is handling write conflicts."
- **Change feed**: "A persistent, ordered record of inserts/updates per container. I use it to trigger Functions, build materialized views, sync to other stores, or feed event-driven pipelines — reliable, replayable change data capture."

## 7. Common Mistakes
- Poor partition key → hot partitions + throttling (429).
- Cross-partition queries at scale (expensive fan-out).
- Choosing Strong consistency unnecessarily (latency/cost).
- Over-provisioning RU/s (fixed) instead of autoscale/serverless.
- Indexing everything when not needed (write RU cost).

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Multi-region writes | local low-latency writes | conflict handling |
| Strong consistency | correctness | latency, cost, availability |
| Autoscale RU/s | handles spikes | ~1.5x rate vs manual |

## 9. Production Best Practices
- Design partition key for even distribution + query alignment.
- Autoscale/serverless RU/s; point reads; tune indexing policy.
- Session consistency default; Strong only where needed.
- TTL for expiry; change feed for event-driven + materialized views.
- Managed Identity + private endpoints; multi-region for HA/DR.

## 10. Security Considerations
- Entra ID RBAC + Managed Identity (avoid keys); private endpoints.
- CMK encryption; firewall/VNet; least-privilege data-plane roles.
- Disable key-based auth where possible; audit; network isolation.

## 11. Cost Optimization
- Autoscale/serverless to match traffic; avoid idle over-provisioning.
- Efficient queries (point reads = 1 RU); good partitioning reduces RU.
- TTL to purge data; right indexing; reserved capacity for steady load.

## 12. Troubleshooting Scenarios
- **429 (rate limited)** → RU/s exceeded or hot partition; scale/redesign key + backoff.
- **High RU per query** → cross-partition/full scans; add partition-key filter/index.
- **Stale reads** → consistency level; use Session/Bounded.
- **Write conflicts** → multi-region writes; set conflict resolution policy.
- **Hot partition** → skewed key; choose higher-cardinality key.

## 13. Hands-on Example
```bash
az cosmosdb create -g rg -n cosmos-prod --locations regionName=eastus \
  --locations regionName=westeurope --enable-multiple-write-locations true \
  --default-consistency-level Session
az cosmosdb sql container create -g rg -a cosmos-prod -d shop -n carts \
  --partition-key-path /customerId --max-throughput 4000     # autoscale
```

## 14. Terraform Example
```hcl
resource "azurerm_cosmosdb_account" "cosmos" {
  name = "cosmos-prod" resource_group_name = var.rg location = "eastus"
  offer_type = "Standard" kind = "GlobalDocumentDB"
  consistency_policy { consistency_level = "Session" }
  geo_location { location = "eastus" failover_priority = 0 }
  geo_location { location = "westeurope" failover_priority = 1 }
  enable_multiple_write_locations = true
}
```

## 15. Azure Example
```bash
# Change feed → Azure Function trigger (event-driven CDC)
az functionapp function create ...   # CosmosDBTrigger on 'carts' container leases
```

## 16. FastAPI / Python Example
```python
from azure.cosmos.aio import CosmosClient
from azure.identity.aio import DefaultAzureCredential

async def get_cart(customer_id: str, cart_id: str):
    async with CosmosClient("https://cosmos-prod.documents.azure.com:443/",
                            credential=DefaultAzureCredential()) as c:   # Managed Identity
        container = c.get_database_client("shop").get_container_client("carts")
        return await container.read_item(item=cart_id, partition_key=customer_id)  # point read = 1 RU
```

## 17. AKS Example
AKS microservices use Cosmos DB with **Workload Identity** (no keys) over private endpoints. The change feed feeds a KEDA-scaled consumer (or Function) for event-driven updates; autoscale RU/s absorbs traffic spikes from the cluster without manual intervention.

## 18. How to Remember
**"Global NoSQL: partition key is king; RU/s (autoscale/serverless); 5 consistency levels (Session default); multi-region writes; change feed = CDC."**

## 19. Real-World Analogy
A global franchise with identical stores in every city (regions): customers shop at the nearest branch for instant service (low latency), each branch can take orders (multi-region writes), and a central logistics feed (change feed) notifies warehouses of every sale. How synchronized the branches' inventory counts are is the "consistency level" you dial in.

## 20. One-Page Cheat Sheet
- **What**: globally distributed, multi-model NoSQL PaaS; 99.999% SLA, single-digit-ms.
- **APIs**: NoSQL (Core, preferred), MongoDB, Cassandra, Gremlin, Table.
- **Scale**: **partition key** (even + query-aligned, immutable) + **RU/s** (autoscale/serverless).
- **Consistency**: Strong→Bounded→**Session**(default)→Prefix→Eventual.
- **Global**: turnkey replication + multi-region writes (conflict resolution).
- **Extras**: change feed (CDC/event-driven), TTL, Synapse Link (HTAP), vector search; Managed Identity + private endpoints.
