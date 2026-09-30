# 106 · Microsoft Entra ID (Azure AD)

> Domain: Security & Identity · Level: Principal Security / Identity Architect

## 1. Beginner Explanation
Microsoft Entra ID (formerly Azure Active Directory) is **Azure's cloud identity service**. It manages users, groups, and applications, and handles sign-in and access — it's how people and apps prove who they are and get permission to use Azure and Microsoft 365.

## 2. Architect-Level Explanation
The cloud identity + access management (IAM) control plane:
- **Tenant**: a dedicated identity directory (users, groups, apps, devices) — the security boundary.
- **Identities**: users (members/guests via **B2B**), **groups** (security/M365, dynamic), **service principals** + **app registrations** (app identities), **managed identities**.
- **AuthN protocols**: **OAuth 2.0 / OpenID Connect** (modern), SAML, WS-Fed; issues **tokens** (ID/access/refresh) with claims + scopes.
- **AuthZ**: app roles, scopes, groups, **Conditional Access** (policy engine: who/what/where/risk → grant/block/require MFA).
- **Security features**: **MFA**, **Conditional Access**, **Identity Protection** (risk-based), passwordless (FIDO2/Passkeys/Authenticator), **PIM** (just-in-time roles), Access Reviews, Entitlement Management.
- **SSO + federation**: single sign-on across apps; federate with on-prem AD (**Entra Connect**), external IdPs.
- **B2B/B2C**: guest collaboration (B2B) and customer identity (**Entra External ID / B2C**).
- **Zero Trust**: identity as the primary perimeter — verify explicitly, least privilege, assume breach.
- **vs on-prem AD**: cloud, protocol-based (not Kerberos/LDAP/OU); complementary.
- **Governance**: audit/sign-in logs, lifecycle, entitlement, access reviews.

## 3. Real Enterprise Use Case
An enterprise uses Entra ID as its identity backbone: employees SSO into Azure, M365, and SaaS; **Conditional Access** requires MFA + compliant device and blocks risky sign-ins (Identity Protection); **PIM** grants admin roles just-in-time with approval; **B2B** invites partners as guests governed by Access Reviews; apps authenticate via app registrations/managed identities using OIDC — a Zero Trust posture with full audit.

## 4. Architecture Diagram (ASCII)
```
        Entra ID Tenant (identity boundary)
   ┌──────────┬───────────┬──────────────┬────────────────┐
   Users/Guests Groups     Service         Managed
   (B2B)       (dynamic)   Principals/Apps  Identities
        │ sign-in (OIDC/OAuth2/SAML) → tokens (claims/scopes)
   Conditional Access (user/device/location/risk) ─► MFA / block / grant
   Identity Protection (risk) · PIM (JIT roles) · Access Reviews
   SSO ─► Azure · M365 · SaaS   | Entra Connect ⇄ on-prem AD
```

## 5. Interview Questions
1. What is Entra ID and how does it differ from on-prem AD?
2. Explain OAuth2/OIDC token flow at a high level.
3. What is Conditional Access?
4. Service principal vs app registration vs managed identity?
5. How does Entra ID support Zero Trust?

## 6. Strong Interview Answers
- **Entra vs AD**: "Entra ID is a cloud IAM service using modern protocols (OAuth2/OIDC/SAML) for apps and APIs, organized around a tenant. On-prem AD uses Kerberos/LDAP with OUs/GPOs for domain-joined machines. They're complementary — I federate/sync with **Entra Connect** for hybrid identity; Entra ID isn't just 'AD in the cloud'."
- **OIDC flow**: "The app redirects the user to Entra ID to authenticate; Entra issues an **ID token** (who the user is) and an **access token** (scopes/permissions for an API). The app validates the token's signature/issuer/audience and uses claims + scopes for authorization. Refresh tokens get new access tokens without re-login."
- **Conditional Access**: "A policy engine evaluating signals — user/group, device compliance, location, application, and sign-in **risk** — to decide grant, block, or require controls like MFA or a compliant device. It's the enforcement heart of Zero Trust at the identity layer."
- **SP vs app reg vs MI**: "An **app registration** defines an application (its config, redirect URIs, permissions) globally; a **service principal** is the app's identity instance in a tenant (what gets role assignments). A **managed identity** is a special auto-managed service principal for Azure resources with no credentials to handle — my default for Azure-to-Azure auth."
- **Zero Trust**: "Identity is the primary perimeter: verify explicitly (MFA, Conditional Access, device compliance), least privilege (RBAC + PIM just-in-time), and assume breach (Identity Protection risk detection, continuous evaluation, audit). Entra ID provides all these controls centrally."

## 7. Common Mistakes
- Treating Entra ID like on-prem AD (Kerberos/OU concepts).
- No MFA / weak Conditional Access → account compromise.
- Standing admin access instead of PIM JIT.
- Over-permissioned app registrations (excess API permissions).
- No access reviews for guests → stale external access.

