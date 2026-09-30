# DEEP MECHANICS · Terraform Modules

> Level 2 — reusable composition, input/output contracts, module sources/
> versioning, and root vs child modules.

---

## 0. The precise mental model
A module is a **reusable, parameterized package of Terraform resources** — the unit of abstraction and DRY. You define infrastructure once (a "VNet module", an "AKS module") with **input variables** and **outputs**, then instantiate it many times with different inputs. Every Terraform config is itself the **root module**; it **calls child modules**.

---

## 1. Anatomy & contract
```
modules/vnet/
  variables.tf   # inputs (the contract)
  main.tf        # resources
  outputs.tf     # exported values (the contract)
```
- **Inputs (variables)** + **outputs** = the module's **public interface**. Consumers only see these, not internals → encapsulation.
- Keep modules **focused** (one logical component).

## 2. Calling modules
```hcl
module "network" {
  source  = "./modules/vnet"      # or registry/git
  address_space = "10.0.0.0/16"
}
# use module.network.subnet_id elsewhere
```
- **Root module** calls **child modules**; children can call grandchildren (compose).
- Pass outputs of one module as inputs to another to wire infrastructure.

## 3. Module sources & versioning
- **Sources**: local path, **Terraform Registry** (public/private), **git**, storage.
- **Pin versions** (`version = "~> 3.1"` for registry, git ref/tag) → reproducible, avoid surprise upgrades. Never use unpinned remote modules in prod.

## 4. count/for_each on modules
Instantiate a module multiple times (`for_each = var.environments`) → create N copies with different inputs (e.g., per-region). Enables scalable, DRY multi-instance infra.

## 5. Best practices
- **Thin root, rich modules** — root wires modules + provides env values; modules hold logic.
- Sensible **defaults** + **validation** on variables; **descriptions**; **outputs** for everything consumers need.
- Don't over-abstract early; extract a module when you repeat a pattern.
- Separate modules from environment configs (module = "what", env config = "with which values").

## 6. The hard follow-ups (with answers)
1. **"What's a module for?"** → reusable parameterized infra package; DRY + encapsulation via input/output contract. (§0,1)
2. **"Root vs child module?"** → the top config that calls modules vs the called reusable packages. (§2)
3. **"How do you wire modules together?"** → pass one module's outputs as another's inputs. (§2)
4. **"Why pin module versions?"** → reproducibility; avoid unexpected breaking upgrades. (§3)
5. **"Create per-environment copies?"** → for_each/count on the module with different inputs. (§4)
6. **"When to extract a module?"** → when a resource pattern repeats; don't over-abstract prematurely. (§5)

## 7. One-screen recall
- Module = **reusable parameterized infra package**; unit of DRY + encapsulation.
- **Contract = input variables + outputs** (public interface); keep modules focused.
- **Root module calls child modules**; wire via outputs→inputs; compose.
- **Sources**: local/registry/git; **pin versions** for reproducibility.
- **for_each/count** on modules → multi-instance (per-env/region).
- Best practice: **thin root + rich modules**, defaults/validation/descriptions, extract on repetition.

> Next: Terraform Workspaces.
