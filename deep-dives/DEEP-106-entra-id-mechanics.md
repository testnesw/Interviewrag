# DEEP MECHANICS · Microsoft Entra ID

> Level 2 — the identity provider, tokens (OIDC/OAuth2), app registrations,
> conditional access, and identity types.

---

## 0. The precise mental model
Entra ID (formerly Azure AD) is a **cloud identity provider (IdP)**: it **authenticates** principals and **issues tokens** that resources trust. It's the control plane for "who can access what" in Azure/M365 via **OAuth2/OIDC**. Authentication (**who you are**, Entra) is distinct from authorization (**what you can do**, RBAC). It's **identity-as-the-perimeter** for zero trust.

---

## 1. Core objects
- **Tenant** = an Entra directory instance (one org).
- **Users / Groups** — human identities; **service principals** — app identities; **managed identities** — Azure-managed app identities.
- **App registration** → creates an **application object** + **service principal** (an app's identity + its API permissions).

## 2. Protocols & tokens
- **OIDC** (authentication) → **ID token** (who the user is).
- **OAuth2** (authorization) → **access token** (permission to call an API); **refresh token** (get new access tokens).
- Tokens are **signed JWTs** (header/claims/signature); resources **validate signature + issuer + audience + expiry**.
- **Scopes** (delegated, on behalf of user) vs **app roles / application permissions** (app acting as itself).

## 3. Authentication flows
- **Authorization Code + PKCE** (web/SPA/mobile — user present).
- **Client credentials** (daemon/service — no user; app identity).
- **On-behalf-of** (API calls downstream API as the user).
- **Device code** (input-constrained devices).

## 4. Security controls
- **MFA** — second factor.
- **Conditional Access** — policy engine: *if* (user/group, app, device state, location, risk) *then* (allow / require MFA / block) → core zero-trust enforcement.
- **Identity Protection** — risk-based detection (leaked creds, impossible travel).
- **PIM** (just-in-time privileged roles — see its own topic).

## 5. Identity types for apps (key for Azure)
- **Managed Identity** (system/user-assigned) → no secrets; Azure rotates credentials → preferred for service-to-service + Key Vault.
- **Service principal w/ secret/cert** → when MI isn't possible; rotate + store in Key Vault.
- Prefer **workload identity federation (OIDC)** for external CI (GitHub/K8s) → no stored secrets.

## 6. Entra vs on-prem AD
- Entra = cloud, **HTTP/REST protocols** (OIDC/OAuth2/SAML), flat, internet-facing.
- AD DS = on-prem, **Kerberos/LDAP**, OUs/GPO. **Entra Connect** syncs them (hybrid).

## 7. The hard follow-ups (with answers)
1. **"Authentication vs authorization here?"** → Entra authenticates + issues tokens (authN); **RBAC** authorizes actions (authZ). (§0)
2. **"ID token vs access token?"** → ID = who the user is (OIDC); access = permission to call an API (OAuth2). (§2)
3. **"App registration creates what?"** → application object + **service principal** (the app's identity). (§1)
4. **"Daemon with no user?"** → **client credentials** flow (app identity). (§3)
5. **"Enforce MFA only from risky logins?"** → **Conditional Access** policy (+ Identity Protection risk). (§4)
6. **"Best app identity in Azure?"** → **Managed Identity** (no secrets, auto-rotated). (§5)
7. **"How does a resource trust a token?"** → validate JWT signature + issuer + audience + expiry. (§2)

## 8. One-screen recall
- **Cloud IdP**: authenticates principals, issues **signed JWT** tokens; identity = perimeter.
- **Objects**: tenant, users/groups, **service principals**, managed identities; **app registration** → SP.
- **Tokens**: OIDC **ID token** (who) + OAuth2 **access token** (API perm) + refresh; scopes (delegated) vs app roles (app).
- **Flows**: auth-code+PKCE, **client credentials**, OBO, device code.
- **Controls**: MFA, **Conditional Access**, Identity Protection, PIM.
- **App identity**: **Managed Identity** > SP secret; workload identity federation for CI.

> Next: Key Vault.
