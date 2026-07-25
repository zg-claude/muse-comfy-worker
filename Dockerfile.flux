# syntax=docker/dockerfile:1.7
# SLIM Flux worker (Chroma1-HD now, Krea later). Carries NO weights - the UNET(fp8) diffusion
# model, the t5xxl text encoder and the ae VAE are read off the RunPod network volume mounted at
# /runpod-volume (see extra_model_paths.yaml). The flux graph uses no FaceDetailer and no LoRA,
# so no Impact Pack. ~2GB.
FROM runpod/worker-comfyui:5.8.6-base

# Point ComfyUI at the volume. extra_model_paths.yaml maps both unet<->diffusion_models and
# clip<->text_encoders so the flux loaders resolve regardless of which folder name a node asks for.
COPY extra_model_paths.yaml /comfyui/extra_model_paths.yaml
