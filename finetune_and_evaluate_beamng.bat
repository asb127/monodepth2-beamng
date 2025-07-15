@echo off
REM Windows batch script for finetuning and evaluating mono_640x192 on BeamNG and KITTI
REM Make sure to run this from an "Anaconda Prompt" or after running "conda init" and opening a new terminal

set KMP_DUPLICATE_LIB_OK=TRUE

echo [INFO] Step 1: Downloading the official mono_640x192 pretrained model
if not exist models mkdir models
cd models
if not exist mono_640x192 (
    if not exist mono_640x192.zip (
        echo [INFO] Downloading mono_640x192.zip...
        curl -L -o mono_640x192.zip https://storage.googleapis.com/niantic-lon-static/research/monodepth2/mono_640x192.zip
    ) else (
        echo [INFO] mono_640x192.zip already exists, skipping download.
    )
    echo [INFO] Unzipping mono_640x192.zip into .\models\mono_640x192
    mkdir mono_640x192
    powershell -Command "Expand-Archive -Force 'mono_640x192.zip' 'mono_640x192'"
) else (
    echo [INFO] mono_640x192 folder already exists, skipping download and unzip.
)
cd ..

echo [INFO] Step 2: KITTI eigen split setup
if not exist .\kitti_data\2011_09_26\2011_09_26_drive_0002_sync (
    echo [INFO] KITTI raw data for eigen split not found in .\kitti_data.
    echo [INFO] Downloading required KITTI raw data archives...
    if not exist kitti_data mkdir kitti_data
    for /f "usebackq delims=" %%u in (splits\kitti_archives_to_download.txt) do (
        echo [INFO] Downloading %%u
        powershell -Command "& {try {Invoke-WebRequest -Uri '%%u' -OutFile 'kitti_data\\' + (Split-Path '%%u' -Leaf)} catch {Write-Host 'Failed to download: %%u'}}"
    )
    echo [INFO] Extracting all zip files in .\kitti_data...
    pushd kitti_data
    for %%z in (*.zip) do (
        echo [INFO] Unzipping %%z
        powershell -Command "Expand-Archive -Force '%%z' ."
    )
    popd
)

REM Convert PNGs to JPGs for faster loading
echo [INFO] Step 2: Converting KITTI PNG images to JPG (this may take a while)...
for /r .\kitti_data %%f in (*.png) do (
    if exist "%%~dpnf.jpg" del "%%~dpnf.jpg"
    magick "%%f" -quality 92 -sampling-factor 2x2,1x1,1x1 "%%~dpnf.jpg"
    del "%%f"
)

if not exist .\splits\eigen\gt_depths.npz (
    echo [INFO] Generating KITTI eigen ground truth depths...
    python export_gt_depth.py --data_path .\kitti_data --split eigen
) else (
    echo [INFO] KITTI eigen ground truth depths already exist.
)

call conda activate monodepth2
echo [INFO] Step 4: Finetuning on BeamNG Driving Dataset
python train.py ^
  --model_name beamng_finetuned_mono_640x192 ^
  --data_path ".\BeamNG-Driving-Dataset" ^
  --split beamng ^
  --dataset beamng ^
  --load_weights_folder .\models\mono_640x192 ^
  --png ^
  --log_frequency 100 ^
  --num_epochs 20 ^
  --batch_size 12 ^
  --height 192 ^
  --width 640 ^
  --save_frequency 1 ^
  --scheduler_step_size 10 ^
  --scheduler_gamma 0.5 ^
  --learning_rate 1e-4 ^
  --num_workers 4 ^
  --disable_automated_logging

echo [INFO] Step 5: Evaluating the original mono_640x192 model on KITTI
python evaluate_depth.py ^
  --data_path .\kitti_data ^
  --split beamng ^
  --eval_split eigen ^
  --load_weights_folder .\models\mono_640x192 ^
  --eval_mono ^
  --save_pred_disps ^
  --output_dir .\eval_results\original_mono_640x192

echo [INFO] Step 6: Evaluating the finetuned model on KITTI (using last checkpoint)
python evaluate_depth.py ^
  --data_path .\kitti_data ^
  --split beamng ^
  --eval_split eigen ^
  --load_weights_folder .\tmp\beamng_finetuned_mono_640x192\models\weights_19 ^
  --eval_mono ^
  --save_pred_disps ^
  --output_dir .\eval_results\finetuned_mono_640x192

echo [INFO] All steps completed. Results and depth maps will be saved in .\eval_results\original_mono_640x192 and .\eval_results\finetuned_mono_640x192
