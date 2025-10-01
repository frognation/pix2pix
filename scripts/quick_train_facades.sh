#!/usr/bin/env bash
set -euo pipefail

echo "[pix2pix quick] Ensuring facades dataset is present"
if [ ! -d "datasets/facades" ]; then
  bash datasets/download_dataset.sh facades
fi

EXP_NAME=${1:-quick_facades}

# Torch7 scripts parse only ENV variables, not -gpu flags.
# CPU mode: gpu=0 cudnn=0

echo "[pix2pix quick] Training minimal run (1 epoch) on CPU for sanity check"
gpu=0 cudnn=0 \
DATA_ROOT=./datasets/facades \
name="${EXP_NAME}" \
which_direction=BtoA \
th train.lua niter=1 niter_decay=0 save_epoch_freq=1 display_id=0

echo "[pix2pix quick] Testing trained model (first 5 samples)"
gpu=0 cudnn=0 \
DATA_ROOT=./datasets/facades \
name="${EXP_NAME}" \
which_direction=BtoA \
phase=val \
th test.lua how_many=5 display_id=0

echo "[pix2pix quick] Results saved under results/${EXP_NAME}/val_latest/"
