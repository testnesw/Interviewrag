# DEEP MECHANICS · Containerization

> Level 2 — the 12-factor principles, why containers enable microservices/cloud-
> native, statelessness, and container vs VM trade-offs.

---

## 0. The precise mental model
Containerization = **packaging an app with all its dependencies into a portable, isolated unit** so it runs identically across environments. It's the enabler of **cloud-native** (microservices, orchestration, CI/CD, elastic scaling). The mindset shift: apps become **stateless, disposable, horizontally scalable** units configured by the environment — the **12-factor** app.

---

## 1. Why containerize (the value)
- **Consistency** — "works on my machine" solved; same image dev→prod.
- **Portability** — runs on any container host/cloud.
- **Density/efficiency** — many containers per host (shared kernel) vs VMs.
- **Speed** — seconds to start → elastic scaling, fast deploys.
- **Isolation** — dependency conflicts gone (each app its own image).

## 2. 12-factor essentials (the design discipline)
- **Config in the environment** (not code) → same image, per-env config (ConfigMaps/env vars).
- **Stateless processes** → externalize state (DB/Redis/blob) → any instance handles any request → horizontal scale + disposability.
- **Disposability** — fast startup/graceful shutdown (handle SIGTERM); Pods can be killed/rescheduled anytime.
- **Logs to stdout/stderr** → collected by the platform (don't write log files).
- **Build/release/run** separation; **dev/prod parity**.

## 3. Container vs VM (the trade-off)
| | **Container** | **VM** |
|---|---|---|
| Isolation | process (namespaces/cgroups), shared kernel | full OS on hypervisor (stronger) |
| Size/start | MBs / seconds | GBs / minutes |
| Density | high | lower |
| Use | microservices, cloud-native | strong isolation, different OS kernels, legacy |
Containers trade some isolation for efficiency; use VMs (or sandboxed runtimes like Kata) where isolation is paramount.

## 4. Enabling microservices & orchestration
Containers make each microservice an independently deployable, scalable unit; orchestrators (Kubernetes) then schedule, scale, heal, and network them. Containerization + orchestration = cloud-native operating model.

## 5. Best practices
One concern per container, immutable images (no in-place patching — rebuild+redeploy), minimal base images, externalized config/state, health endpoints, resource limits, graceful shutdown.

## 6. The hard follow-ups (with answers)
1. **"Why containerize?"** → consistency, portability, density, fast elastic scaling, dependency isolation. (§1)
2. **"Why must containers be stateless?"** → so any instance serves any request → horizontal scale + disposability/rescheduling. (§2)
3. **"Container vs VM?"** → process isolation/shared kernel (light/fast) vs full OS/hypervisor (stronger isolation). (§3)
4. **"How do 12-factor apps handle config/logs?"** → config from env, logs to stdout/stderr collected by platform. (§2)
5. **"How does containerization enable microservices?"** → each service = independent deployable/scalable unit for orchestrators to manage. (§4)

## 7. One-screen recall
- Containerization = package app+deps into **portable isolated unit**; enabler of **cloud-native**.
- Value: **consistency, portability, density, speed, isolation**.
- **12-factor**: **config in env**, **stateless** (externalize state), **disposable** (fast start / SIGTERM), **logs to stdout**, build/release/run, dev-prod parity.
- **Container vs VM**: shared-kernel process isolation (light/fast) vs full-OS hypervisor (strong isolation).
- **Containers + orchestration = cloud-native**; immutable images, one concern, limits, health, graceful shutdown.

> Next: Image Optimization.
