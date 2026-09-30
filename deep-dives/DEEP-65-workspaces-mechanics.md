# DEEP MECHANICS · Terraform Workspaces

> Level 2 — what workspaces actually do (multiple states per config), their
> limits, and workspaces vs directory-per-env.

---

## 0. The precise mental model
A workspace lets **one Terraform configuration have multiple independent state files** — switch workspace and you operate on a different state (e.g., `dev`, `prod`) with the same code. It's a **lightweight way to reuse config across environments**, but it has real limitations that make many teams prefer **directory/backend-per-environment** for production.

---

## 1. How they work
- `terraform workspace new dev` / `select prod` → each workspace = a **separate state** under the same backend (e.g., a `env:/dev/` state path).
- Reference the current workspace via `terraform.workspace` (e.g., name resources or pick sizing by env).
- **Default** workspace always exists.

## 2. What they're good for
- Quick **ephemeral/parallel** environments (feature branches, test) from one config.
- Same code, isolated state per workspace → no duplication.

## 3. The limitations (why not for prod)
- **Same backend + same config** → harder to give environments **different backends, permissions, or provider configs** (prod should be isolated more strongly).
- **Easy to apply to the wrong workspace** (a `select` mistake → apply to prod) → risky.
- State is co-located → weaker blast-radius isolation than separate accounts.
- Doesn't handle structurally different environments well.

## 4. Workspaces vs directory-per-environment
| | **Workspaces** | **Directory/backend per env** |
|---|---|---|
| State | multiple in one backend | fully separate backends |
| Isolation | weaker (same config/creds) | strong (separate creds/backend) |
| Code reuse | high (one config) | via shared modules |
| Prod safety | riskier (wrong-workspace applies) | safer (explicit separation) |
| Use | ephemeral/test envs | production environments |
**Common guidance:** workspaces for transient/test; **separate directories + shared modules** for dev/staging/prod.

## 5. The hard follow-ups (with answers)
1. **"What does a workspace do?"** → gives one config multiple independent state files (per env). (§1)
2. **"How do you vary behavior per workspace?"** → `terraform.workspace` in expressions (naming/sizing). (§1)
3. **"Why avoid workspaces for prod?"** → same backend/creds, wrong-workspace apply risk, weaker isolation. (§3)
4. **"Preferred prod pattern?"** → directory/backend per environment + shared modules for reuse. (§4)
5. **"Good use for workspaces?"** → ephemeral/parallel test or feature environments. (§2)

## 6. One-screen recall
- Workspace = **multiple state files for one config**; switch via `select`, reference `terraform.workspace`.
- Good for **ephemeral/parallel test envs** (one config, isolated state, no duplication).
- **Limits**: same backend/creds/config → weak isolation + **wrong-workspace apply risk** → not ideal for prod.
- **Prod pattern: directory/backend-per-env + shared modules** (strong isolation, safer).

> Next: Terraform Best Practices.
