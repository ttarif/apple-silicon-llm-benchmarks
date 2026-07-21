#!/bin/sh
set -eu
MODEL=${1:-"$HOME/.local/share/mlx-models/Laguna-S-2.1-MLX-4bit"}
PY=${LAGUNA_PYTHON:-/tmp/laguna-bench/bin/python}
OUT=${2:-results/laguna}
mkdir -p "$OUT"
"$PY" -m mlx_lm.benchmark --model "$MODEL" --prompt-tokens 512 --generation-tokens 256 --batch-size 1 --num-trials 3 --prefill-step-size 2048 | tee "$OUT/p512-g256.txt"
"$PY" -m mlx_lm.benchmark --model "$MODEL" --prompt-tokens 8192 --generation-tokens 256 --batch-size 1 --num-trials 3 --prefill-step-size 2048 | tee "$OUT/p8192-g256.txt"
"$PY" -m mlx_lm.benchmark --model "$MODEL" --prompt-tokens 65536 --generation-tokens 64 --batch-size 1 --num-trials 1 --prefill-step-size 2048 | tee "$OUT/p65536-g64.txt"
