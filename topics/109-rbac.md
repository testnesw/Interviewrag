# 109 · Azure RBAC (Role-Based Access Control)

> Domain: Security & Identity · Level: Principal Security / Identity Architect

## 1. Beginner Explanation
Azure RBAC controls **who can do what to which Azure resources**. You assign a person, group, or app a **role** (a set of permissions) at a **scope** (like a subscription or resource group), so people get exactly the access they need — no more, no less.

## 2. Architect-Level Explanation
The authorization system for the Azure control plane (and many data planes):
- **Role assignment = who + role + scope**: **security principal** (user/group/SP/managed identity) + **role definition** (permission set) + **scope** (management group → subscription → resource group → resource).
- **Inheritance**: assignments flow **downward** from broader scopes to narrower ones (assign at RG → applies to all resources in it).
- **Role definitions**: **built-in** (Owner, Contributor, Reader, plus service-specific like Storage Blob Data Reader) vs **custom roles** (Actions/NotActions/DataActions/NotDataActions).
- **Control plane vs data plane**: `Actions` (manage resources — e.g., create a storage account) vs **DataActions** (access data — e.g., read a blob). Contributor manages but can't necessarily read data without a data role.
- **Key roles**: **Owner** (full + manage access), **Contributor** (full manage, no access grants), **Reader** (view), **User Access Administrator** (manage RBAC only).
- **Evaluation**: additive **allow** model; **deny assignments** (rare, e.g., Blueprints/Managed Apps) override. Most-specific scope + union of roles.
- **Governance**: least privilege, **PIM** for privileged roles (JIT), **Access Reviews**, group-based assignments (not per-user), **Azure Policy** (governance ≠ RBAC).
- **vs Entra roles**: Azure RBAC governs Azure resources; **Entra ID roles** govern the directory (e.g., Global Admin) — different systems.

## 3. Real Enterprise Use Case
An enterprise structures RBAC via **management groups** (org → platform/landing zones), assigns roles to **Entra groups** (not individuals) at RG scope, uses **custom roles** for least privilege (e.g., "VM Operator" without delete), grants privileged roles **just-in-time via PIM**, separates control-plane Contributor from **data-plane** roles (Blob Data Reader), and runs quarterly **Access Reviews** — auditable least-privilege at scale.

## 4. Architecture Diagram (ASCII)
```
   Role Assignment = WHO + ROLE + SCOPE
   WHO: user│group│service principal│managed identity
   ROLE: built-in (Owner/Contributor/Reader/…) or custom (Actions/DataActions)
   SCOPE (inherits downward):
      Management Group ─► Subscription ─► Resource Group ─► Resource
   Control plane (Actions) vs Data plane (DataActions)
   Additive allow ∪ | deny assignments override | PIM = JIT for privileged
```

## 5. Interview Questions
1. What are the three parts of a role assignment?
2. How does scope inheritance work?
3. Control-plane vs data-plane permissions (Actions vs DataActions)?
4. Owner vs Contributor vs User Access Administrator?
5. Built-in vs custom roles; how to enforce least privilege?

## 6. Strong Interview Answers
- **Three parts**: "A role assignment binds a **security principal** (who), a **role definition** (what permissions), and a **scope** (where — management group/subscription/RG/resource). All three together grant access."
- **Inheritance**: "Assignments inherit **downward** — a role at a resource group applies to every resource within it; at a subscription, to all its RGs. Effective permissions are the **union** of all assignments that apply at or above a resource's scope. I assign at the broadest sensible scope for manageability, narrowest for least privilege."
- **Actions vs DataActions**: "`Actions` are control-plane operations (create/delete/configure a resource); **`DataActions`** are data-plane (read/write the data inside, like blob contents). Crucially, **Contributor can manage a storage account but not read its blobs** without a data role — so I assign data roles (Blob Data Reader) explicitly for data access."
- **Owner/Contributor/UAA**: "**Owner** = full control including granting access; **Contributor** = full management but **cannot** assign roles; **User Access Administrator** = manage access only, not resources. Separating Contributor from access-granting enforces separation of duties."
- **Custom/least privilege**: "Built-in roles cover most needs; when they're too broad I create **custom roles** with specific Actions/NotActions/DataActions. Least privilege: assign to **groups** not users, at the narrowest scope, use PIM for privileged/JIT, and review with Access Reviews."

## 7. Common Mistakes
- Assigning Owner/Contributor broadly instead of least privilege.
- Per-user assignments instead of groups → unmanageable.
- Forgetting **DataActions** (Contributor ≠ data access) → confusing 403s.
- Assigning at too-broad scope (subscription when RG suffices).
- Standing privileged access instead of PIM JIT.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Broad scope | fewer assignments | over-permission risk |
| Custom roles | least privilege | maintenance overhead |
| Group-based | manageable | needs group hygiene |

