# DEEP MECHANICS · Pods

> Level 2 — what a Pod really is, shared network/storage namespace, multi-container
> patterns, lifecycle, and why you rarely create Pods directly.

---

## 0. The precise mental model
A Pod is the **smallest deployable unit** in Kubernetes — **one or more containers that share a network namespace (same IP) and can share storage**, always **co-scheduled on one node**. It's a "logical host" for tightly-coupled containers. Pods are **ephemeral and disposable**; you almost never create them directly — controllers (Deployments) manage them.

---

## 1. The shared namespace (the core idea)
Containers in a Pod share:
- **Network** — same **IP + port space**, reach each other on `localhost`. (Ports can't collide.)
- **IPC + optionally PID.**
- **Volumes** — mounted into multiple containers to share files.
This is enabled by the **pause container** (holds the namespaces). Different Pods = different IPs, communicate via Services.

## 2. Multi-container patterns
- **Sidecar** — helper alongside the main container (log shipper, proxy/service-mesh envoy). Most common.
- **Ambassador** — proxy external connections.
- **Adapter** — transform output (e.g., metrics format).
Use when containers are **tightly coupled and must share lifecycle/host**; otherwise separate Pods.

## 3. Lifecycle & probes
- Phases: Pending → Running → Succeeded/Failed.
- **Liveness probe** — restart container if it hangs.
- **Readiness probe** — remove from Service endpoints until ready (don't send traffic).
- **Startup probe** — for slow-starting apps (delays liveness).
- **initContainers** — run to completion **before** app containers (setup, migrations).

## 4. Resources & QoS
- **requests** (scheduling guarantee) + **limits** (hard cap). CPU over limit → throttled; memory over limit → **OOMKilled**.
- **QoS classes**: Guaranteed (req=limit), Burstable, BestEffort → eviction order under node pressure.

## 5. Why not create Pods directly (ephemeral)
A bare Pod isn't rescheduled if its node dies. **Controllers** (Deployment→ReplicaSet) maintain the desired count, replace failures, and enable rollouts. Always deploy via a controller.

## 6. The hard follow-ups (with answers)
1. **"What's a Pod?"** → smallest unit; ≥1 containers sharing network(IP)/storage, co-scheduled. (§0,1)
2. **"How do containers in a Pod talk?"** → same network namespace → `localhost` + shared volumes. (§1)
3. **"Liveness vs readiness?"** → restart-if-unhealthy vs remove-from-traffic-until-ready. (§3)
4. **"What's an initContainer for?"** → run setup/migrations to completion before app containers start. (§3)
5. **"Why not run bare Pods?"** → ephemeral, not rescheduled on node failure; use Deployments. (§5)
6. **"Memory over limit?"** → OOMKilled (CPU over limit = throttled). (§4)

## 7. One-screen recall
- Pod = **smallest unit**, ≥1 containers sharing **network(same IP)/IPC/volumes**, **co-scheduled** (pause container).
- **Patterns**: **sidecar** (proxy/logs), ambassador, adapter — for tightly-coupled containers.
- **Probes**: liveness (restart), readiness (traffic gate), startup (slow apps); **initContainers** first.
- **requests/limits**; over-mem = **OOMKilled**, over-CPU = throttled; **QoS** Guaranteed/Burstable/BestEffort.
- **Ephemeral** → always deploy via controllers (Deployment).

> Next: Deployments.
