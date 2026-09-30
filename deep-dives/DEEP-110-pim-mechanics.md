# DEEP MECHANICS · Privileged Identity Management (PIM)

> Level 2 — just-in-time roles, eligible vs active, activation controls, access
> reviews, and zero standing access.

---

## 0. The precise mental model
PIM implements **Just-In-Time (JIT) privileged access**: instead of users **permanently holding** admin roles (standing privilege = attack surface), they are made **eligible** and must **activate** the role for a **time-limited** window, subject to **MFA, justification, and approval**. Goal = **zero standing access** + full audit of privilege use.

---

## 1. Eligible vs active
- **Active assignment** = permission held now (standing access) — what plain RBAC gives.
- **Eligible assignment** = *can activate when needed* → no standing privilege until activated.
- PIM converts powerful roles to **eligible** → activated on demand for N hours.

## 2. Activation controls
- On activation, enforce: **MFA**, **justification** (text), **approval workflow** (approver must grant), optional **ticket number**, and a **time limit** (auto-expires).
- Reduces the window an admin credential is exploitable.

## 3. What PIM covers
- **Entra roles** (Global Admin, etc.), **Azure RBAC roles** (Owner/Contributor at scopes), and **PIM for Groups** (JIT group membership → any access the group grants).

## 4. Governance features
- **Access reviews** — periodic recertification: do these people still need this? → remove stale access.
- **Alerts** — e.g., too many Global Admins, roles activated outside policy, admins without MFA.
- **Audit log** — every eligibility, activation, approval → who had privilege, when, why.

## 5. Why it matters (zero trust)
- **Minimizes standing privilege** → smaller blast radius if an account is compromised.
- **Least privilege over time** (not just scope): privilege exists only during the task.
- Supports **separation of duties** (approver ≠ requester).

## 6. Requirements/notes
- Needs **Entra ID P2** (or Governance) licensing.
- Combine with **Conditional Access** (require compliant device/MFA to activate) and RBAC (scope).

## 7. The hard follow-ups (with answers)
1. **"What problem does PIM solve?"** → standing privileged access (persistent attack surface) → replace with **JIT eligible → activate**. (§0/§1)
2. **"Eligible vs active?"** → eligible = can activate when needed (no standing power); active = held now. (§1)
3. **"Controls at activation?"** → MFA + justification + **approval** + time limit + optional ticket. (§2)
4. **"Ensure people don't accumulate access?"** → **access reviews** (recertification). (§4)
5. **"JIT for group-based access?"** → **PIM for Groups**. (§3)
6. **"How does it support least privilege?"** → least privilege **in time** — privilege only during the task. (§5)
7. **"Licensing?"** → Entra ID **P2**. (§6)

## 8. One-screen recall
- **JIT privileged access** → **zero standing access**.
- **Eligible** (activate on demand, time-boxed) vs **active** (standing).
- **Activation**: MFA + justification + **approval** + expiry (+ ticket).
- **Covers**: Entra roles, Azure RBAC roles, **PIM for Groups**.
- **Governance**: **access reviews**, alerts, full **audit**.
- **Why**: smaller blast radius, least privilege over time, separation of duties; needs **P2**.

> Next: Microsoft Defender for Cloud.
