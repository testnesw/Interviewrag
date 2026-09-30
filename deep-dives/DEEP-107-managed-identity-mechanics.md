# DEEP MECHANICS · Managed Identity & Entra ID

> Level 2 — how tokens are actually acquired, OAuth2/OIDC flows, system vs
> user-assigned MI internals (IMDS), workload identity federation, and how
> RBAC is evaluated — plus how to debug a 403.

---

## 0. The precise mental model
**Entra ID** (formerly Azure AD) is the **identity provider (IdP)** — it authenticates principals and issues **JWT access tokens**. **Authorization** (what you can do) is a *separate* system: **Azure RBAC** on resources. **Managed Identity** is an Entra identity for an Azure resource so your code gets tokens **without storing any secret** — the platform manages the credential. The whole model: **AuthN (Entra issues a token) → present token → AuthZ (RBAC decides) → allow/deny.** Keep AuthN and AuthZ mentally separate — most confusion comes from conflating them.

---

## 1. AuthN vs AuthZ — the split you must articulate
- **Authentication (AuthN)** = *who are you* → Entra ID validates credentials → issues an **access token** (JWT).
- **Authorization (AuthZ)** = *what may you do* → **Azure RBAC** checks role assignments on the target resource.

A valid token proves identity; it does **not** grant access. A `401` = bad/missing token (AuthN). A `403` = authenticated but **no role** (AuthZ). This distinction is the single most-tested concept.

---

