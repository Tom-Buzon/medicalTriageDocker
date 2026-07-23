#!/usr/bin/env bash

set -euo pipefail

MODEL_ID="${MODEL_ID:-qneaup/qwen3-1.7b-medical-triage-sft-dpo}"
SERVED_MODEL_NAME="${SERVED_MODEL_NAME:-triage-model}"
VLLM_DTYPE="${VLLM_DTYPE:-bfloat16}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-1024}"
MAX_NUM_SEQS="${MAX_NUM_SEQS:-1}"

echo "============================================================"
echo "Starting vLLM CPU server"
echo "Model repository: ${MODEL_ID}"
echo "Served model name: ${SERVED_MODEL_NAME}"
echo "Dtype: ${VLLM_DTYPE}"
echo "Maximum model length: ${MAX_MODEL_LEN}"
echo "============================================================"

exec vllm serve "${MODEL_ID}" \
    --served-model-name "${SERVED_MODEL_NAME}" \
    --host 0.0.0.0 \
    --port 8000 \
    --dtype "${VLLM_DTYPE}" \
    --max-model-len "${MAX_MODEL_LEN}" \
    --max-num-seqs "${MAX_NUM_SEQS}" \
    --generation-config vllm