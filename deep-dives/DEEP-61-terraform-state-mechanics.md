# DEEP MECHANICS · Terraform State & Core Engine

> Level 2 — what state actually is, how the dependency graph and plan work,
> locking internals, drift, safe refactoring, and the failure scenarios
> interviewers use to separate users from architects.

---

## 0. The precise mental model
Terraform is a **desired-state engine with memory**. The **state file** is that memory — a JSON map from your config's resource addresses to **real-world resource IDs + last-known attributes**. Every `plan` is a three-way reconcile: **config (desired)** vs **state (last known)** vs **real infrastructure (actual)**. Understand state and the graph, and everything else is detail.

---

## 1. What state actually contains and why it's mandatory

State stores, per resource: the **address** (`azurerm_storage_account.this`), the **provider ID** (the real Azure resource ID), **all attributes** last read, and **dependency edges**. Terraform needs it to:
- **Map** config ↔ real resources (there's no reliable way to "find" your resources otherwise).
- **Detect drift** (compare stored attributes to real ones on refresh).
- **Compute diffs** without querying/rebuilding everything from scratch.
- Store **outputs** and **resource dependencies** for ordering.

**Why you can't just skip it:** without state, Terraform can't know that "the storage account in my config" *is* "this specific Azure resource" — it would try to create a duplicate. State is identity.

**Security fact:** state can contain **secrets in plaintext** (e.g., a generated password, connection strings). Therefore: **remote encrypted backend + access control, never commit to git, avoid unnecessary sensitive outputs.**

---

## 2. The plan/apply engine — three-way reconcile + the graph

**Plan does:**
1. **Refresh** (unless disabled): read real infra → update in-memory state copy → this is how **drift** surfaces.
2. **Build the resource dependency graph** (a **DAG**) from implicit references (`a.id` used in `b`) and explicit `depends_on`.
3. **Diff**: for each resource compare **desired (config)** vs **refreshed state** → classify as **create / update-in-place / destroy / replace (-/+)**.
4. Output the plan (optionally save to a file for a guaranteed apply).

**Apply does:** walk the DAG, executing changes with **parallelism** (default 10) across independent nodes, respecting dependency order.

**Replace (`-/+`) vs update:** some attribute changes are **ForceNew** (the provider can't change them in place, e.g., a resource's region/name) → Terraform **destroys then recreates**. Reading the plan's `-/+` and *why* (it annotates "forces replacement") is critical — this is where accidental data loss happens.

**Deep follow-up: "Your plan shows a destroy/recreate of the database — how do you avoid downtime/data loss?"**
Identify the ForceNew attribute causing it. Options: `create_before_destroy` lifecycle (new before old), `ignore_changes` if it's externally managed, `moved`/import if it's really a rename, or don't change that attribute. Never blindly apply a `-/+` on stateful resources.

---

## 3. Remote backend + locking (the concurrency mechanic)

**Local state = single-user, unsafe.** Teams use a **remote backend** (azurerm → Azure Storage blob). It provides:
- **Shared state** all engineers/pipelines read.
- **State locking**: before write operations, Terraform acquires a **lock**. On azurerm this is a **blob lease** on the state blob. A second `apply` **blocks/fails** with "state locked" until released.

**Why locking is non-negotiable:** two concurrent applies could both read state, both make changes, and the second write **overwrites** the first's record → **state corruption / orphaned resources**. The lock serializes writes.

**Deep follow-up: "A pipeline crashed mid-apply and now state is locked — what do you do?"**
The lease is stuck. Verify no apply is actually running, then `terraform force-unlock <LOCK_ID>`. Also check whether the apply partially completed — real resources may exist that state doesn't fully reflect → run `plan` to reconcile, import if needed. Never force-unlock while an apply is genuinely running.

---

## 4. Drift — detection and reconciliation

**Drift** = real infrastructure changed outside Terraform (someone edited in the portal). Mechanics:
- `plan`/`refresh` reads real attributes → diff against config → shows changes to "revert" the drift.
- `apply` re-imposes config (undoes the manual change), OR you update config to match (accept it), OR `import` if it's a new resource.

**Governance answer:** enforce **IaC-only changes** (deny portal edits via process/policy), run **scheduled `plan`** in CI to *detect* drift early, and treat drift as an incident.

---

## 5. Safe refactoring without destroying resources

When you rename/move resources in config, Terraform by default sees the old address **gone** (destroy) and a new address **added** (create) → **destroy+recreate**. To avoid:
- **`moved` blocks** (declarative, committed) — tell Terraform "address A is now B" → it updates state mapping, **no destroy**.
- **`terraform state mv`** (imperative CLI) — same effect, manual.
- **`import` / `import` blocks** — bring existing/brownfield resources under management by mapping real ID → address.
- **`terraform state rm`** — remove from state *without* destroying the real resource (e.g., handing ownership to another config).

**Deep follow-up: "You split one big module into two — how do you not recreate everything?"**
Use `moved` blocks (or `state mv`) to remap each resource to its new module address so state follows the refactor; verify with `plan` showing **no changes** to those resources.

---

## 6. State structure at scale — layering to limit blast radius

One giant state = huge blast radius + slow plans + lock contention. Enterprise pattern: **split state by layer/lifecycle**:
- `foundation` (management groups, policy), `network` (hub/spoke), `platform` (AKS, shared), `app` (per-workload).
- Layers reference each other via **`terraform_remote_state`** data source (read outputs) — e.g., app layer reads network layer's VNet ID.
- **Per-environment separate state** (`dev`/`test`/`prod` different backend keys) so prod is isolated with its own pipeline + approvals.

**Workspaces vs separate state:** workspaces multiplex states under one backend/config (lightweight, but easy to apply to the wrong one). For **strong prod isolation**, prefer **separate backends/directories**.

---

## 7. count vs for_each (the state-stability issue)
- **`count`** indexes resources by **position** (`[0],[1],[2]`). Remove the middle element → everything after **shifts index** → Terraform destroys/recreates them. Fragile.
- **`for_each`** keys resources by a **stable map/set key** (`["blue"]`, `["green"]`). Remove one → only that key is destroyed; others untouched. **Prefer `for_each`** for anything that changes membership.

---

## 8. The hard follow-up questions (with answers)
1. **"What is state and why can't Terraform work without it?"** → the config↔real-resource identity map + last-known attributes; without it Terraform can't find/track resources and would duplicate. (§1)
2. **"Two engineers apply simultaneously — what prevents corruption?"** → **state locking** (blob lease) serializes writes; second apply blocks. (§3)
3. **"Plan shows `-/+` on prod DB — what and how to avoid?"** → a **ForceNew** attribute → destroy+recreate; use `create_before_destroy`/`ignore_changes`/`moved`/don't change it. (§2)
4. **"Someone changed a resource in the portal — how does Terraform react and what do you do?"** → refresh surfaces **drift**; apply reverts, or update config to accept, or import; enforce IaC-only + scheduled drift detection. (§4)
5. **"Rename a resource without recreating it?"** → **`moved` block** / `state mv` remaps state address. (§5)
6. **"Reduce blast radius of a huge state?"** → **layer state** (network/platform/app) + remote_state references + per-env separate state. (§6)
7. **"count vs for_each — why does removing an element matter?"** → count reindexes (recreates trailing resources); for_each keys are stable. (§7)
8. **"State is locked after a crash — recover?"** → confirm nothing running → `force-unlock` → `plan` to reconcile any partial apply. (§3)

---

## 9. One-screen deep-recall sheet
- **State** = JSON map: config address ↔ real resource ID + last attributes + deps. It's **identity + memory + drift baseline**. Can hold **plaintext secrets** → remote encrypted backend, never in git.
- **plan** = 3-way reconcile: **config** vs **state** vs **real** (refresh surfaces drift) → build **DAG** → diff (create/update/**replace -/+**/destroy). **apply** walks DAG with parallelism.
- **ForceNew** attr → destroy+recreate; avoid with `create_before_destroy` / `ignore_changes` / `moved`.
- **Remote backend (azurerm)** + **state locking (blob lease)** serialize writes → prevent corruption; crash → `force-unlock` then reconcile.
- **Drift** = out-of-band change; refresh detects, apply reverts; enforce IaC-only + scheduled plan.
- **Refactor safely**: **`moved` blocks** / `state mv` / `import` / `state rm` (remove without destroy).
- **Scale**: **layer state** (foundation/network/platform/app) + `terraform_remote_state`; **separate state per env** (prod isolated). Workspaces = lightweight, separate backends = strong isolation.
- **`for_each` > `count`** (stable keys vs positional reindex).

---

> Next: **FastAPI / Async**.
