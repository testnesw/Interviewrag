# DEEP MECHANICS · Speech — STT & TTS

> 🧠 **Hook:** *Ears + mouth* — STT turns sound into text, TTS turns text back into sound; stream both for low latency.
>
> Level 2 — how speech-to-text and text-to-speech work, streaming vs batch,
> and voice-agent pipelines.

---

## 0. The precise mental model
**STT (ASR)** converts an audio waveform → text: audio is turned into features (mel-spectrogram), an encoder produces acoustic representations, and a decoder emits text tokens. **TTS** does the reverse: text → acoustic features (mel-spectrogram) → a **vocoder** synthesizes the waveform. A **voice agent** chains them: STT → LLM → TTS, optimized for low latency.

---

## 1. STT (speech-to-text / ASR)
- **Pipeline**: waveform → **mel-spectrogram** → **encoder** (transformer) → text.
- **Whisper** = encoder-decoder transformer trained on huge weakly-labeled audio; robust, multilingual, does transcription + translation.
- **Streaming vs batch**: batch = whole file, best accuracy; **streaming** = partial results as audio arrives (low latency, needs chunking + endpointing).
- **Key concepts**: **diarization** (who spoke when), **VAD** (voice activity detection), **word error rate (WER)** = the accuracy metric, timestamps, custom vocabulary/biasing for domain terms.

## 2. TTS (text-to-speech)
- **Pipeline**: text → (normalize/phonemes) → **acoustic model** (text→mel-spectrogram, e.g., Tacotron/FastSpeech/VITS) → **vocoder** (mel→waveform, e.g., HiFi-GAN) → audio.
- Modern **neural TTS** = natural prosody; **zero-shot voice cloning** from a few seconds of reference audio.
- **Streaming TTS**: emit audio chunks as text arrives → low time-to-first-audio (critical for voice agents).
- **SSML** controls pronunciation, pauses, emphasis, rate, pitch.

## 3. Voice agent pipeline (the system-design answer)
```
Mic → VAD → STT (streaming) → LLM (+ tools/RAG) → TTS (streaming) → Speaker
```
- **Latency is everything** — target sub-second turn response. Techniques:
  - **Stream all stages**; start TTS on the first sentence of the LLM output.
  - **Endpointing/VAD** to detect when the user stopped talking.
  - **Barge-in**: user interrupts → cancel TTS playback + LLM.
- **Speech-native (realtime) models** (e.g., GPT-4o realtime / audio models) skip the text round-trip — audio in → audio out — for the lowest latency + tone/emotion preservation.

## 4. Azure mapping
- **Azure AI Speech**: STT (real-time + batch), TTS (neural voices, custom voice), translation, diarization, pronunciation assessment; Whisper available via Azure OpenAI.

## 5. Cautions
- STT errors **propagate** to the LLM (garbage in → garbage out) → confirm critical info.
- Accents/noise/domain terms hurt WER → custom models/biasing.
- **Voice cloning** = consent/deepfake risk → watermarking + policy.
- Latency budget is tight — every hop counts; cache/warm models.

## 6. The hard follow-ups (with answers)
1. **"How does STT work?"** → waveform → **mel-spectrogram** → encoder-decoder transformer → text (Whisper). (§1)
2. **"Streaming vs batch STT?"** → batch = best accuracy on whole file; streaming = partial low-latency results with chunking + endpointing. (§1)
3. **"STT accuracy metric?"** → **WER** (word error rate). (§1)
4. **"How does TTS work?"** → text → acoustic model (mel) → **vocoder** → waveform. (§2)
5. **"Lowest-latency voice agent?"** → stream every stage, start TTS on first sentence, **barge-in**, or a **speech-native realtime model** (audio→audio). (§3)
6. **"Detect when user stops talking?"** → **VAD / endpointing**. (§1/§3)
7. **"Who spoke when?"** → **diarization**. (§1)
8. **"Voice cloning risk?"** → consent/deepfake → watermark + policy. (§5)

## 7. One-screen recall
- **STT**: waveform → **mel-spectrogram** → encoder-decoder (**Whisper**) → text; **streaming vs batch**; metric = **WER**; **diarization**, **VAD**.
- **TTS**: text → acoustic model (mel) → **vocoder** → audio; neural TTS, **voice cloning**, **SSML**, streaming for low time-to-first-audio.
- **Voice agent**: Mic→VAD→STT→LLM→TTS→Speaker; **stream everything**, **barge-in**, or **speech-native realtime** (audio→audio) for lowest latency.
- **Azure AI Speech** = STT/TTS/translation/custom voice.
- Cautions: STT errors propagate; accents/noise raise WER; cloning = consent risk.

> Next: Distillation & Model Compression.