## 8. Trade-offs
| Choice | Pro | Con |
|--------|-----|-----|
| Conditional Access strict | strong security | user friction if over-tuned |
| B2B guests | easy collaboration | governance needed |
| Passwordless | secure + UX | rollout effort |

## 9. Production Best Practices
- Enforce MFA + Conditional Access (device compliance, risk).
- PIM for privileged roles; Access Reviews for guests/roles.
- Least-privilege app permissions; managed identities over secrets.
- Identity Protection risk policies; passwordless/phishing-resistant MFA.
- Monitor sign-in/audit logs (SIEM/Sentinel); named break-glass accounts.

## 10. Security Considerations
- Phishing-resistant MFA (FIDO2/passkeys); block legacy auth.
- Conditional Access + continuous access evaluation; risk-based blocking.
- Least privilege + PIM + JIT; emergency (break-glass) accounts excluded from CA lockout.
- Secure app credentials (managed identity / cert over secrets); rotate.

## 11. Cost Optimization
- Right license tier (P1/P2 for CA/PIM/Identity Protection where needed).
- Managed identities eliminate secret-management overhead/cost.
- Group-based licensing + lifecycle to avoid orphaned licenses.

## 12. Troubleshooting Scenarios
- **Sign-in blocked** → Conditional Access policy; check sign-in logs (which policy).
- **Token audience/issuer invalid** → wrong app registration/scope config.
- **App can't get token** → SP missing/consent not granted/permissions.
- **Guest can't access** → B2B invite/consent/CA scoping.
- **Locked out of admin** → use break-glass account; review CA exclusions.

## 13. Hands-on Example
```bash
az ad app create --display-name "orders-api"          # app registration
az ad sp create --id <appId>                          # service principal
az ad app permission add --id <appId> --api <graphId> --api-permissions <scope>
```

## 14. Terraform Example
```hcl
resource "azuread_application" "api" { display_name = "orders-api" }
resource "azuread_service_principal" "api" { client_id = azuread_application.api.client_id }
resource "azuread_group" "engineers" {
  display_name = "engineers" security_enabled = true
  # dynamic membership / assigned members for RBAC + Conditional Access targeting
}
```

## 15. Azure Example
```bash
# Conditional Access: require MFA for admins (via Graph/portal; shown conceptually)
# signals: role=GlobalAdmin → grant: require MFA + compliant device
az rest --method POST --uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies" --body @ca-policy.json
```

## 16. FastAPI / Python Example
```python
# Validate an Entra ID access token (OIDC) in a FastAPI API
from fastapi import Depends, HTTPException
import jwt
from jwt import PyJWKClient
jwks = PyJWKClient("https://login.microsoftonline.com/<tenant>/discovery/v2.0/keys")

def verify(token: str):
    key = jwks.get_signing_key_from_jwt(token).key
    try:
        return jwt.decode(token, key, algorithms=["RS256"],
                          audience="api://orders", issuer="https://login.microsoftonline.com/<tenant>/v2.0")
    except jwt.PyJWTError:
        raise HTTPException(401, "invalid token")   # checks signature/aud/issuer
```

## 17. AKS Example
AKS uses Entra ID for **cluster RBAC** (kubectl access mapped to Entra groups) and **Workload Identity** (pods federate to Entra service principals via OIDC to get tokens for Azure resources — no secrets). Conditional Access can gate cluster admin access; sign-ins flow to Sentinel.

## 18. How to Remember
**"Cloud IAM: tenant + identities (users/groups/SPs/MI); OIDC tokens (claims/scopes); Conditional Access = policy engine; PIM = JIT roles; identity = Zero Trust perimeter."**

## 19. Real-World Analogy
A modern airport identity system: your passport + boarding pass (tokens) prove who you are and where you're allowed to go (scopes). Security checkpoints adapt to risk — extra screening for certain flags (Conditional Access/MFA), and staff only get restricted-area access for the shift they need it, with approval (PIM just-in-time), all logged.

## 20. One-Page Cheat Sheet
- **What**: cloud IAM control plane; **tenant** = identity boundary.
- **Identities**: users/guests (B2B), groups, service principals/app registrations, **managed identities**.
- **AuthN**: OAuth2/**OIDC**/SAML → tokens (ID/access/refresh) with claims + scopes.
- **AuthZ/Security**: **Conditional Access** (risk/device/location → MFA/block), Identity Protection, MFA/passwordless, **PIM** (JIT), Access Reviews.
- **Zero Trust**: verify explicitly, least privilege, assume breach; identity = primary perimeter.
- **Hybrid**: Entra Connect ⇄ on-prem AD; SSO to Azure/M365/SaaS.
