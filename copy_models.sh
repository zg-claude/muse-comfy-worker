#!/bin/bash
# Boot-time model staging: copy the needed checkpoints/loras/detectors from the RunPod network
# volume (/runpod-volume) to LOCAL container disk (/comfyui/models), so ComfyUI/safetensors loads
# them off local disk. Loading directly off the network volume (mmap over the FUSE mount) crashes
# the worker with a bare exit-1 - proven Jul 25. cp does a normal read (not mmap), so it's safe.
set -e
VOL=/runpod-volume/ComfyUI/models
DST=/comfyui/models
for rel in checkpoints/cyberrealistic_pony.safetensors; do
  if [ -f "$VOL/$rel" ] && [ ! -f "$DST/$rel" ]; then
    mkdir -p "$DST/$(dirname "$rel")"
    echo "[stage] copying $rel from volume -> local..."
    cp "$VOL/$rel" "$DST/$rel"
    echo "[stage] done $rel ($(du -h "$DST/$rel" | cut -f1))"
  fi
done
echo "[stage] staging complete"
