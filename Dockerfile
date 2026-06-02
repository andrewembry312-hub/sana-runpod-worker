FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04
LABEL maintainer="E-Labs AI Studio" description="Sana 0.6B (models baked)"
ENV DEBIAN_FRONTEND=noninteractive PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/*
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir torch==2.6.0 torchvision==0.21.0 \
    --index-url https://download.pytorch.org/whl/cu124
WORKDIR /workspace
COPY requirements-runpod.txt requirements-runpod.txt
RUN pip install --no-cache-dir -r requirements-runpod.txt
# Bake Sana 600M weights into the image at build time.
# Model is Apache 2.0 -- no HF token needed.
RUN python3 -c "import os,huggingface_hub as h; M='Efficient-Large-Model/Sana_600M_1024px_diffusers'; T='/models/sana'; os.makedirs(T,exist_ok=True); h.snapshot_download(repo_id=M,local_dir=T); print('Done:',len(os.listdir(T)),'files',flush=True)"
COPY rp_handler.py /workspace/rp_handler.py
RUN mkdir -p /tmp/sana_outputs
WORKDIR /workspace
CMD ["python", "-u", "rp_handler.py"]