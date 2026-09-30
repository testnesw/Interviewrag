# DEEP MECHANICS · Azure Data Lake Storage Gen2

> Level 2 — what HNS actually changes, hierarchical namespace vs flat blob, ACLs
> + RBAC, and why ADLS Gen2 is the analytics storage layer.

---

## 0. The precise mental model
ADLS Gen2 = **Blob Storage + a Hierarchical Namespace (HNS)**. That one feature turns flat object storage into a **real directory tree** with **atomic directory operations** and **POSIX-like ACLs**, which is exactly what big-data analytics engines (Spark/Databricks/Synapse) need. It's the **storage foundation of the lakehouse** — cheap, massive, hierarchical, secure.

---

## 1. What HNS changes (the core)
Plain blob = **flat namespace**; "folders" are just name prefixes. Renaming/deleting a "folder" = touch every blob (slow, non-atomic).
**HNS** = a true filesystem tree:
- **Atomic directory rename/delete** — O(1) metadata op, not per-file → critical for Spark job commit performance and correctness.
- **Directory-level operations & ACLs.**
- Efficient hierarchical listing for analytics.

## 2. Security — RBAC + POSIX ACLs
Two layers combine:
- **Azure RBAC** — coarse, at container/account (e.g., Storage Blob Data Reader).
- **POSIX ACLs** — fine-grained per **directory/file** (read/write/execute for users/groups) → analytics-grade access control on specific paths.
Evaluation: RBAC checked first (super-user roles short-circuit); otherwise ACLs decide. Use Entra groups on ACLs (not individual users) for manageability.

## 3. Multi-protocol access
Same data accessible via **Blob APIs** and the **DFS (filesystem) endpoint** (`abfss://`). Analytics engines use the ABFS driver; other tools use blob APIs → one dataset, many tools.

## 4. Why it's the analytics layer
- Cheap, virtually unlimited, tiered (Hot/Cool/Archive) like blob.
- HNS + atomic ops + ACLs → efficient, correct, secure for Spark/Databricks/Synapse.
- Foundation for **medallion (Bronze/Silver/Gold)** lakehouse layouts with Delta/Parquet.

## 5. Design notes
- **Partition folder layout** (`/year=/month=/`) → partition pruning.
- Use **`abfss://`** + Managed Identity/Service Principal for secure access.
- Combine with **Private Endpoint** for network isolation.
- Avoid tiny files (small-file problem) → compaction.

## 6. The hard follow-ups (with answers)
1. **"ADLS Gen2 vs Blob?"** → Blob + **Hierarchical Namespace** → real directories, atomic dir ops, POSIX ACLs. (§0,1)
2. **"Why does HNS matter for Spark?"** → atomic O(1) directory rename/commit + efficient listing → correct, fast jobs. (§1)
3. **"How is access controlled?"** → **RBAC (coarse) + POSIX ACLs (per path)**; RBAC checked first, then ACLs; use Entra groups. (§2)
4. **"How do engines access it?"** → `abfss://` DFS endpoint via ABFS driver (multi-protocol with blob). (§3)
5. **"Why is it the lakehouse storage?"** → cheap+tiered + HNS/ACLs → efficient secure analytics; hosts medallion+Delta. (§4)

## 7. One-screen recall
- **ADLS Gen2 = Blob + Hierarchical Namespace (HNS)** → true directory tree.
- HNS wins: **atomic O(1) dir rename/delete** (Spark commit correctness/speed), dir ops, **POSIX ACLs**.
- **Security = RBAC (coarse) + POSIX ACLs (fine per path)**; RBAC first then ACL; assign to **Entra groups**.
- **Multi-protocol**: blob APIs + **`abfss://` DFS**; analytics engines use ABFS.
- Cheap/tiered/unlimited → **lakehouse foundation** (medallion + Delta/Parquet), partition layout for pruning, Private Endpoint, avoid small files.

> Next: Azure SQL.
