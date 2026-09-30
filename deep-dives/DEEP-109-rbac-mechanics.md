# DEEP MECHANICS · Azure RBAC

> Level 2 — role assignments, scope hierarchy, role definitions, deny/ABAC, and
> RBAC vs Entra roles.

---

## 0. The precise mental model
Azure RBAC is the **authorization** system for the Azure control/data plane: access = a **role assignment** = **(security principal) + (role definition) + (scope)**. It answers "**what can this identity do on which resources**." It's **additive and inherited down the scope hierarchy**, least-privilege by design.

---

## 1. The three parts of an assignment
```
Assignment = WHO (principal) + WHAT (role definition) + WHERE (scope)
```
- **Principal**: user, group, service principal, or managed identity.
- **Role definition**: a set of **Actions/DataActions** (allowed) and **NotActions/NotDataActions** (subtracted).
- **Scope**: the resource boundary.

## 2. Scope hierarchy & inheritance
```
Management Group → Subscription → Resource Group → Resource
```
- Assign at a scope → **inherited by everything below**.
- Assign at the **narrowest scope** needed (least privilege). Higher scope = broader power.

## 3. Role definitions
- **Built-in roles**: **Owner** (full + manage access), **Contributor** (full except manage access/RBAC), **Reader** (view), + service-specific (e.g., *Storage Blob Data Reader*, *Key Vault Secrets User*).
- **Custom roles**: define exact Actions/DataActions when built-ins don't fit.
- **Control plane** (`Actions`, manage resources via ARM) vs **data plane** (`DataActions`, access data *in* resources, e.g., blob contents).

## 4. Evaluation logic
- **Additive**: effective permission = union of all assignments.
- **Deny assignments** override allows (used by Azure/Blueprints/managed apps).
- **Explicit deny > allow**. No assignment = no access (default deny).

## 5. ABAC (attribute-based conditions)
- Add **conditions** to role assignments (e.g., allow blob read only if `tag = project:x` or path prefix) → finer-grained than role alone, fewer role definitions.

## 6. RBAC vs Entra roles vs PIM
- **Azure RBAC** = permissions on **Azure resources** (VMs, storage, RGs).
- **Entra roles** = permissions on **Entra/directory** (users, groups, app regs — e.g., Global Admin).
- **PIM** = make either **just-in-time / time-bound** (eligible → activate with approval/MFA).

## 7. Best practices
- Prefer **groups** over individual assignments; assign at right scope; use **built-in** before custom.
- Least privilege; **data roles** not Owner for data access; audit with Access Reviews + activity logs.

## 8. The hard follow-ups (with answers)
1. **"What makes up an assignment?"** → principal + role definition + scope. (§1)
2. **"How does inheritance work?"** → assign at a scope → inherited to all child scopes. (§2)
3. **"Owner vs Contributor?"** → Owner can **manage access (RBAC)**; Contributor can't. (§3)
4. **"Control vs data plane?"** → Actions (manage resource via ARM) vs **DataActions** (access data inside, e.g., blob). (§3)
5. **"Two conflicting assignments?"** → additive union, but **deny assignment wins**. (§4)
6. **"Restrict to resources with a tag?"** → **ABAC condition** on the assignment. (§5)
7. **"RBAC vs Entra roles?"** → Azure resources vs directory objects. (§6)
8. **"Grant admin only when needed?"** → **PIM** JIT activation. (§6)

## 9. One-screen recall
- **Assignment = principal + role definition + scope**; answers "who can do what where."
- **Scope**: MG → Sub → RG → Resource; **inherited down**; assign narrowest.
- **Roles**: Owner (full+RBAC) / Contributor (no RBAC) / Reader; + data roles; custom when needed.
- **Control plane (Actions)** vs **data plane (DataActions)**.
- **Additive union**; **deny > allow**; default deny.
- **ABAC** conditions for fine-grain; **PIM** for JIT; **Entra roles** ≠ Azure RBAC.

> Next: PIM.
