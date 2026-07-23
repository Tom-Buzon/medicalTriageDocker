FROM vllm/vllm-openai-cpu:latest-x86_64

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends nginx \
    && rm -rf /var/lib/apt/lists/*

RUN if ! id -u user >/dev/null 2>&1; then \
        useradd -m -u 1000 user; \
    fi

ENV HOME=/home/user
ENV PATH=/home/user/.local/bin:${PATH}
ENV HF_HOME=/home/user/.cache/huggingface

WORKDIR /home/user/app

COPY frontend/requirements.txt ./frontend/requirements.txt

RUN pip install --no-cache-dir -r ./frontend/requirements.txt

COPY --chown=user frontend/app.py ./frontend/app.py
COPY --chown=user nginx.conf ./nginx.conf
COPY --chown=user start-space.sh ./start-space.sh

# Prépare les dossiers et logs que Nginx tente d'utiliser,
# même avant d'avoir complètement lu nginx.conf.
RUN chmod +x ./start-space.sh \
    && mkdir -p \
        /home/user/.cache/huggingface \
        /var/log/nginx \
        /var/lib/nginx \
        /tmp/nginx_client_body \
        /tmp/nginx_proxy \
        /tmp/nginx_fastcgi \
        /tmp/nginx_uwsgi \
        /tmp/nginx_scgi \
    && rm -f \
        /var/log/nginx/error.log \
        /var/log/nginx/access.log \
    && ln -s /dev/stderr /var/log/nginx/error.log \
    && ln -s /dev/stdout /var/log/nginx/access.log \
    && chown -R user:user \
        /home/user \
        /var/log/nginx \
        /var/lib/nginx \
        /tmp/nginx_client_body \
        /tmp/nginx_proxy \
        /tmp/nginx_fastcgi \
        /tmp/nginx_uwsgi \
        /tmp/nginx_scgi

USER user

ENV MODEL_ID=qneaup/qwen3-1.7b-medical-triage-sft-dpo
ENV SERVED_MODEL_NAME=triage-model
ENV MODEL_DTYPE=bfloat16
ENV MAX_MODEL_LEN=1024
ENV MAX_NUM_SEQS=1

ENV VLLM_CPU_KVCACHE_SPACE=2
ENV VLLM_CPU_OMP_THREADS_BIND=auto

ENV INFERENCE_BASE_URL=http://127.0.0.1:8000/v1

EXPOSE 7860

ENTRYPOINT []

CMD ["/home/user/app/start-space.sh"]