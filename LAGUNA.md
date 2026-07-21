# Laguna S 2.1 on Apple Silicon

## Variant selection

The first model tested is `pipenetwork/Laguna-S-2.1-MLX-4bit`.

Reasons:

- Conventional native MLX affine 4-bit, group size 64.
- 61.6 GiB indexed weights versus 67.0 GiB for Poolside NVFP4 MLX.
- Bundles a numerically validated `laguna.py` loader.
- Preserves the 1,048,576-token context configuration; Poolside's current NVFP4 export advertises 262,144.
- Leaves more unified-memory headroom for KV cache, allocator workspace, and macOS.

The Poolside NVFP4 model is not automatically faster on Apple Silicon merely because it uses NVFP4. It is larger, requires the same custom Laguna architecture loader, and lacks published M1 Ultra comparisons.

## Architecture

- 118B total parameters, approximately 8B active per token
- 48 layers
- 256 routed experts, top 10, plus one shared expert
- 12 global-attention layers
- 36 sliding-window layers with window 512
- 1M advertised base context

## MTPLX compatibility

Laguna cannot currently be converted into a valid MTPLX speculative model.

- MTPLX has no Laguna backend or loader.
- The checkpoints contain no native MTP/NextN heads or `mtp.safetensors`.
- Forge refuses AR-only models with `no_mtp_heads` rather than fabricating a speculative contract.
- MTPLX's generic patch is Qwen-specific and cannot be reused safely for Laguna.
- Poolside publishes a separate DFlash drafter, not an embedded MTP head.

A real MTPLX port requires Laguna target support, mixed full/sliding cache handling, a Laguna-specific proposer contract, trained proposer weights, exact verification/rollback tests, and a verified runtime contract. Weight conversion alone is insufficient.

The technically faithful acceleration path is to port Poolside's Laguna DFlash target/drafter to MLX or use an existing supported server. It must not be relabeled as native MTP.
