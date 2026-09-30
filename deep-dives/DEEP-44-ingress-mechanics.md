# DEEP MECHANICS · Ingress

> Level 2 — L7 HTTP routing, the Ingress controller vs resource split, TLS
> termination, and Ingress vs Gateway API.

---

## 0. The precise mental model
Ingress = **L7 HTTP(S) routing into the cluster through a single entry point**. It has two parts: the **Ingress resource** (rules: which host/path → which Service) and the **Ingress controller** (the actual proxy — NGINX, App Gateway — that reads those rules and routes traffic). One load balancer fronts many services with **path/host routing + TLS**, instead of one LoadBalancer Service per app.

---

## 1. Resource vs controller (the key split)
- **Ingress resource** — declarative rules (`host: api.example.com, path: /v1 → service-a:80`). Just config; does nothing alone.
- **Ingress controller** — a Pod running a reverse proxy (NGINX, Traefik, **AGIC/App Gateway**) that **watches** Ingress resources and configures itself. **No controller = Ingress does nothing.**

## 2. Routing capabilities
- **Host-based** — route by domain (app1.com vs app2.com).
- **Path-based** — `/api` → api-svc, `/web` → web-svc.
- **TLS termination** — terminate HTTPS at the ingress using certs from **Secrets** (or Key Vault). Central cert management.
- Rewrites, redirects, rate limits (controller-specific annotations).

## 3. Traffic flow
```
Client → Cloud LB → Ingress Controller Pod (NGINX/AppGw)
       → matches host/path rule → Service (ClusterIP) → Pod
```
One external IP + one LB shared across all apps → cost + management savings vs many LoadBalancer Services.

## 4. On AKS
- **AGIC (Application Gateway Ingress Controller)** — App Gateway as the ingress (WAF, SSL) — Azure-native.
- **NGINX ingress** — common, flexible.
- **Application Gateway for Containers** — newer, Gateway API-based.

## 5. Ingress vs Gateway API (the evolution)
- **Ingress** — simple, HTTP-focused, controller-specific annotations for advanced features (fragmented).
- **Gateway API** — the successor: role-oriented (GatewayClass/Gateway/HTTPRoute), richer (traffic splitting, headers, multi-protocol), portable. Know it's replacing Ingress for advanced use.

## 6. The hard follow-ups (with answers)
1. **"Ingress resource vs controller?"** → rules (config) vs the proxy Pod that implements them; need both. (§1)
2. **"Why Ingress over LoadBalancer Services?"** → one shared L7 entry (host/path/TLS) vs one cloud LB+IP per service. (§0,3)
3. **"How is TLS handled?"** → terminate at ingress with cert from a Secret/Key Vault. (§2)
4. **"AKS ingress options?"** → AGIC (App Gateway+WAF), NGINX, App Gateway for Containers. (§4)
5. **"Ingress vs Gateway API?"** → simple HTTP + annotations vs role-oriented, richer, portable successor. (§5)

## 7. One-screen recall
- Ingress = **L7 HTTP router, single entry** = **resource (rules)** + **controller (proxy Pod: NGINX/AppGw)**; controller required.
- **Host/path routing + TLS termination** (cert from Secret/Key Vault) + rewrites.
- Flow: LB → controller → match rule → **Service → Pod**; one IP shared across apps (cost saving).
- AKS: **AGIC (App Gateway+WAF)**, NGINX, App Gateway for Containers.
- **Gateway API** = richer, portable successor to Ingress.

> Next: Helm.
