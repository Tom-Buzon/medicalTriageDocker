FROM vllm/vllm-openai-cpu:latest-x86_64

ENV VLLM_CPU_KVCACHE_SPACE=2
ENV VLLM_CPU_OMP_THREADS_BIND=auto

EXPOSE 8000

ENTRYPOINT ["vllm", "serve", "/model"]

CMD ["--served-model-name", "triage-model", "--host", "0.0.0.0", "--port", "8000", "--dtype", "bfloat16", "--max-model-len", "1024", "--max-num-seqs", "1", "--generation-config", "vllm"]