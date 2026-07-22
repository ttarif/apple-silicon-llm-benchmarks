# Laguna S 2.1 exhaustive M1 Ultra comparison

Hardware: Apple M1 Ultra, 128 GB unified memory. Single-stream, batch 1. Results are machine-local; GGUF built from Poolside commit `04b2b72`. MLX NVFP4 used MLX-VLM PR #1650. Laguna MLX DFlash support was implemented in `ttarif/dflash-mlx` branch `laguna-dflash-mlx`.

## Fastest setups

| Context | Fastest setup | PP tok/s | TG tok/s | Peak GB | Notes |
|---:|---|---:|---:|---:|---|
| short coding | **oQ2e MLX + Q4 DFlash, block 8** | — | **61.3** | 37.0 | 79.3% acceptance |
| 8K | **oQ2e MLX + Q4 DFlash, block 8** | 343.0 | **41.2** | 38.8 | 71.1% acceptance |
| ~64K | **GGUF Q4_K_M AR** | **384.0** | **27.9** | not reported | DFlash disabled |
| 64K memory-efficient | oQ2e MLX AR | 285.4 | 26.3 | **38.4** | 6% slower TG, much smaller |

## Matched comparison

| Format | Mode | 512 TG | 8K TG | 64K TG | 64K PP | 64K peak |
|---|---|---:|---:|---:|---:|---:|
| MLX affine 4-bit | AR | 29.3 | 29.5 | 21.6 | 270.5 | 70.0 GB |
| MLX affine 4-bit | Q4 DFlash | 38.2 | 29.6 | 17.5 | 75.2 | 105.0 GB |
| MLX NVFP4 | AR | 28.5 | 21.8 | 22.1 | 311.1 | 71.6 GB |
| **MLX oQ2e** | AR | 38.0 | 36.0 | 26.3 | 285.4 | 38.4 GB |
| **MLX oQ2e** | **Q4 DFlash** | **61.3** | **41.2** | 23.2 | 269.4 | 42.6 GB |
| MLX oQ3e | AR | 37.9 | 36.3 | 26.1 | 282.9 | 50.5 GB |
| MLX oQ3e | Q4 DFlash | 52.4 | 38.7 | not run | — | — |
| GGUF Q4_K_M | AR | 40.7 | 40.7 | **27.9** | **384.0** | — |
| GGUF Q4_K_M | BF16 DFlash | 43.4 | — | **2.8** | 378.1 | — |

## Interpretation

- oQ2e is the best Apple deployment target: smallest resident memory and fastest measured speculative short/8K lane.
- DFlash must self-disable above 16K. At 64K, draft acceptance/cost loses to AR for every tested target; GGUF DFlash collapsed to 0% acceptance on the repetitive long-context fixture.
- GGUF AR is 6% faster than oQ2e AR at 64K, but uses a 75 GB target versus 36 GB oQ2e. oQ2e leaves room for agents, caches and other applications.
- NVFP4 improves PP over uniform affine 4-bit but does not beat oQ2e TG, and uses nearly twice the memory.
- Q8/Q4 KV quantization in current MLX-VLM is not a speed win: rotating caches originally crashed; after skipping rotating layers, 64K PP dropped to ~246 tok/s and peak rose to ~86 GB because conversion held both forms transiently.

## Deployed policy

The persistent service uses oQ2e and a Q4 DFlash drafter with block/verify cap 8. `--dflash-max-ctx 16384` automatically falls back to AR above 16K. Prefix snapshots are disabled for Laguna because current cache serialization does not support its cache classes safely.

## Correctness

- Affine Laguna AR and DFlash generated identical deterministic output in the parity test.
- 59 core target/rollback/registry tests pass after Laguna integration.
- Persistent OpenAI API smoke returns clean `LAGUNA_OK` and stops on Laguna's `</assistant>` token.

Raw measurements: `data/laguna-exhaustive-results.json`.
