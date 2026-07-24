# syntax=docker/dockerfile:1.7
# PONY worker WITH FaceDetailer. Layer order = stable-first for registry caching: the big
# model downloads sit BELOW the deps, so iterating deps rebuilds only the small top layers.
FROM runpod/worker-comfyui:5.8.6-base

# --- models (stable, cached) ---
ARG CIVITAI_TOKEN
RUN --mount=type=secret,id=civitai \
    CIVITAI_API_TOKEN="$(cat /run/secrets/civitai)" \
    comfy model download --url "https://civitai.com/api/download/models/2884631" \
      --relative-path models/checkpoints --filename cyberrealistic_pony.safetensors
RUN comfy model download \
      --url "https://huggingface.co/RunDiffusion/Juggernaut-XL-v9/resolve/main/Juggernaut-XL_v9_RunDiffusionPhoto_v2.safetensors" \
      --relative-path models/checkpoints --filename juggernaut.safetensors
RUN comfy model download \
      --url "https://huggingface.co/Bingsu/adetailer/resolve/main/face_yolov8m.pt" \
      --relative-path models/ultralytics/bbox --filename face_yolov8m.pt

# --- Roxy LoRA (Pony family), from the loras-v1 GitHub release ---
RUN comfy model download --url "https://github.com/zg-claude/muse-comfy-worker/releases/download/loras-v1/roxy_pony.safetensors" \
      --relative-path models/loras --filename roxy_pony.safetensors

# --- FaceDetailer node + deps (iterate here; models above stay cached) ---
RUN --mount=type=secret,id=civitai \
    CIVITAI_API_TOKEN="$(cat /run/secrets/civitai)" \
    comfy model download --url "https://civitai.com/api/download/models/3074764" \
      --relative-path models/loras --filename uvg5.safetensors
RUN comfy-node-install comfyui-impact-pack comfyui-impact-subpack
# Install the nodes' OWN requirements (Impact Pack imports segment-anything at LOAD time even
# without the SAM path, so hand-picking deps and dropping it makes FaceDetailer silently fail
# to register). The worker's ComfyUI is a venv at /opt/venv; `pip` here resolves to it.
# numpy<2 LAST so it wins the ABI (a requirement may pull numpy 2.x); headless opencv for no GUI libs.
RUN for r in /comfyui/custom_nodes/*/requirements.txt; do pip install --no-cache-dir -r "$r" || true; done && \
    pip install --no-cache-dir opencv-python-headless "numpy<2"
