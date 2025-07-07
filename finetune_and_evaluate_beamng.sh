#!/bin/bash
set -e

# Set up KITTI dataset for eigen split
if [ ! -d "./kitti_data/2011_09_26/2011_09_26_drive_0002_sync" ]; then
    echo "[INFO] KITTI raw data for eigen split not found in ./kitti_data."
    echo "[INFO] Downloading required KITTI raw data archives..."
    mkdir -p kitti_data
    wget -N -i splits/kitti_archives_to_download.txt -P kitti_data/
    echo "[INFO] Extracting all zip files in ./kitti_data..."
    cd kitti_data
    for z in *.zip; do
        unzip -o "$z"
    done
    cd ..
fi

# Convert PNGs to JPGs for faster loading
echo "[INFO] Converting KITTI PNG images to JPG (this may take a while)..."
find kitti_data/ -name '*.png' | parallel 'convert -quality 92 -sampling-factor 2x2,1x1,1x1 {.}.png {.}.jpg && rm {}'

# Generate ground truth depths if not present
if [ ! -f "./splits/eigen/gt_depths.npz" ]; then
    echo "[INFO] Generating KITTI eigen ground truth depths..."
    python export_gt_depth.py --data_path ./kitti_data --split eigen
else
    echo "[INFO] KITTI eigen ground truth depths already exist."
fi

# Download the provided mono_640x192 pretrained model
mkdir -p models
cd models
wget -N https://storage.googleapis.com/niantic-lon-static/research/monodepth2/mono_640x192.zip
# Unzip into ./models/mono_640x192
rm -rf mono_640x192
mkdir mono_640x192
unzip -o mono_640x192.zip -d mono_640x192
cd ..

# Finetune it on BeamNG Driving Dataset
python train.py \
  --model_name beamng_finetuned_mono_640x192 \
  --data_path "./BeamNG-Driving-Dataset" \
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
