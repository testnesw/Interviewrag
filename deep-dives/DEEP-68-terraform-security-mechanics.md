# DEEP MECHANICS · Terraform Security

> Level 2 — securing state, credentials, scanning, and least-privilege for IaC.

---

## 0. The precise mental model
Terraform security has three fronts: **(1) protect state** (it stores secrets in plaintext), **(2) protect credentials** (auth keyless, least-privilege), and **(3) shift-left scanning** (catch insecure resource config before apply). Add **policy-as-code** to enforce guardrails.

---

## 1. State security (the #1 risk)
- State = **plaintext secrets** (passwords, keys, connection strings).
- **Never commit state to git.** Use remote backend with:
  - **Encryption at rest** + in transit.
  - **RBAC** on the storage container; **private endpoint**; firewall.
  - **Versioning + soft delete** for recovery; **locking** to prevent corruption.
- Limit who can read state → they can read all secrets.

## 2. Credential security
- **Keyless auth**: OIDC/Workload Identity Federation (CI) or Managed Identity (on Azure) — no stored secrets.
- If using a Service Principal: **least-privilege** scope, short-lived, rotate; store in **Key Vault/CI secret store**, never in `.tf`/`.tfvars`.
- Pull runtime secrets from **Key Vault data sources**, not literals.

## 3. Secrets in code
- Mark variables/outputs **`sensitive = true`** → redacts from CLI/logs (not from state).
- Don't put secrets in **plan output/logs**; be careful with `output`.
- `.gitignore`: `*.tfstate`, `*.tfvars` (if secret), `.terraform/`.

## 4. Static scanning (shift-left)
- **tfsec / checkov / terrascan** in CI → detect insecure config (public storage, open NSG `0.0.0.0/0`, unencrypted disks, no TLS).
- **tflint** for provider-specific correctness + best practices.
- Fail the pipeline on high-severity findings.

## 5. Policy-as-code (enforce at plan/apply)
- **Sentinel** (HCP Terraform) or **OPA/Conftest** → org rules: "all storage private", "required tags", "approved regions/SKUs".
- Runs against the **plan** → blocks non-compliant changes before apply.
- Complements Azure Policy (which enforces at the platform level too).

## 6. Supply chain
- **Pin** provider + module versions + checksums (`.terraform.lock.hcl` committed).
- Use **trusted module sources** (AVM, verified registry); review third-party modules.

## 7. The hard follow-ups (with answers)
1. **"Biggest Terraform security risk?"** → **state stores secrets in plaintext** → protect/never commit it. (§1)
2. **"Does `sensitive = true` encrypt secrets?"** → No — only **redacts from CLI/log output**; state is still plaintext. (§3)
3. **"Catch an open NSG before deploy?"** → **tfsec/checkov** in CI (shift-left scan). (§4)
4. **"Enforce 'all storage must be private'?"** → **policy-as-code** (Sentinel/OPA) on the plan + Azure Policy. (§5)
5. **"Auth without storing secrets?"** → **OIDC/Managed Identity**, least-privilege. (§2)
6. **"Pin dependencies?"** → version constraints + committed **`.terraform.lock.hcl`**. (§6)

## 8. One-screen recall
- **State** = plaintext secrets → remote backend, encrypt, RBAC, private endpoint, versioning, lock; **never commit**.
- **Creds** = **OIDC/MI**, least-privilege, rotate; secrets from **Key Vault**, never in code.
- **`sensitive`** redacts logs, **not** state.
- **Scan**: **tfsec/checkov/terrascan** + tflint in CI, fail on high severity.
- **Policy-as-code**: **Sentinel/OPA** on plan + Azure Policy.
- **Supply chain**: pin versions + lock file, trusted modules (AVM).

> Next: REST APIs.
