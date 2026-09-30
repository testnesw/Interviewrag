# DEEP MECHANICS · CI/CD Architecture

> Level 2 — CI vs CD, pipeline stages, artifact promotion, environment strategy,
> and quality gates.

---

## 0. The precise mental model
CI/CD is a **pipeline that turns a commit into a safely deployed release**. **CI** = integrate + build + test every commit → a versioned, immutable **artifact**. **CD** = promote that *same* artifact through environments with automated gates. Core principle: **build once, deploy many**; never rebuild per environment.

---

## 1. CI vs CD vs CD
- **Continuous Integration**: merge often → automated build + tests on each commit → fast feedback, avoid integration hell.
- **Continuous Delivery**: every change is **release-ready**; deploy to prod is a **manual approval** (button).
- **Continuous Deployment**: every green change auto-deploys to prod (no manual gate).

## 2. Pipeline stages
```
Source → Build → Test → Package(artifact) → Deploy(dev→test→prod) → Verify
```
- **Build once** → immutable artifact (container image / package) with a version tag.
- Same artifact promoted across envs; only **config** differs (env vars/secrets).

## 3. Artifact & environment promotion
- Artifact stored in a **registry** (ACR, package feed) — versioned, signed.
- **Promote** identical artifact dev → staging → prod; config injected per env.
- Rebuilding per env = anti-pattern (drift, "works in dev" bugs).

## 4. Quality gates (shift-left)
- **In CI**: unit tests, lint, **SAST** (code scan), dependency/SCA scan, secret scan, build.
- **Pre-deploy**: integration tests, **DAST**, image scan, IaC scan (tfsec), policy checks.
- **Post-deploy**: smoke tests, health checks, **canary/blue-green** verification.
- Fail fast; gates block promotion.

## 5. Deployment strategies (see also blue-green/canary)
- **Rolling**, **blue-green** (instant switch/rollback), **canary** (gradual %), **feature flags** (decouple deploy from release).

## 6. Principles
- **Automate everything**, version everything, immutable artifacts, fast feedback (<10 min CI ideal).
- **Trunk-based** or short-lived branches → frequent integration.
- **Least-privilege** deploy identities (OIDC); pipeline as code (versioned).
- **Observability**: metrics/logs/traces + automated rollback on SLO breach.

## 7. The hard follow-ups (with answers)
1. **"CI vs CD vs continuous deployment?"** → CI = build/test each commit; delivery = always releasable (manual prod); deployment = auto to prod. (§1)
2. **"Why build once, deploy many?"** → identical artifact across envs → eliminates env drift bugs; config injected. (§2/§3)
3. **"Where do security scans go?"** → SAST/SCA/secret in CI, DAST/image/IaC pre-deploy, smoke post-deploy (shift-left). (§4)
4. **"Rollback strategy?"** → blue-green (switch back) / canary (halt rollout) / previous artifact redeploy. (§5)
5. **"Decouple deploy from release?"** → **feature flags**. (§5)
6. **"Secure the pipeline identity?"** → least-privilege **OIDC**, pipeline as code. (§6)

## 8. One-screen recall
- **CI** = build+test each commit → immutable **artifact**; **CD** = promote same artifact via gates.
- **Build once, deploy many**; config per env, not rebuilds.
- **Stages**: source→build→test→package→deploy→verify.
- **Gates**: CI (unit/SAST/SCA/secret) → pre-deploy (integration/DAST/image/IaC) → post (smoke/canary).
- **Strategies**: rolling / blue-green / canary / feature flags.
- **Principles**: automate, version, immutable, fast feedback, trunk-based, OIDC, observability + auto-rollback.

> Next: Blue-Green Deployment.
