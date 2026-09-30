# DEEP MECHANICS · Istio

> Level 2 — the architecture (istiod + Envoy), the core CRDs (VirtualService/
> DestinationRule/Gateway), mTLS modes, and traffic-management patterns.

---

## 0. The precise mental model
Istio is the **most feature-rich service mesh**: a control plane (**istiod**) that programs **Envoy sidecars**, configured through a set of **CRDs** that declaratively control routing, resilience, security, and telemetry. Master the **four main CRDs** and **mTLS modes** and you can answer most Istio questions.

---

## 1. Architecture
- **istiod** (control plane) — service discovery, config distribution to proxies, **certificate authority** (issues workload certs for mTLS).
- **Envoy sidecars** (data plane) — intercept all Pod traffic, enforce routing/policy/mTLS.
- **Ingress/Egress Gateways** — Envoy at the mesh edge for in/out traffic.

## 2. The core CRDs (know these)
- **VirtualService** — **routing rules**: match (host/path/header) → route to subsets with **weights** (canary), plus retries, timeouts, fault injection, mirroring.
- **DestinationRule** — defines **subsets** (versions via labels) + traffic **policies** (load balancing, connection pool, **circuit breaking/outlier detection**).
- **Gateway** — configures the edge Envoy (ports, hosts, TLS) for ingress/egress.
- **PeerAuthentication / AuthorizationPolicy** — mTLS mode + **who-can-call-whom** authz.

## 3. Traffic management patterns
- **Canary** — VirtualService weights: 90% v1 / 10% v2, shift gradually.
- **Mirroring (shadow)** — send a copy of live traffic to a new version without affecting responses.
- **Fault injection** — inject delays/errors to test resilience.
- **Circuit breaking / outlier detection** — DestinationRule ejects failing hosts.
- Retries, timeouts per route.

## 4. Security (mTLS)
- **PeerAuthentication** modes: **STRICT** (mTLS required), **PERMISSIVE** (accept both — for migration), DISABLE.
- istiod is the **CA** issuing SPIFFE identities per workload → automatic, rotated certs.
- **AuthorizationPolicy** — L7 allow/deny based on identity, namespace, path, method → zero-trust.

## 5. Observability
Envoy emits metrics (Prometheus), distributed traces, and access logs for every request automatically → integrate Grafana/Kiali/Jaeger. Kiali visualizes the mesh topology.

## 6. AKS note
The **AKS Istio-based add-on** provides a Microsoft-managed, supported Istio control plane → less operational burden.

## 7. The hard follow-ups (with answers)
1. **"Istio architecture?"** → istiod control plane (discovery/config/CA) + Envoy sidecars (data plane) + gateways. (§1)
2. **"How do you do a canary in Istio?"** → VirtualService weighted routing across DestinationRule subsets. (§2,3)
3. **"VirtualService vs DestinationRule?"** → routing rules vs subset definitions + traffic policies (LB/circuit-breaking). (§2)
4. **"How is mTLS configured?"** → PeerAuthentication STRICT/PERMISSIVE; istiod issues workload certs (CA). (§4)
5. **"Test resilience without real failures?"** → fault injection (delays/errors) + traffic mirroring. (§3)
6. **"Restrict which services can call which?"** → AuthorizationPolicy (identity/namespace/path). (§4)

## 8. One-screen recall
- Istio = feature-rich mesh: **istiod** (control plane: discovery/config/**CA**) + **Envoy** sidecars + **gateways**.
- **CRDs**: **VirtualService** (routing/weights/retries/timeouts/fault/mirror), **DestinationRule** (subsets + LB/**circuit-breaking/outlier**), **Gateway** (edge TLS/hosts), **PeerAuthentication/AuthorizationPolicy** (mTLS + authz).
- **Canary** = VirtualService weights; **mirroring** = shadow traffic; **fault injection** = resilience testing.
- **mTLS**: STRICT/PERMISSIVE(migration); SPIFFE identities, auto-rotated.
- Auto metrics/traces/logs (Prometheus/Kiali/Jaeger). **AKS Istio add-on** = managed.

> Next: AKS Security.
