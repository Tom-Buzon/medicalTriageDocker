#!/usr/bin/env bash

set -euo pipefail

MODEL_ID="${MODEL_ID:-qneaup/qwen3-1.7b-medical-triage-sft-dpo}"
MODEL_REVISION="${MODEL_REVISION:-}"
SERVED_MODEL_NAME="${SERVED_MODEL_NAME:-triage-model}"
MODEL_DTYPE="${MODEL_DTYPE:-${VLLM_DTYPE:-bfloat16}}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-1024}"
MAX_NUM_SEQS="${MAX_NUM_SEQS:-1}"

# Older local .env files used VLLM_DTYPE. Keep them compatible, but do not
# expose this unknown VLLM_* variable to the vLLM process.
unset VLLM_DTYPE

echo "============================================================"
echo "Starting vLLM CPU server"
echo "Model repository: ${MODEL_ID}"
echo "Model revision: ${MODEL_REVISION:-main}"
echo "Served model name: ${SERVED_MODEL_NAME}"
echo "Dtype: ${MODEL_DTYPE}"
echo "Maximum model length: ${MAX_MODEL_LEN}"
echo "============================================================"

VLLM_ARGS=(
    serve "${MODEL_ID}"
    --served-model-name "${SERVED_MODEL_NAME}"
    --host 0.0.0.0
    --port 8000
    --dtype "${MODEL_DTYPE}"
    --max-model-len "${MAX_MODEL_LEN}"
    --max-num-seqs "${MAX_NUM_SEQS}"
    --generation-config vllm
)

if [[ -n "${MODEL_REVISION}" ]]; then
    VLLM_ARGS+=(--revision "${MODEL_REVISION}")
fi

exec vllm "${VLLM_ARGS[@]}"
