# DEEP MECHANICS · Secrets

> Level 2 — how K8s Secrets actually work (base64 not encryption), encryption at
> rest, mounting, and the CSI/Key Vault pattern.

---

## 0. The precise mental model
A Kubernetes Secret is an object for **sensitive data** (passwords, tokens, certs) that Pods consume as **env vars or mounted files**. The critical caveat: by default Secrets are only **base64-encoded, not encrypted** — stored in **etcd**. Real security requires **encryption at rest, RBAC, and ideally an external store (Key Vault via CSI)**. Interviewers love the "Secrets aren't secret by default" point.

---

## 1. What a Secret is (and isn't)
- Data is **base64-encoded** (encoding ≠ encryption — trivially reversible).
- Stored in **etcd**; anyone with etcd/API read access + RBAC can read it.
- Similar to ConfigMaps but intended for sensitive data (different handling/RBAC).

## 2. Securing Secrets (the real work)
- **Encryption at rest** — enable **etcd encryption** (KMS provider) so Secrets are encrypted on disk. On AKS, etcd is Microsoft-managed/encrypted, but enable **KMS with Key Vault** for customer-managed keys.
- **RBAC** — restrict who can `get` Secrets (least privilege).
- **Don't commit Secrets to git** (use sealed-secrets/SOPS or external store).
- Avoid env-var exposure (visible in process listings / crash dumps) → prefer mounted files.

## 3. Consuming Secrets
- **Env vars** — simple but leak-prone (child processes, logs).
- **Volume mount** — Secret as files in a tmpfs (memory) volume; supports **auto-update** on change (files) — preferred.
- **imagePullSecrets** — for private registry auth.

## 4. The CSI Secrets Store + Key Vault pattern (best practice)
**Secrets Store CSI Driver** mounts secrets **directly from Azure Key Vault** into Pods:
- Secrets live in **Key Vault** (rotation, audit, access policies), not etcd.
- Pod uses **Workload Identity** to fetch them → keyless.
- Optionally sync to a K8s Secret for env-var use.
This is the recommended AKS approach — central, rotated, audited secrets.

## 5. Secret types
`Opaque` (generic), `kubernetes.io/tls` (cert+key), `dockerconfigjson` (registry), `service-account-token`.

## 6. The hard follow-ups (with answers)
1. **"Are Kubernetes Secrets encrypted?"** → no — base64-encoded in etcd by default; enable **encryption at rest (KMS)**. (§1,2)
2. **"How do you secure them properly?"** → etcd encryption + RBAC + external store (Key Vault via CSI) + no git commits. (§2,4)
3. **"Env var vs volume mount?"** → mount preferred (tmpfs, auto-update, less leak-prone). (§3)
4. **"Best practice on AKS?"** → Secrets Store CSI Driver + Key Vault + Workload Identity (keyless, rotated, audited). (§4)
5. **"Secret vs ConfigMap?"** → both key-value, but Secret for sensitive data (separate RBAC, base64, can be encrypted). (§1)

## 7. One-screen recall
- Secret = sensitive key-value consumed as **env vars or mounted files**; **base64 ≠ encryption**, stored in **etcd**.
- Secure: **etcd encryption at rest (KMS/Key Vault)** + **RBAC least privilege** + no git + prefer **volume mount (tmpfs, auto-update)** over env vars.
- **Best practice (AKS): Secrets Store CSI Driver → Key Vault + Workload Identity** (keyless, rotated, audited).
- Types: Opaque, tls, dockerconfigjson, SA token.

> Next: ConfigMaps.
