# 99 · Apache Spark

> Domain: Data & Storage · Level: Principal Data Platform Architect

## 1. Beginner Explanation
Apache Spark is a **distributed data-processing engine**. It splits huge datasets across many machines and processes them in parallel and in memory, making big-data jobs — transformations, aggregations, ML — run much faster than older tools.

## 2. Architect-Level Explanation
A unified distributed compute engine for large-scale data:
- **Architecture**: **Driver** (coordinates, builds DAG) + **Executors** (run tasks on worker nodes) + **Cluster Manager** (YARN/Kubernetes/standalone/Databricks).
- **Abstractions**: **RDD** (low-level), **DataFrame/Dataset** (structured, optimized), **Spark SQL**.
- **Execution model**: **lazy evaluation** — transformations (map, filter, join) build a DAG; **actions** (count, collect, write) trigger execution. **Catalyst optimizer** + **Tungsten** (code gen, memory mgmt) + **AQE** (Adaptive Query Execution) optimize plans.
- **Stages/tasks**: DAG split into stages at **shuffle** boundaries; tasks run per partition.
- **Shuffle**: expensive data redistribution across the network (joins, groupBy) — main performance concern; **data skew** and **small files** hurt.
- **Partitioning**: parallelism unit; repartition/coalesce; partition pruning.
- **APIs/workloads**: batch, **Structured Streaming** (micro-batch/continuous), MLlib, GraphX; PySpark/Scala/SQL.
- **Storage**: reads/writes Parquet/Delta/ORC/JSON on data lakes; separates compute from storage.
- **Tuning**: partition sizing, broadcast joins, caching/persist, avoiding wide transformations, handling skew (salting), memory config.

## 3. Real Enterprise Use Case
A data platform runs Spark (on Databricks/AKS) to process terabytes nightly: read raw JSON/CSV from ADLS Gen2, transform + join reference data into cleansed Delta tables, aggregate to business metrics, and run Structured Streaming for near-real-time event enrichment — tuned with broadcast joins, AQE, and partitioning to control shuffle and cost.

## 4. Architecture Diagram (ASCII)
```
   Driver (DAG + Catalyst plan) ──► Cluster Manager (K8s/YARN/Databricks)
        │ schedules tasks
   ┌────┴──────┬───────────┬───────────┐
   Executor    Executor    Executor    Executor   (parallel tasks / partition)
   Lazy: transformations build DAG ─► action triggers run
   Stages split at SHUFFLE (join/groupBy) ← main cost; skew/small files hurt
   Reads/writes Parquet/Delta on lake (compute ⟂ storage) | AQE optimizes
```

## 5. Interview Questions
1. Explain driver/executors and the execution model.
2. Transformations vs actions; what is lazy evaluation?
3. What is a shuffle and why is it costly?
4. RDD vs DataFrame; what optimizers apply?
5. How do you tune a slow Spark job?

## 6. Strong Interview Answers
- **Architecture/model**: "The driver builds a DAG of the job and coordinates; executors run tasks in parallel on partitions across workers; a cluster manager allocates resources. It's in-memory and distributed, which is why it's fast at scale."
- **Lazy/actions**: "Transformations (map, filter, join) are lazy — they just build the DAG. Nothing runs until an **action** (count, collect, write) triggers execution. Laziness lets Catalyst optimize the whole plan (predicate pushdown, reordering) before running."
- **Shuffle**: "A shuffle redistributes data across executors over the network — triggered by wide operations like joins, groupBy, distinct. It's the most expensive operation (network + disk I/O + serialization) and the usual bottleneck. I minimize it with broadcast joins for small tables, good partitioning, and reducing wide transformations."
- **RDD vs DataFrame**: "RDDs are low-level, unoptimized. DataFrames/Datasets are structured and go through the **Catalyst** optimizer + **Tungsten** code generation + **Adaptive Query Execution**, so they're much faster and the recommended API. I use RDDs only for rare low-level control."
- **Tuning**: "Profile the DAG/Spark UI for skew and shuffle. Use broadcast joins, right partition sizes (avoid tiny/huge partitions and small files), cache reused data, enable AQE, handle skew with salting, prefer DataFrame API, and push filters early. Then right-size executors/memory."

## 7. Common Mistakes
- `collect()` on huge data → driver OOM.
- Ignoring shuffle/data skew (one task dominates).
- Too many small files / wrong partition count.
- Not broadcasting small dimension tables in joins.
- Overusing caching (memory pressure) or RDDs over DataFrames.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Broadcast join | avoids shuffle | small table only |
| Caching | reuse speed | memory cost |
| More partitions | parallelism | overhead if too many |

