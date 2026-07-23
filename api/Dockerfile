FROM vllm/vllm-openai-cpu:latest-x86_64

ENV VLLM_CPU_KVCACHE_SPACE=2
ENV VLLM_CPU_OMP_THREADS_BIND=auto

COPY start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 8000

ENTRYPOINT ["/start.sh"]