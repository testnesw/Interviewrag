# DEEP MECHANICS · Terraform Fundamentals

> Level 2 — declarative IaC, the core workflow, HCL, providers/resources, the
> dependency graph, and plan/apply internals.

---

## 0. The precise mental model
Terraform is **declarative infrastructure as code**: you describe the **desired end state** in HCL, and Terraform figures out the **actions to reach it** by diffing desired config against recorded **state** and real infrastructure. It builds a **dependency graph**, then creates/updates/destroys resources in the right order. "Declare what you want; Terraform computes how."

---

## 1. The core workflow
```
write (HCL) → init (download providers/modules) →
plan (diff desired vs state/real → proposed changes) →
apply (execute changes, update state) → destroy (tear down)
```
- **plan** is the safety net — review changes before applying.
- **apply** is idempotent — re-running with no config change = no-op.

## 2. Providers & resources
- **Provider** — plugin that talks to an API (azurerm, aws, kubernetes). Configured with auth (use Managed Identity/OIDC, not keys).
- **Resource** — a managed infrastructure object (`resource "azurerm_storage_account" "x" {}`).
- **Data source** — read existing/external info (`data "azurerm_..."`).

## 3. Desired state vs state file
- **Config** = desired state. **State file** = Terraform's record of what it manages (maps config → real resource IDs).
- On plan, Terraform **refreshes** (reads real infra), compares to state and config, computes the delta. (State deep dive covers locking/remote backend.)

## 4. The dependency graph
Terraform parses references (`resource.a.id` used in `resource.b`) to build a **DAG**, then creates resources in dependency order and **parallelizes** independent ones. Explicit `depends_on` for hidden dependencies.

## 5. HCL essentials
- **Variables** (input), **outputs** (export values), **locals** (computed), **expressions/functions**, **count/for_each** (loops), **conditionals**, **modules** (reuse). Interpolation `${}` / references.

## 6. Idempotency & drift
- Declarative + state → **idempotent**: same config = same result.
- **Drift** — someone changes infra outside Terraform → next plan shows the difference → reconcile. (Don't make manual changes to Terraform-managed infra.)

## 7. The hard follow-ups (with answers)
1. **"Declarative vs imperative IaC?"** → declare desired end state (Terraform computes actions) vs script each step (e.g., scripts). (§0)
2. **"The workflow?"** → write→init→plan→apply (→destroy); plan diffs, apply executes idempotently. (§1)
3. **"How does Terraform order resource creation?"** → dependency DAG from references; parallel where independent. (§4)
4. **"Provider vs resource vs data source?"** → API plugin vs managed object vs read-only lookup. (§2)
5. **"What is drift?"** → out-of-band changes diverging from state; plan detects, reconcile via Terraform. (§6)
6. **"Terraform vs Bicep/ARM?"** → multi-cloud declarative with state vs Azure-native (no state file, ARM-managed). (§2)

## 8. One-screen recall
- Terraform = **declarative IaC**: declare desired state → diff vs **state** + real infra → create/update/destroy in order.
- Workflow: **write→init→plan→apply(→destroy)**; plan = safety diff, apply = **idempotent**.
- **Provider** (API plugin, keyless auth) · **resource** (managed) · **data source** (read).
- **Dependency DAG** from references (parallel independents; `depends_on` for hidden).
- HCL: variables/outputs/locals, count/for_each, modules.
- **Drift** = out-of-band change → plan detects → reconcile; never edit managed infra manually.

> Next: Remote Backend.
