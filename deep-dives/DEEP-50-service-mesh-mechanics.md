# DEEP MECHANICS · Service Mesh

> Level 2 — the sidecar/data-plane vs control-plane model, what a mesh gives you
> (mTLS, traffic mgmt, observability), and the cost/ambient-mesh evolution.

---

## 0. The precise mental model
A service mesh is a **dedicated infrastructure layer for service-to-service communication**. It injects a **proxy (sidecar) next to every Pod** that transparently intercepts all traffic, so you get **mTLS, retries, traffic splitting, and observability without changing app code**. A **control plane** configures all the proxies. The mesh moves cross-cutting network concerns **out of the app and into the platform**.

---

## 1. Data plane vs control plane
- **Data plane** — the **sidecar proxies** (Envoy) in every Pod that intercept inbound/outbound traffic and enforce policy. This is where traffic actually flows.
- **Control plane** — (Istiod, etc.) configures/distributes policy + certs to the proxies, holds the service registry. No traffic flows through it.

## 2. What you get (the value)
- **mTLS everywhere** — automatic mutual TLS between services → encryption + identity (zero-trust) with no app changes.
- **Traffic management** — canary/blue-green via **weighted routing**, retries, timeouts, circuit breaking, fault injection.
- **Observability** — automatic metrics/traces/logs for every call (golden signals) since the proxy sees all traffic.
- **Policy** — authz (who can call whom), rate limiting.

## 3. How interception works
A sidecar (Envoy) is injected (auto via namespace label); **iptables rules redirect** the Pod's traffic through the proxy. The app thinks it's calling the service directly; the proxy handles TLS/routing/retries. Transparent to the app.

## 4. The cost (why not always use one)
- **Resource overhead** — a proxy per Pod (CPU/memory/latency per hop).
- **Complexity** — another distributed system to operate/debug.
- Use a mesh when you have **many services** needing uniform mTLS/traffic control/observability; for a few services it's overkill (libraries or ingress may suffice).

## 5. Ambient mesh (the evolution)
**Istio Ambient / sidecar-less** meshes remove the per-Pod sidecar (use a per-node **ztunnel** for mTLS + optional waypoint proxies for L7) → **lower overhead**, easier ops. Know this is the direction addressing the sidecar cost.

## 6. Options on Azure
- **Istio** (AKS **Istio-based add-on**, managed), **Linkerd** (lightweight), **Open Service Mesh** (retired), **Cilium/eBPF** service mesh (sidecar-less via eBPF).

## 7. The hard follow-ups (with answers)
1. **"What does a service mesh give you?"** → mTLS, traffic mgmt (canary/retries/CB), observability — no app code changes. (§2)
2. **"Data plane vs control plane?"** → sidecar proxies carrying traffic vs config/cert distribution (no traffic). (§1)
3. **"How is traffic intercepted?"** → sidecar injected + iptables redirect; transparent to app. (§3)
4. **"Cost of a mesh?"** → per-Pod proxy overhead + operational complexity → only worth it at scale. (§4)
5. **"How do you do canary with a mesh?"** → weighted routing (e.g., 90/10) between service versions. (§2)
6. **"What's ambient mesh?"** → sidecar-less (ztunnel + waypoints) to cut overhead. (§5)

## 8. One-screen recall
- Service mesh = infra layer for service-to-service comms via **per-Pod sidecar proxy (Envoy)**; app-transparent.
- **Data plane** (sidecars carry traffic) vs **control plane** (Istiod configures/certs, no traffic).
- Value: **automatic mTLS (zero-trust)**, **traffic mgmt** (weighted canary/retries/timeouts/circuit-breaking/fault-injection), **observability** (metrics/traces), policy/authz.
- Interception via **iptables redirect** to sidecar.
- **Cost**: per-Pod proxy overhead + complexity → use at **many-services** scale.
- **Ambient/sidecar-less** (ztunnel+waypoint, eBPF) = lower overhead. AKS **managed Istio add-on**.

> Next: Istio.
