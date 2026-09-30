# DEEP MECHANICS · Terraform Best Practices

> Level 2 — structure, state/isolation, CI/CD, secrets, and safe-change practices
> for production Terraform.

---

## 0. The precise mental model
Production Terraform is about **safety, repeatability, and collaboration**: isolate state by blast radius, keep changes reviewable via **plan in CI**, never hardcode secrets, pin versions, and structure code with **modules + per-env configs**. The goal is that any change is **predictable and auditable**.

---

## 1. Code structure
- **Modules** for reusable components; **thin per-environment root configs** supplying values.
- Consistent file layout (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`).
- **Pin provider + module + Terraform versions** (`required_version`, `~>`) → reproducible.

## 2. State & isolation
- **Remote backend** (Azure blob) with **locking + encryption**.
- **Separate state per environment and per component/layer** → blast-radius isolation + smaller/faster plans.
- Protect state storage (RBAC, private endpoint, versioning) — it holds secrets.

## 3. Secrets management
- **Never** hardcode secrets or commit `.tfvars` with secrets / state to git.
- Pull secrets from **Key Vault** (data source) or inject via CI variables; use **Managed Identity/OIDC** for provider auth (no stored credentials).
- Mark sensitive variables/outputs `sensitive = true`.

## 4. CI/CD workflow
```
PR → terraform fmt + validate + tflint + plan (posted to PR for review)
   → security scan (tfsec/checkov)
   → merge → apply (via pipeline with least-privilege identity, OIDC)
```
- **Plan on PR, apply on merge** → human-reviewed, auditable changes.
- Pipeline identity is **least-privilege** and **keyless (OIDC/MI)**.

## 5. Safe changes
- Always **review the plan** before apply; watch for unexpected **destroy/replace**.
- Use **`moved` blocks** for refactors (rename without destroy); **`lifecycle`** (`prevent_destroy`, `create_before_destroy`, `ignore_changes`).
- **`-target`** and manual state ops (`state mv/rm`, imports) sparingly and carefully.
- Small, frequent changes over big-bang applies.

## 6. Quality & governance
- `fmt`, `validate`, **tflint**, **tfsec/checkov** (security), and **policy-as-code** (Sentinel/OPA) to enforce org rules.
- Document module interfaces; tag all resources (owner/env/cost center).

## 7. The hard follow-ups (with answers)
1. **"Structure a Terraform repo?"** → shared modules + thin per-env roots + pinned versions + consistent layout. (§1)
2. **"Manage secrets?"** → Key Vault/CI vars + MI/OIDC auth; never commit secrets/state; `sensitive`. (§3)
3. **"Safe change process?"** → plan on PR (reviewed) → apply on merge via least-privilege pipeline. (§4)
4. **"Rename a resource without destroying it?"** → `moved` block (or `state mv`). (§5)
5. **"Enforce org policy?"** → policy-as-code (Sentinel/OPA) + tfsec/checkov in CI. (§6)
6. **"Isolate blast radius?"** → separate state per env + per component. (§2)

## 8. One-screen recall
- **Structure**: shared **modules** + thin per-env roots; **pin versions**.
- **State**: remote backend (lock+encrypt), **separate per env + component**; protect state storage.
- **Secrets**: Key Vault/CI vars, **MI/OIDC** auth, never commit secrets/state, `sensitive`.
- **CI/CD**: fmt/validate/tflint/**plan on PR (review)** + tfsec/checkov → **apply on merge** (least-privilege OIDC).
- **Safe changes**: review plan (watch destroy/replace), **`moved` blocks**, lifecycle rules, small frequent changes.
- **Governance**: policy-as-code (Sentinel/OPA), tagging.

> Next: Terraform on Azure.
