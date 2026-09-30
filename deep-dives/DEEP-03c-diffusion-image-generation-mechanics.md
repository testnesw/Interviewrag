# DEEP MECHANICS · Diffusion & Image Generation

> Level 2 — how diffusion models generate images, latent diffusion, conditioning
> (text/ControlNet), and sampling trade-offs.

---

## 0. The precise mental model
A diffusion model learns to **reverse a gradual noising process**. Training: take an image, add Gaussian noise in small steps until it's pure noise; train a network to **predict the noise** at each step. Generation: start from **random noise** and repeatedly **denoise** (subtract predicted noise) over many steps until a clean image emerges. Text conditioning steers each denoising step toward the prompt.

---

## 1. Forward vs reverse process
- **Forward (fixed, no learning)**: $x_0 \to x_T$ by adding noise over $T$ steps; $x_T$ ≈ pure Gaussian noise.
- **Reverse (learned)**: a U-Net/Transformer predicts the noise $\epsilon_\theta(x_t, t, c)$ at timestep $t$ given condition $c$ → step from $x_t$ to $x_{t-1}$.
- Loss = simple MSE between **predicted noise and actual added noise**.

## 2. Latent diffusion (why Stable Diffusion is fast)
- Running diffusion in **pixel space** is expensive. **Latent Diffusion (LDM)**: a **VAE encoder** compresses the image to a small **latent**, diffusion happens in that latent space, then the **VAE decoder** reconstructs pixels.
- → far cheaper compute/memory; this is what makes SD practical.

## 3. Conditioning (how the prompt steers it)
- **Text**: prompt → text encoder (CLIP/T5) → embeddings injected via **cross-attention** into the U-Net at each step.
- **Classifier-free guidance (CFG)**: run denoise both **conditioned** and **unconditioned**, extrapolate: $\epsilon = \epsilon_{uncond} + s(\epsilon_{cond}-\epsilon_{uncond})$. Higher **guidance scale $s$** = closer to prompt but less diverse / can over-saturate.
- **ControlNet**: extra conditioning (edges, depth, pose, scribble) → structural control.
- **Image-to-image / inpainting**: start from a partially-noised real image / mask regions.
- **IP-Adapter, LoRA**: style/subject conditioning; LoRA fine-tunes a style cheaply.

## 4. Samplers & steps (quality vs speed)
- **Sampler/scheduler** (DDPM, DDIM, DPM++, Euler) decides how to step through denoising. DDIM = deterministic, fewer steps.
- **More steps** = higher fidelity but slower; typical 20–50. **Distilled** models (LCM, SDXL-Turbo) generate in **1–4 steps**.
- Trade-off dial: steps × guidance scale × sampler.

## 5. Model families (name-drop)
- **Stable Diffusion / SDXL** (latent, open), **DALL·E 3**, **Midjourney**, **Imagen/FLUX**.
- **Diffusion Transformers (DiT)** replace the U-Net with a transformer (scales better; used by Sora-style video, SD3).

## 6. Cautions
- **Non-deterministic** (seed controls reproducibility).
- Struggles with **text rendering, hands/fine structure, exact counts**.
- Safety: NSFW/deepfake risk → content filters + **C2PA/provenance watermarking**; copyright/training-data concerns.

## 7. The hard follow-ups (with answers)
1. **"How does diffusion generate an image?"** → learn to **reverse a noising process**: start from noise, repeatedly predict-and-remove noise. (§0/§1)
2. **"What does the network actually predict?"** → the **noise** added at each step (MSE loss). (§1)
3. **"Why latent diffusion?"** → do diffusion in a compressed **VAE latent** space → much cheaper than pixel space. (§2)
4. **"How does the text prompt steer it?"** → text embeddings via **cross-attention** + **classifier-free guidance**. (§3)
5. **"Guidance scale effect?"** → higher = closer to prompt, less diverse / can over-saturate. (§3)
6. **"Structural control (pose/edges)?"** → **ControlNet**. (§3)
7. **"Fewer steps / real-time?"** → distilled models (**LCM, Turbo**) → 1–4 steps; DDIM sampler. (§4)
8. **"DiT vs U-Net?"** → transformer backbone, scales better (SD3, video). (§5)

## 8. One-screen recall
- Diffusion = **reverse a noising process**; network **predicts the noise**, MSE loss; generate by denoising from random noise over many steps.
- **Latent diffusion (SD)**: VAE compress → diffuse in latent → VAE decode → cheap.
- **Conditioning**: text via **cross-attention** + **CFG (guidance scale)**; **ControlNet** for structure; **LoRA/IP-Adapter** for style.
- **Samplers** (DDIM/DPM++) + **steps** trade quality vs speed; **LCM/Turbo** = 1–4 steps.
- **DiT** = transformer backbone (SD3, video).
- Weak at text/hands/counts; provenance + safety filters needed.

> Next: Speech (STT / TTS).
