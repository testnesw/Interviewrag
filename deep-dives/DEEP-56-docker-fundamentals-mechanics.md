# DEEP MECHANICS · Docker Fundamentals

> Level 2 — images vs containers, layers + union filesystem, namespaces/cgroups,
> the build/run lifecycle, and how isolation actually works.

---

## 0. The precise mental model
Docker packages an app + its dependencies into an **image** (immutable, layered template) that runs as a **container** (an isolated process using the host kernel). Containers aren't VMs — they **share the host kernel** and are isolated by Linux **namespaces** (what they see) and **cgroups** (what they can use). Lightweight, fast, portable "it runs the same everywhere."

---

## 1. Image vs container
- **Image** — read-only, **layered** template (built from a Dockerfile). Immutable, versioned by tags/digests.
- **Container** — a **running instance** of an image with a thin **writable layer** on top. Ephemeral; delete it and the writable layer is gone (persist via volumes).

## 2. Layers & union filesystem (why builds are fast)
- Each Dockerfile instruction (`RUN`, `COPY`) = a **cached layer**. Layers are **stacked** via a **union filesystem** (overlayfs) into one view.
- **Build cache**: unchanged layers are reused → order matters (put rarely-changing steps first, `COPY package.json` before source so deps cache).
- Layers are **shared** across images → storage/pull efficiency.

## 3. How isolation works (not a VM)
- **Namespaces** — isolate what a container *sees*: PID, network, mount, UTS, IPC, user → its own process tree, network stack, filesystem view.
- **cgroups** — limit what it *uses*: CPU, memory, I/O.
- **Shared kernel** — no guest OS → seconds to start, MBs not GBs (vs VMs which virtualize hardware with a full OS).

## 4. The lifecycle
```
Dockerfile → docker build → Image → docker push → Registry
Registry → docker pull → docker run → Container (writable layer)
```
`run` = create + start; container runs until its main process (PID 1) exits.

## 5. Networking & storage
- **Networking**: bridge (default), host, none, overlay (multi-host). Port mapping `-p host:container`.
- **Storage**: **volumes** (managed, persistent, preferred) vs bind mounts (host path) vs tmpfs (memory). Container writable layer is ephemeral.

## 6. Key concepts
- **ENTRYPOINT vs CMD** — the executable vs default args.
- **EXPOSE** documents ports; **ENV** sets env vars; **WORKDIR** sets cwd.
- **One process per container** (ideally); PID 1 signal handling matters (use proper init/`--init` to reap zombies).

## 7. The hard follow-ups (with answers)
1. **"Image vs container?"** → immutable layered template vs running instance with a writable layer. (§1)
2. **"Container vs VM?"** → shares host kernel, namespace/cgroup isolation (light, fast) vs full guest OS on a hypervisor. (§3)
3. **"How is isolation achieved?"** → namespaces (visibility) + cgroups (resources). (§3)
4. **"Why order Dockerfile steps carefully?"** → layer build cache; put stable steps first (copy deps before source). (§2)
5. **"Persist data?"** → volumes (writable layer is ephemeral). (§5)
6. **"ENTRYPOINT vs CMD?"** → the executable vs default/overridable args. (§6)

## 8. One-screen recall
- **Image** = immutable **layered** template (Dockerfile); **container** = running instance + **writable layer** (ephemeral).
- **Layers + union FS (overlay)** + **build cache** → order steps stable-first (deps before source); layers shared.
- Isolation = **namespaces (what it sees: PID/net/mount/...)** + **cgroups (what it uses: CPU/mem)**; **shares host kernel** → fast/small vs VM.
- Lifecycle: build→push→pull→run; PID 1 exit stops container.
- **Volumes** persist; **ENTRYPOINT vs CMD**; one process/container.

> Next: Containerization.