## 9. Production Best Practices
- Least privilege; assign to **Entra groups** at narrowest scope.
- Separate control-plane vs data-plane roles explicitly.
- PIM for privileged roles (JIT + approval); Access Reviews.
- Custom roles only when built-ins too broad; document them.
- Management-group hierarchy + Azure Policy for governance; IaC assignments.

## 10. Security Considerations
- Least privilege + separation of duties (Contributor vs UAA vs Owner).
- PIM JIT for admin roles; limit standing Owners; break-glass accounts.
- Audit role assignments (activity log → Sentinel); detect privilege escalation.
- Deny assignments where needed; review guest/SP access.

## 11. Cost Optimization
- RBAC itself is free; prevents costly mistakes/breaches via least privilege.
- Reader roles for cost/monitoring visibility without change rights.
- Governance (Policy + RBAC) avoids sprawl/unauthorized expensive resources.

## 12. Troubleshooting Scenarios
- **403 on data despite Contributor** → missing DataAction role (add Blob Data Reader).
- **User can't grant access** → Contributor can't assign roles; needs Owner/UAA.
- **Unexpected access** → inherited assignment from higher scope; check effective permissions.
- **Too much access** → broad scope/role; narrow scope + least-privilege role.
- **Privileged action denied** → PIM role not activated (JIT).

## 13. Hands-on Example
```bash
az role assignment create --assignee-object-id $GROUP_ID --assignee-principal-type Group \
  --role "Storage Blob Data Reader" --scope $STORAGE_ID       # data-plane, least privilege
az role definition create --role-definition @vm-operator.json  # custom role
```

## 14. Terraform Example
```hcl
resource "azurerm_role_definition" "vm_operator" {
  name = "VM Operator" scope = data.azurerm_subscription.s.id
  permissions {
    actions = ["Microsoft.Compute/virtualMachines/start/action",
               "Microsoft.Compute/virtualMachines/restart/action"]
    not_actions = ["Microsoft.Compute/virtualMachines/delete"]   # least privilege
  }
}
resource "azurerm_role_assignment" "ops" {
  scope = azurerm_resource_group.app.id
  role_definition_id = azurerm_role_definition.vm_operator.role_definition_resource_id
  principal_id = azuread_group.ops.object_id                      # group, not user
}
```

## 15. Azure Example
```bash
# Check effective permissions / who has access at a scope
az role assignment list --scope $RG_ID --include-inherited -o table
```

## 16. FastAPI / Python Example
```python
# App relies on RBAC data-plane roles for its Managed Identity; app-level authz maps roles
from fastapi import Depends, HTTPException
def require_role(role: str):
    def dep(claims: dict = Depends(verify_token)):
        if role not in claims.get("roles", []):   # app roles (Entra) mirror least-privilege
            raise HTTPException(403, "insufficient role")
        return claims
    return dep

@app.delete("/orders/{id}")
async def delete_order(id: str, _=Depends(require_role("Orders.Admin"))): ...
```

## 17. AKS Example
AKS combines **Azure RBAC for Kubernetes authorization** (Entra identities/groups mapped to cluster access via Azure role assignments) with Kubernetes RBAC. Cluster admin is granted **just-in-time via PIM**; workloads get least-privilege data roles through Workload Identity — layered, auditable access control.

## 18. How to Remember
**"WHO + ROLE + SCOPE; inherits downward; Actions (manage) vs DataActions (data — Contributor ≠ data access); groups + narrow scope + PIM = least privilege."**

## 19. Real-World Analogy
An office building's access-card system: each card (role) opens certain doors (permissions) on certain floors (scope). Giving someone the lobby master key (subscription Owner) opens everything below it (inheritance). A facilities pass lets you manage the HVAC room but not open the safe inside (control-plane vs data-plane) — and sensitive keys are only issued for the shift you need them (PIM).

## 20. One-Page Cheat Sheet
- **Model**: role assignment = **WHO** (principal) + **ROLE** (definition) + **SCOPE**; inherits **downward**.
- **Roles**: built-in (Owner/Contributor/Reader + service roles) vs **custom** (Actions/NotActions/DataActions).
- **Plane split**: `Actions` (manage) vs **`DataActions`** (data) — **Contributor ≠ data access**.
- **Key**: Owner (grants access), Contributor (no grants), User Access Administrator (access only).
- **Least privilege**: assign to **groups**, narrowest scope, **PIM** JIT for privileged, Access Reviews.
- **vs Entra roles**: Azure RBAC = resources; Entra roles = directory; Azure Policy = governance (not RBAC).
