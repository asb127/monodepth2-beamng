#!/bin/bash
set -e

# Download the provided mono_640x192 pretrained model
mkdir -p models
cd models
wget -N https://storage.googleapis.com/niantic-lon-static/research/monodepth2/mono_640x192.zip
unzip -o mono_640x192.zip
cd ..

# Finetune it on BeamNG Driving Dataset
python train.py \
  --model_name beamng_finetuned_mono_640x192 \
  --data_path ./BeamNG-Driving-Dataset \
  --split beamng \
  --dataset beamng \
  --load_weights_folder ./models/mono_640x192 \
  --num_epochs 20 \
  --save_frequency 5

# Evaluate the original mono_640x192 model on KITTI
python evaluate_depth.py \
  --data_path ./kitti_data \
  --split eigen \
  --load_weights_folder ./models/mono_640x192 \
  --eval_mono \
  --save_pred_disps \
  --save_pred_depth \
  --output_dir ./eval_results/original_mono_640x192

# Evaluate the finetuned model on KITTI (using last checkpoint)
python evaluate_depth.py \
  --data_path ./kitti_data \
  --split eigen \
  --load_weights_folder ./tmp/beamng_finetuned_mono_640x192/models/weights_19 \
  --eval_mono \
  --save_pred_disps \
  --save_pred_depth \
  --output_dir ./eval_results/finetuned_mono_640x192
