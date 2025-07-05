import os

# Set your dataset root
DATASET_ROOT = './BeamNG-Driving-Dataset'
# Fill these lists with your chosen session folder names
TRAIN_SESSIONS = [
    '2025-03-02_12-50-31',
    '2025-03-02_14-01-23',
    '2025-03-02_14-57-13',
    '2025-03-02_15-26-10',
    '2025-03-02_15-46-04',
    '2025-03-02_16-21-21',
    '2025-03-02_22-53-59',
    '2025-03-02_23-24-39',
    '2025-03-02_23-56-57',
    '2025-03-03_00-54-53',
    '2025-03-05_08-23-47',
    '2025-03-05_09-27-23',
    '2025-03-05_10-35-24',
    '2025-03-05_10-58-32',
    '2025-03-05_11-12-25',
    '2025-03-05_11-31-08',
    '2025-03-05_11-47-04',
    '2025-03-05_11-53-38',
    '2025-03-05_12-10-18',
    '2025-03-05_12-28-57',
    '2025-03-05_12-53-35',
    '2025-03-05_13-17-59',
    '2025-03-05_13-25-15',
    '2025-03-05_16-21-30',
]
VAL_SESSIONS = [
    '2025-03-02_00-08-45',
    '2025-03-02_12-20-09',
    '2025-03-02_13-21-54',
    '2025-03-03_00-02-33',
    '2025-03-05_10-42-52',
    '2025-03-05_13-07-34',
]

# BeamNG Driving Dataset is monocular so we always use the left camera ('l')
CAMERA = 'l'

# Frame filename pattern: frame_00001_sensor_camera_color.png
FRAME_PREFIX = 'frame_'
FRAME_SUFFIX = '_sensor_camera_color.png'

# Output split file paths
TRAIN_OUT = os.path.join("splits", "beamng", "train_files.txt")
VAL_OUT = os.path.join("splits", "beamng", "val_files.txt")


def write_split_file(sessions, out_path):
    lines = []
    for session in sessions:
        color_dir = os.path.join(DATASET_ROOT, session, 'color')
        if not os.path.isdir(color_dir):
            print(f"Warning: {color_dir} does not exist.")
            continue
        frame_files = sorted(f for f in os.listdir(color_dir) if f.startswith(FRAME_PREFIX) and f.endswith(FRAME_SUFFIX))
        for fname in frame_files:
            # Extract frame index as integer (removing prefix/suffix and leading zeros)
            frame_num_str = fname[len(FRAME_PREFIX):-len(FRAME_SUFFIX)]
            frame_index = int(frame_num_str.lstrip('0') or '0')
            # Format: <session>/color <frame_index> l
            lines.append(f"{session}/color {frame_index} {CAMERA}")
    # Do NOT shuffle lines! Order must match ground truth for evaluation.
    with open(out_path, 'w') as f:
        for line in lines:
            f.write(line + '\n')

if __name__ == '__main__':
    write_split_file(TRAIN_SESSIONS, TRAIN_OUT)
    write_split_file(VAL_SESSIONS, VAL_OUT)
    print('Done! Fill TRAIN_SESSIONS and VAL_SESSIONS with your session names.')
