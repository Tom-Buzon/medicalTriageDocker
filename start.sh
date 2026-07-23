#!/usr/bin/env bash

set -e

echo "Starting vLLM CPU server..."
echo "Model path: /model"

exec vllm serve /model \
    --served-model-name triage-model \
    --host 0.0.0.0 \
    --port 8000 \
    --dtype bfloat16 \
    --max-model-len 1024 \
    --max-num-seqs 1 \
    --generation-config vllm