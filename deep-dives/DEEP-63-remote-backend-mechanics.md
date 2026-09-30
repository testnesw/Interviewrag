# DEEP MECHANICS · Terraform Remote Backend

> Level 2 — why remote state, locking, the Azure blob backend, and state
> isolation patterns.

---

## 0. The precise mental model
A backend defines **where Terraform state lives and how operations run**. **Local** state (a file on disk) breaks teams — no sharing, no locking, easy to lose, secrets in plaintext on a laptop. A **remote backend** (Azure Storage blob, Terraform Cloud) stores state **centrally with locking and encryption** so a team can collaborate safely. This is mandatory for real/team use.

---

## 1. Why remote (problems with local state)
- **No collaboration** — state on one machine.
- **No locking** — two applies at once corrupt state.
- **Loss risk** — laptop dies, state gone → Terraform loses track of infra.
- **Secrets exposed** — state contains sensitive values in plaintext.
Remote backend fixes all four.

## 2. The Azure blob backend
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatexyz"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```
- State stored as a **blob**; **encrypted at rest**; access via **Entra/Managed Identity** (not keys).
- **State locking via blob lease** — Azure Storage provides the lock automatically (no separate lock table needed, unlike some clouds).

## 3. Locking (prevents corruption)
- Before a write op, Terraform acquires a **lock** (blob lease). Concurrent applies are blocked → serialized → no state corruption.
- **force-unlock** only if a lock is stuck (crash) — carefully.

## 4. State isolation (the pattern)
- **Separate state per environment** (dev/staging/prod) via different **keys**/containers/storage accounts → blast-radius isolation (a prod apply can't touch dev).
- **Separate state per component/layer** (networking vs app) → smaller state, faster plans, team ownership. Wire them together with **remote state data sources** (`terraform_remote_state`) or outputs.

## 5. Bootstrapping & security
- The backend storage itself is often created by a small **bootstrap** config (chicken-and-egg).
- Lock down the state storage: private endpoint, RBAC, versioning (recover bad state), soft delete. State = crown jewels (has secrets).

## 6. The hard follow-ups (with answers)
1. **"Why not local state?"** → no collaboration/locking, loss risk, plaintext secrets. (§1)
2. **"How does the Azure backend lock state?"** → blob lease — automatic, no separate lock table. (§2,3)
3. **"Two engineers apply at once?"** → second blocked by the lock until the first finishes → no corruption. (§3)
4. **"Isolate prod from dev state?"** → separate state (key/container/account) per env → blast-radius isolation. (§4)
5. **"Share values between states?"** → outputs + `terraform_remote_state` data source. (§4)
6. **"Secure the state?"** → private endpoint + RBAC + versioning/soft delete (it holds secrets). (§5)

## 7. One-screen recall
- Backend = **where state lives + how ops run**; **local breaks teams** (no share/lock, loss, plaintext secrets).
- **azurerm backend** = state blob, **encrypted**, **Entra/MI** auth, **locking via blob lease** (automatic).
- **Locking** serializes writes → no corruption; `force-unlock` only for stuck locks.
- **State isolation**: separate state per **env** and per **component** (blast radius, faster plans); link via **`terraform_remote_state`**.
- Protect state storage (private endpoint, RBAC, versioning) — it contains secrets.

> Next: Terraform Modules.
