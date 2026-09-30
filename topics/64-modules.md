# 64 · Terraform Modules

> Domain: Terraform & IaC · Level: Principal Platform Architect

## 1. Beginner Explanation
A module is a **reusable package of Terraform code** — a set of resources bundled together with inputs and outputs. Instead of copying the same code, you write it once as a module and reuse it everywhere.

## 2. Architect-Level Explanation
Modules are Terraform's unit of reuse and abstraction:
- **Structure**: input `variables`, `resources`, and `outputs`. The **root module** is your working dir; **child modules** are called via `module` blocks.
- **Sources**: local paths, Terraform **Registry**, Git, or a private registry (ACR/artifact feed).
- **Versioning**: pin module versions (semver) for stable, controlled rollouts.
- **Composition**: build small, focused modules (network, aks, storage) and compose them in environment root modules — DRY + consistency + guardrails baked in.
- **Meta-arguments**: `count`/`for_each` to instantiate multiple copies; `providers` passthrough; `depends_on`.
- **Design**: keep modules opinionated but configurable; avoid leaking provider config; expose sensible defaults + required inputs; document.
- Enables platform teams to publish "golden" modules enforcing standards (naming, tags, security).

## 3. Real Enterprise Use Case
A platform team publishes versioned "golden modules" (`aks`, `hub-network`, `sql`) in a private registry with security, naming, and tagging baked in. Application teams consume them via `module` blocks with a few inputs — getting compliant infrastructure without needing deep Azure expertise, and upgrades roll out via version bumps.

## 4. Architecture Diagram (ASCII)
```
   Private Module Registry (versioned golden modules)
     ├─ module "network" (vnet, subnets, nsg, tags)
     ├─ module "aks"     (secure defaults, identity, policy)
     └─ module "sql"     (private endpoint, backups)
              │ consumed with inputs (for_each per env)
   Root module (envs/prod/main.tf)
     module "aks" { source = ".../aks" version = "2.3.0" ... }
     outputs ─► wired between modules (network.subnet_id → aks)
```

## 5. Interview Questions
1. What is a module and why use one?
2. Root vs child module?
3. How do you version and source modules?
4. How do you instantiate many copies (count vs for_each)?
5. How do you design a good reusable module?

## 6. Strong Interview Answers
- **Why**: "Modules package resources with inputs/outputs for reuse — DRY, consistency, and embedded guardrails (naming, tags, security). Platform teams publish golden modules so app teams get compliant infra easily."
- **Root vs child**: "The root module is the directory you run Terraform in; child modules are those it calls via `module` blocks. Root wires child modules together and holds the backend/provider config."
- **Version/source**: "Source from a registry/Git and **pin the version** (`version = \"~> 2.3\"`) so upgrades are deliberate. I avoid unpinned Git refs in production."
- **count vs for_each**: "`count` for N identical copies indexed by number; `for_each` for a set/map keyed by stable identifiers — `for_each` is safer for collections because adding/removing an item doesn't reindex and destroy others."
- **Good design**: "Small and focused, opinionated defaults with required inputs, meaningful outputs, no hardcoded provider/env, documented, versioned, and tested. Don't build a mega-module that does everything."

## 7. Common Mistakes
- Unpinned module versions (surprise breaking changes).
- Mega-modules doing too much (hard to reuse/test).
- `count` on collections → reindex destroys resources.
- Hardcoding provider/region inside modules.
- No outputs → can't wire modules together.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Small modules | reusable, testable | more wiring |
| Mega-module | one call | rigid, hard to maintain |
| for_each | stable keys | must be known at plan |

## 9. Production Best Practices
- Golden, versioned modules in a private registry.
- Pin versions; semantic versioning + changelogs.
- `for_each` over `count` for collections.
- Clear inputs (validation), outputs, and docs/examples.
- Test modules (terratest/`terraform test`); no provider config inside.

## 10. Security Considerations
- Bake security defaults into modules (private endpoints, TLS, RBAC).
- Validate inputs (`validation` blocks) to prevent misconfig.
- Source only from trusted registries; pin + review upgrades.
- Enforce tags/naming for governance.

## 11. Cost Optimization
- Modules enforce approved, right-sized SKUs.
- Reuse avoids drift/duplication.
- `for_each` maps make per-env sizing explicit.

## 12. Troubleshooting Scenarios
- **Unexpected recreation** → `count` index shift; switch to `for_each`.
- **Module upgrade broke** → unpinned version; pin + read changelog.
- **Provider errors in module** → pass providers explicitly.
- **Output missing** → module doesn't export the value.
- **Duplicate resources** → module called twice without distinct keys.

## 13. Hands-on Example
```bash
terraform get -update       # download/refresh modules
terraform init              # also installs modules
terraform plan
```

## 14. Terraform Example
```hcl
# Reusable child module: modules/network/main.tf
variable "name" { type = string }
variable "address_space" { type = list(string) }
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.name}"
  address_space       = var.address_space
  location            = var.location
  resource_group_name = var.rg_name
  tags                = var.tags       # governance baked in
}
output "vnet_id" { value = azurerm_virtual_network.vnet.id }
```

## 15. Azure Example
```hcl
# Root module consuming a pinned golden module + for_each per environment
module "aks" {
  source   = "app.terraform.io/acme/aks/azurerm"
  version  = "~> 2.3"
  for_each = var.environments               # map: {dev=..., prod=...}
  name     = each.key
  node_size = each.value.node_size
}
```

## 16. FastAPI / Python Example
```python
# Self-service: render a root module that calls the golden module
TEMPLATE = '''module "aks" {{
  source  = "app.terraform.io/acme/aks/azurerm"
  version = "~> 2.3"
  name    = "{name}"
}}'''
@app.post("/infra/aks")
def scaffold(name: str):
    open(f"envs/{name}/main.tf", "w").write(TEMPLATE.format(name=name))
    return {"created": f"envs/{name}/main.tf"}
```

## 17. AKS Example
A golden `aks` module bakes in: SystemAssigned identity, Azure RBAC, private cluster, Cilium network policy, Defender, and required tags — app teams just pass `name` and `node_size`, guaranteeing every cluster is compliant by construction.

## 18. How to Remember
**"Write once, reuse everywhere, pin the version."** Small focused modules + `for_each` + golden defaults = compliant, DRY infra.

## 19. Real-World Analogy
Prefabricated building blocks (like standardized room modules in construction): the factory builds certified, code-compliant units once; builders assemble them with a few options (size, finish) — faster, consistent, and inspection-ready, versus custom-building every room.

## 20. One-Page Cheat Sheet
- **Module**: reusable package = inputs (variables) + resources + outputs.
- **Root vs child**: root = working dir (backend/providers); child = called via `module`.
- **Source + pin**: registry/Git with `version` — deliberate upgrades.
- **Multiples**: `for_each` (stable keys) preferred over `count` for collections.
- **Design**: small, opinionated defaults, validated inputs, outputs, docs, tested, no inner provider config.
- **Enterprise**: golden versioned modules enforce security/naming/tags.
