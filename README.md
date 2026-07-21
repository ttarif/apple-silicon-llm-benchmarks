# Apple Silicon LLM Benchmarks

Reproducible local-model measurements from an Apple Mac Studio with an M1 Ultra and 128 GB unified memory.

## Hardware and methodology

- Apple M1 Ultra: 20 CPU cores, 128 GB unified memory
- macOS 27.0
- Single-request latency unless stated otherwise
- Cold process and cold prompt cache for context sweeps
- Long-context fixture: 62,922 / 125,832 / 247,692 actual tokens
- MTPLX context lanes: Sustained, fixed depth, serial scheduler, latency batching, maximum fans
- Short coding prompt: `Implement robust binary search in Python with input validation.`
- Do not compare `effective_tps` from HTTP wall time directly with runtime-reported decode TPS without noting the metric difference.

## Filled-context results

| Runtime | Prompt tokens | PP tok/s | TG tok/s | Peak GB |
|---|---:|---:|---:|---:|
| MTPLX Qwen3.6 35B-A3B D2, KV off, chunk 2048 | 62,922 | **882.0** | 44.5 | 27.9 |
| Qwen3.5 35B AR MLX-VLM | 62,922 | 750.7 | **47.2** | 27.7 |
| MTPLX Qwen3.5 4B D2 | 62,922 | 719.4 | 30.9 | 10.9 |
| Qwen3.5 35B DFlash block 8 | 62,922 | 762.1 | 25.4 | 28.0 |
| Bonsai Q2 27B MLX | 62,922 | 220.3 | 25.2 | 19.1 |
| MTPLX Qwen3.6 27B D2 Sustained | 62,922 | 208.3 | 20.8 | 29.9 |
| MTPLX Qwen3.6 27B updated Turbo D2 | 62,922 | 208.1 | 19.9 | 30.6 |
| MTPLX Qwen3.6 35B-A3B D2, Q8, chunk 4096 | 125,832 | 357.7 | 20.3 | 42.8 |
| Bonsai Q2 27B MLX | 125,832 | 146.9 | 9.8 | 29.1 |
| MTPLX Qwen3.6 35B-A3B D2, Q8, chunk 4096 | 247,692 | 173.6 | 7.6 | 62.1 |
| Bonsai Q2 27B MLX | 247,692 | 90.0 | 4.9 | 48.3 |

## Short coding results

| Runtime | Result |
|---|---:|
| Qwen3.5 35B + DFlash block 8 | **103.9 runtime TG tok/s** |
| MTPLX Qwen3.5 4B D2 | ~103.8 effective output tok/s |
| MTPLX Qwen3.6 35B-A3B D2 | ~78.0 effective output tok/s |
| Qwen3.5 35B AR MLX-VLM | 63.6 runtime TG tok/s |
| Bonsai Q1 27B MLX | 43.9 runtime TG tok/s |
| Bonsai Q2 27B MLX | 43.7 runtime TG tok/s |
| MTPLX Qwen3.6 27B updated D2 | ~33.4 effective output tok/s |

DFlash was byte-identical to greedy AR in a deterministic parity test. It accelerated short coding by 1.64x but regressed filled-64K TG because acceptance fell to 15.6%.

## Laguna S 2.1 affine 4-bit

Tested `pipenetwork/Laguna-S-2.1-MLX-4bit` with the pinned custom Laguna loader, MLX 0.32.0, and mlx-lm 0.31.3.

| Prompt | Generation | PP tok/s | TG tok/s | Peak GB |
|---:|---:|---:|---:|---:|
| 512 | 256 | 289.5 | 19.3 | 66.8 |
| 8,192 | 256 | 352.2 | 18.3 | 67.9 |
| 65,536 | 64 | 276.7 | 22.2 | 70.7 |

The 64K TG result used one short 64-token trial and should not be interpreted as a context-driven speedup. Laguna is substantially slower than the measured MTPLX 35B and Qwen3.5+DFlash lanes, but it targets agentic coding and provides a much larger context architecture.

The PipeNetwork affine variant was selected over Poolside NVFP4 because it is 5.4 GiB smaller, bundles the required loader, advertises a 1M context, and leaves more unified-memory headroom. See [LAGUNA.md](LAGUNA.md).

## Main findings

1. Qwen3.6 35B-A3B is the best measured primary local coding model: its sparse MoE activates about 3B parameters per token and outperforms dense 27B at long context.
2. Qwen3.5 35B + DFlash is the fastest short coding lane, but must be disabled for long contexts when acceptance collapses.
3. The updated 27B Turbo metadata is valid, but Turbo did not improve M1 Ultra results: Sustained and Turbo tied on short requests, Sustained was 4.4% faster TG at 64K.
4. The MTPLX 4B is an excellent low-memory worker at short context, but long-context TG falls to 30.9 tok/s.
5. Loading multiple copies of one large model is usually inferior to one resident server with bounded concurrency: copies duplicate weights and KV pools. Use one model instance with queued/continuous batching, or route roles to different models only when they are already needed for quality tiers.

## Data

- `data/benchmark-summary.json`: normalized manually recorded measurements.
- `data/tune-*`: raw MTPLX tuner output.
- `data/laguna-s-2.1-mlx-4bit.json`: Laguna benchmark measurements.