## 2. The token — what's inside and why it matters
An Entra **access token** is a **JWT** (base64 header.payload.signature):
- **`aud`** (audience) — the resource the token is for (e.g., `https://storage.azure.com`). Wrong audience = rejected.
- **`iss`** (issuer) — your Entra tenant.
- **`oid`** (object id) — the principal (the MI's identity).
- **`roles`/`scp`** — app roles / delegated scopes.
- **`exp`** — expiry (~1 hour) → tokens are short-lived; refresh as needed.
- **Signature** — signed by Entra; the resource validates it against Entra's public keys (no shared secret needed).

**Deep follow-up: "How does Storage trust a token it never issued?"**
The token is **signed by Entra**; Storage validates the signature using Entra's published public keys (JWKS), checks `aud`=storage, `iss`=trusted tenant, and `exp`. Trust is via signature validation, not a shared secret.

---

## 3. Managed Identity internals — how code gets a token with no secret
Two types:
- **System-assigned** — tied to **one resource**, lifecycle-bound (deleted with it). 1:1.
- **User-assigned** — a **standalone** resource you assign to **many** resources. Reusable, decoupled lifecycle. Preferred at scale.

**How it works (the IMDS mechanism):**
```
Your code (DefaultAzureCredential)
   → calls IMDS endpoint http://169.254.169.254/.../token?resource=...
   → Azure platform authenticates the resource's identity
   → returns a JWT access token (cached ~ until exp)
   → code calls Storage/Key Vault with "Authorization: Bearer <token>"
```
`169.254.169.254` is the **non-routable Instance Metadata Service** address, reachable only from within the VM/host. No secret ever lives in your code or config — the **platform holds the credential**. That's the entire value proposition.

**Deep follow-up: "Where does the secret live with Managed Identity?"**
Nowhere in your app. Azure's platform manages a credential for the identity; your code asks the local IMDS endpoint for a token. Nothing to store, rotate, or leak — this is why MI beats storing keys/connection strings.

---

## 4. DefaultAzureCredential — the chain
`DefaultAzureCredential` tries credential sources **in order** and uses the first that works:
```
Environment vars → Managed Identity → Azure CLI (dev) → VS/VS Code → ...
```
Result: **same code** runs locally (uses your `az login`) and in Azure (uses MI). This is the recommended, keyless pattern.

**Deep follow-up: "Why does it work locally without a Managed Identity?"**
The chain falls back to your **Azure CLI login** locally, and to **MI** in Azure. One code path, environment-appropriate credential.

---

## 5. Workload Identity Federation — MI beyond Azure (AKS, GitHub)
For workloads that can't have an Azure MI directly (Kubernetes pods, GitHub Actions), **federation** lets an **external OIDC token** be exchanged for an Entra token — **no secret**:
- **AKS Workload Identity** — the pod's **Kubernetes service account** has a **federated credential**; its projected OIDC token is exchanged with Entra for an Azure access token. Pod → Azure resources, keyless.
- **GitHub Actions OIDC** — the workflow's OIDC token is federated to an Entra app registration → deploy to Azure with **no stored secret**.

**Mechanism:** you register a **federated credential** on the identity trusting an external issuer + subject. Entra validates the external OIDC token and issues its own.

**Deep follow-up: "How does an AKS pod access Key Vault without secrets?"**
Workload Identity: the pod's service account has a federated credential; its projected OIDC token is exchanged with Entra for an access token; the pod calls Key Vault with that Bearer token. RBAC on the vault authorizes it. Fully keyless.

---

## 6. RBAC evaluation — how allow/deny is computed
A **role assignment** = **security principal** + **role definition** (set of `Actions`/`DataActions`) + **scope** (mgmt group → subscription → RG → resource).
Evaluation:
1. Gather all assignments applicable to the principal at the requested scope **and inherited** from higher scopes.
2. **Deny assignments** win over allows (explicit deny always blocks).
3. Otherwise, if any role grants the required `Action`/`DataActions`, **allow**; else **deny (403)**.
- **Roles are additive**; there's no "allow" that overrides a deny.
- **Inheritance** flows downward (assign at RG → applies to all resources in it).
- `DataActions` govern **data-plane** (e.g., read a blob) vs `Actions` for **control-plane** (manage the resource) — a common gotcha.

**Deep follow-up: "MI has Reader but gets 403 reading a blob — why?"**
Reader is **control-plane** (`Actions`); reading blob *data* needs a **data-plane** role like **Storage Blob Data Reader** (`DataActions`). Wrong role family → 403 even though it "looks" readable in the portal.

---

## 7. Debugging a 403 — the checklist interviewers want
1. **AuthN ok?** Is it 401 (token) or 403 (role)? 403 = authenticated, missing permission.
2. **Right identity?** Which principal (`oid`) is the call using — correct MI assigned?
3. **Role + scope** — is the needed role assigned at a scope that covers the resource?
4. **Data vs control plane** — data operations need `DataActions` roles.
5. **Audience** — token `aud` matches the resource.
6. **Propagation** — new assignments/tokens can take minutes; token cached with old claims → refresh.
7. **Networking** — sometimes it's actually a firewall/Private Endpoint block, not RBAC.

---

## 8. The hard follow-up questions (with answers)
1. **"AuthN vs AuthZ?"** → Entra issues token (who); RBAC authorizes (what). 401=token, 403=role. (§1)
2. **"What's in the token?"** → JWT: aud, iss, oid, roles/scp, exp, Entra signature. (§2)
3. **"Where's the secret in MI?"** → nowhere in app; platform holds it, code asks IMDS. (§3)
4. **"System vs user-assigned MI?"** → system=1:1 lifecycle-bound; user-assigned=standalone, shareable. (§3)
5. **"How does DefaultAzureCredential work locally + cloud?"** → credential chain: CLI login locally, MI in Azure. (§4)
6. **"AKS pod → Key Vault keyless?"** → Workload Identity federation: SA OIDC token → Entra token → Bearer. (§5)
7. **"How is RBAC evaluated?"** → additive roles, inherited by scope, **deny wins**; needs matching Action/DataAction. (§6)
8. **"Reader role but 403 on blob data?"** → need data-plane role (Storage Blob Data Reader), not control-plane Reader. (§6)

---

## 9. One-screen deep-recall sheet
- **Entra ID = IdP** (AuthN, issues JWT). **Azure RBAC = AuthZ** (separate). **401=token, 403=role.**
- **Token** = JWT: `aud` (resource), `iss` (tenant), `oid` (principal), `roles/scp`, `exp`(~1h), **Entra signature** → resource validates via public keys (no shared secret).
- **Managed Identity** = Entra identity for a resource, **secret held by platform**. Code calls **IMDS `169.254.169.254`** → gets Bearer token. **System-assigned** (1:1, lifecycle-bound) vs **user-assigned** (standalone, shareable).
- **DefaultAzureCredential** = chain (env → MI → CLI...) → same code local + cloud.
- **Workload Identity Federation** = exchange external **OIDC** token (AKS SA / GitHub Actions) for Entra token → keyless beyond Azure.
- **RBAC** = principal + role (Actions/**DataActions**) + scope; **additive**, **inherited** downward, **deny wins**. Control-plane (`Actions`) vs data-plane (`DataActions`) — Reader ≠ blob data read.
- **403 debug**: identity? role+scope? data vs control plane? audience? propagation delay? (or actually networking).

---

> Next: **Observability / OpenTelemetry**.
