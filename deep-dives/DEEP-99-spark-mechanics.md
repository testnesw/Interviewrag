# DEEP MECHANICS · Apache Spark

> Level 2 — the execution model (driver/executors, RDD/DataFrame, lazy DAG),
> shuffles, partitioning, and why joins/skew dominate performance.

---

## 0. The precise mental model
Spark is a **distributed compute engine** that parallelizes data processing across a cluster. You describe **transformations** on distributed collections (DataFrames); Spark builds a **lazy DAG** and only executes when an **action** is called, splitting work into **stages** and **tasks** run by **executors**. The whole performance game is **minimizing shuffles** (cross-network data movement) and **handling skew**.

---

## 1. Cluster architecture
- **Driver** — runs your program, builds the DAG, schedules tasks, collects results. Single point; don't `collect()` huge data to it.
- **Executors** — worker processes across nodes that run **tasks** on data **partitions** and hold cached data.
- **Cluster manager** — YARN/Kubernetes/Databricks allocates resources.
A **partition** = a chunk of data processed by one task on one core → parallelism = number of partitions.

## 2. RDD → DataFrame → lazy evaluation
- **RDD** — low-level distributed collection.
- **DataFrame/Dataset** — structured, columnar, optimized by **Catalyst** (query optimizer) + **Tungsten** (memory/codegen). Use DataFrames.
- **Lazy**: **transformations** (`map`, `filter`, `join`, `groupBy`) build the DAG but don't run; **actions** (`count`, `collect`, `write`) trigger execution. Lets Catalyst optimize the whole plan.

## 3. Jobs → stages → tasks (and shuffles)
An action = a **job** → split into **stages** at **shuffle boundaries** → each stage = **tasks** (one per partition).
- **Narrow transformations** (map/filter) — no data movement, pipelined within a stage.
- **Wide transformations** (groupBy/join/repartition) — require a **shuffle**: repartition data across the network by key → expensive (disk+network). **Minimizing shuffles is the #1 optimization.**

## 4. Shuffle, skew & joins (where perf dies)
- **Shuffle** — writes intermediate data, re-reads across nodes → slow. Reduce by filtering early, pre-partitioning, avoiding unnecessary `groupBy`.
- **Data skew** — one key has most rows → one task does all the work (straggler). Fix: **salting**, AQE skew join handling.
- **Broadcast join** — if one side is small, broadcast it to all executors → avoids the shuffle entirely (huge win). Spark auto-broadcasts under a threshold.
- **AQE (Adaptive Query Execution)** — runtime replan: coalesce partitions, handle skew, switch join strategy.

## 5. Caching & partitioning
- **cache/persist** — keep a reused DataFrame in memory to avoid recomputation.
- **Partitioning** — right number (too few = no parallelism; too many = overhead). `repartition` (shuffle, even) vs `coalesce` (no shuffle, reduce).
- **Partition pruning + predicate pushdown** — read only needed files/columns (Parquet/Delta).

## 6. Structured Streaming (context)
Micro-batch (or continuous) processing of unbounded data with the same DataFrame API; supports windowing, watermarks (late data), and exactly-once sinks.

## 7. The hard follow-ups (with answers)
1. **"Driver vs executor?"** → driver schedules/collects; executors run tasks on partitions. (§1)
2. **"Lazy evaluation — why?"** → transformations build a DAG; actions trigger; lets Catalyst optimize the whole plan. (§2)
3. **"What's a shuffle and why care?"** → wide-transformation cross-network repartition; expensive → minimize. (§3,4)
4. **"Handle a slow skewed job?"** → salting, AQE skew handling, broadcast the small side. (§4)
5. **"Speed up a join?"** → broadcast join if one side small; filter early; pre-partition on key. (§4)
6. **"repartition vs coalesce?"** → repartition shuffles for even/larger; coalesce reduces partitions without shuffle. (§5)

## 8. One-screen recall
- Spark = distributed engine; **driver** (DAG/schedule) + **executors** (tasks on **partitions**).
- Use **DataFrames** (Catalyst+Tungsten). **Lazy**: transformations build DAG, **actions** execute.
- Action→**job**→**stages** (split at **shuffle boundaries**)→**tasks**. **Narrow** (no move) vs **wide** (shuffle).
- **Shuffle = #1 cost** → filter early, pre-partition, avoid needless groupBy.
- **Skew** → salting / AQE. **Broadcast join** (small side) avoids shuffle. **AQE** replans at runtime.
- **cache** reused data; tune **partitions** (repartition=shuffle, coalesce=no shuffle); **pushdown/pruning** with Parquet/Delta.

> Next: Databricks.
