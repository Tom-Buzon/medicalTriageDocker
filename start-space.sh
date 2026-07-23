#!/usr/bin/env bash

set -euo pipefail

MODEL_ID="${MODEL_ID:-qneaup/qwen3-1.7b-medical-triage-sft-dpo}"
SERVED_MODEL_NAME="${SERVED_MODEL_NAME:-triage-model}"
MODEL_DTYPE="${MODEL_DTYPE:-bfloat16}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-1024}"
MAX_NUM_SEQS="${MAX_NUM_SEQS:-1}"

export INFERENCE_BASE_URL="http://127.0.0.1:8000/v1"

echo "============================================================"
echo "Starting Hugging Face Medical Triage Space"
echo "Model: ${MODEL_ID}"
echo "Served model name: ${SERVED_MODEL_NAME}"
echo "Dtype: ${MODEL_DTYPE}"
echo "============================================================"

vllm serve "${MODEL_ID}" \
    --served-model-name "${SERVED_MODEL_NAME}" \
    --host 127.0.0.1 \
    --port 8000 \
    --dtype "${MODEL_DTYPE}" \
    --max-model-len "${MAX_MODEL_LEN}" \
    --max-num-seqs "${MAX_NUM_SEQS}" \
    --generation-config vllm &

VLLM_PID=$!

streamlit run /home/user/app/frontend/app.py \
    --server.address=127.0.0.1 \
    --server.port=8501 \
    --server.headless=true \
    --browser.gatherUsageStats=false &

STREAMLIT_PID=$!

echo "Testing Nginx configuration..."

nginx \
    -t \
    -c /home/user/app/nginx.conf

echo "Starting Nginx..."

nginx \
    -c /home/user/app/nginx.conf \
    -g "daemon off;" &

NGINX_PID=$!

shutdown() {
    echo "Stopping services..."

    kill "${VLLM_PID}" 2>/dev/null || true
    kill "${STREAMLIT_PID}" 2>/dev/null || true
    kill "${NGINX_PID}" 2>/dev/null || true

    wait || true
}

trap shutdown SIGTERM SIGINT

wait -n "${VLLM_PID}" "${STREAMLIT_PID}" "${NGINX_PID}"

EXIT_CODE=$?

shutdown

exit "${EXIT_CODE}"