## 9. Production Best Practices
- DataFrame/SQL API + AQE; broadcast small joins.
- Right partition sizing (~100–200MB); compact small files.
- Handle skew (salting); avoid collect on big data.
- Parquet/Delta + partition pruning + predicate pushdown.
- Monitor Spark UI; right-size executors/memory; checkpoint streaming.

## 10. Security Considerations
- Managed Identity/credential passthrough to storage (no keys).
- Network isolation (VNet/private endpoints) for cluster + storage.
- Column/row-level security via catalog (Unity Catalog).
- Encrypt data in transit + at rest; audit access.

## 11. Cost Optimization
- Minimize shuffle (biggest cost driver); efficient joins/partitioning.
- Autoscaling + spot/preemptible workers; auto-terminate idle.
- Columnar formats + pruning reduce I/O/compute; cache wisely.

## 12. Troubleshooting Scenarios
- **Driver OOM** → `collect()` on large data; write to storage instead.
- **One slow task/stage** → data skew; salt keys / repartition.
- **Excessive shuffle** → wide ops; broadcast joins, better partitioning.
- **Small-files slowness** → compact/coalesce output.
- **Executor OOM** → partition too large / caching; tune memory + partitions.

## 13. Hands-on Example
```python
from pyspark.sql import functions as F, SparkSession
spark = SparkSession.builder.appName("etl").getOrCreate()
orders = spark.read.parquet("abfss://silver@lake.dfs.core.windows.net/orders")
custs  = spark.read.parquet("abfss://silver@lake.dfs.core.windows.net/customers")
result = (orders.join(F.broadcast(custs), "customer_id")   # broadcast avoids shuffle
                .groupBy("region").agg(F.sum("amount").alias("revenue")))
result.write.mode("overwrite").partitionBy("region").parquet(".../gold/revenue")
```

## 14. Terraform Example
```hcl
# Spark on AKS via the Spark Operator (Helm) — declarative cluster infra
resource "helm_release" "spark_operator" {
  name = "spark-operator" repository = "https://kubeflow.github.io/spark-operator"
  chart = "spark-operator" namespace = "spark" create_namespace = true
}
```

## 15. Azure Example
Run Spark on **Azure Databricks**, **Synapse/Fabric Spark pools**, **HDInsight**, or **AKS** (Spark on Kubernetes). Databricks adds Photon + Delta + Unity Catalog; all read/write ADLS Gen2 via ABFS with Managed Identity.

## 16. FastAPI / Python Example
```python
# Submit a Spark batch job from an API (fire-and-track), not run Spark in the request
import subprocess
@app.post("/jobs/etl")
async def trigger_etl():
    subprocess.Popen(["spark-submit", "--master", "k8s://...", "etl_job.py"])
    return {"status": "submitted"}   # Spark is for batch/stream, not per-request compute
```

## 17. AKS Example
Spark runs on AKS via the **Spark Operator** or `spark-submit` with `--master k8s://` — the driver + executors are pods, scaled by the cluster autoscaler. Executors read/write ADLS Gen2 with **Workload Identity**; dynamic allocation adds/removes executor pods based on load.

## 18. How to Remember
**"Driver + executors; lazy transformations → action triggers DAG; SHUFFLE is the enemy (broadcast/partition to avoid); DataFrames + Catalyst/AQE; compute ⟂ storage."**

## 19. Real-World Analogy
A huge kitchen with one head chef (driver) directing many cooks (executors) who each prep a portion of ingredients in parallel (partitions). The chef plans the whole recipe before anyone starts (lazy DAG). The costly step is passing ingredients between stations across the kitchen (shuffle) — a good chef minimizes that shuffling to serve faster.

## 20. One-Page Cheat Sheet
- **What**: distributed in-memory big-data engine (batch, streaming, SQL, ML).
- **Parts**: **Driver** (DAG/plan) + **Executors** (parallel tasks) + cluster manager.
- **Model**: lazy **transformations** build DAG; **actions** trigger; Catalyst + Tungsten + **AQE** optimize.
- **Cost**: **shuffle** (joins/groupBy) is the bottleneck — broadcast small joins, partition well, fix skew.
- **API**: DataFrame/SQL > RDD; Parquet/Delta + pruning; compute ⟂ storage.
- **Run on**: Databricks, Synapse/Fabric, HDInsight, AKS (Spark Operator); Managed Identity to ADLS.
