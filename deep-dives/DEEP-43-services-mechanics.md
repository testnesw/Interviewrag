# DEEP MECHANICS · Services

> Level 2 — stable virtual IPs, the four Service types, kube-proxy/iptables,
> endpoints, and DNS-based discovery.

---

## 0. The precise mental model
A Service gives a **stable virtual IP + DNS name** in front of a set of **ephemeral Pods** (selected by labels), load-balancing across the **healthy, ready** ones. Pods come and go with changing IPs; the Service is the **durable address** clients use. It's how you get **discovery + load balancing** in Kubernetes.

---

## 1. How it works (ClusterIP + Endpoints)
- Service has a stable **ClusterIP** (virtual, never changes).
- A **selector** matches Pod labels → the **EndpointSlice/Endpoints** object tracks the current **ready** Pod IPs (readiness probes gate membership).
- **kube-proxy** programs **iptables/IPVS** rules on every node so traffic to the ClusterIP is DNAT'd to a Pod IP (random/round-robin). No process in the data path — it's kernel routing.

## 2. The four Service types
- **ClusterIP** (default) — internal-only virtual IP. Pod-to-Pod/service.
- **NodePort** — opens a port on **every node** → external access via node IP:port. Basic/dev.
- **LoadBalancer** — provisions a **cloud load balancer** (Azure LB) with a public/private IP → production external L4 access.
- **ExternalName** — CNAME to an external DNS name (no proxying).

## 3. DNS-based discovery
CoreDNS gives every Service a name: `mysvc.namespace.svc.cluster.local`. Apps connect by name → resolves to ClusterIP → load-balanced to Pods. **Headless Service** (`clusterIP: None`) returns Pod IPs directly (for StatefulSets/DBs needing per-Pod addressing).

## 4. Service vs Ingress
- **Service (LoadBalancer)** — **L4** per-service external IP; one LB per service (costly at scale).
- **Ingress** — **L7** HTTP router sharing **one** entry point across many services (path/host routing, TLS). Use Ingress for HTTP; Service/LoadBalancer for L4 or as Ingress backend. (See Ingress deep dive.)

## 5. Traffic policies & session affinity
- **externalTrafficPolicy: Local** — preserve client source IP + avoid extra hop (only routes to Pods on the receiving node).
- **sessionAffinity: ClientIP** — sticky by source IP.

## 6. The hard follow-ups (with answers)
1. **"Why do you need a Service?"** → Pods are ephemeral (changing IPs); Service = stable IP/DNS + load balancing over ready Pods. (§0,1)
2. **"How does traffic reach a Pod?"** → kube-proxy iptables/IPVS DNATs ClusterIP → a ready Pod IP (from Endpoints). (§1)
3. **"Four types?"** → ClusterIP (internal), NodePort (node port), LoadBalancer (cloud LB), ExternalName (CNAME). (§2)
4. **"How does discovery work?"** → CoreDNS name svc.ns.svc.cluster.local → ClusterIP. (§3)
5. **"Service vs Ingress?"** → L4 per-service IP vs L7 shared HTTP router (path/host/TLS). (§4)
6. **"Preserve client IP?"** → externalTrafficPolicy: Local. (§5)

## 7. One-screen recall
- Service = **stable ClusterIP + DNS** over ephemeral Pods, LB across **ready** Pods (Endpoints gated by readiness).
- **kube-proxy** programs **iptables/IPVS** → DNAT ClusterIP→Pod IP (kernel, no data-path process).
- **Types**: **ClusterIP** (internal) · **NodePort** · **LoadBalancer** (cloud LB) · **ExternalName**.
- **CoreDNS**: `svc.ns.svc.cluster.local`; **headless** (None) → Pod IPs for StatefulSets.
- **vs Ingress**: L4 per-service vs L7 shared HTTP router. `externalTrafficPolicy: Local` preserves client IP.

> Next: Ingress.
