import os
import numpy as np
from PIL import Image
from .mono_dataset import MonoDataset

class BeamNGDataset(MonoDataset):
    """
    Monodepth2-compatible Dataset for BeamNG Driving Dataset.
    Expects directory structure:
    ./BeamNG-Driving-Dataset/<session>/color/frame_xxxxx_sensor_camera_color.png
    ./BeamNG-Driving-Dataset/<session>/depth/frame_xxxxx_sensor_camera_depth.png
    """
    def __init__(self, *args, **kwargs):
        super(BeamNGDataset, self).__init__(*args, **kwargs)
        # Camera intrinsics for BeamNG dataset (calculated by hand)
        #
        # The images have been resized to 640x192 and the camera fov_y is 70 degrees.
        # The principal point is assumed to be placed in the center.
        #
        # To get the focal lengths:
        #   fy = (height / 2) / tan(fov_y / 2)
        #   fx = fy * (width / height)
        #
        # For this dataset:
        #   height = 192, width = 640
        #   fov_y = 70 deg (in radians: 1.22173)
        #   fy = 96 / tan(35 deg) ≈ 137.16
        #   fx = 137.16 * (640/192) ≈ 457.88
        #   cx = 320, cy = 96
        #
        # Monodepth2 needs normalized intrinsics:
        #   fx = 457.88 / 640 = 0.71544
        #   fy = 137.16 / 192 = 0.71437
        #   cx = 320 / 640 = 0.5
        #   cy = 96 / 192 = 0.5
        #
        # Resulting normalized intrinsics matrix:
        self.K = np.array([
            [0.71544, 0,       0.5, 0],
            [0,       0.71437, 0.5, 0],
            [0,       0,       1,   0],
            [0,       0,       0,   1]
        ], dtype=np.float32)
        self.full_res_shape = (640, 192)

    def get_image_path(self, folder, frame_index, side=None):
        """
        Returns the path to the color image for a given session and frame index.
        The 'side' argument is ignored because this dataset is monocular (only one camera).
        """
        fname = f"frame_{frame_index:05d}_sensor_camera_color" + self.img_ext
        return os.path.join(self.data_path, folder, "color", fname)

    def get_depth_path(self, folder, frame_index):
        """
        Returns the path to the depth image for a given session and frame index.
        """
        fname = f"frame_{frame_index:05d}_sensor_camera_depth" + self.img_ext
        return os.path.join(self.data_path, folder, "depth", fname)

    def check_depth(self):
        """
        Checks if a depth image exists for the first sample in the dataset.
        Used to determine if ground truth depth is available.
        """
        line = self.filenames[0].split()
        folder = line[0]
        frame_index = int(line[1]) if len(line) > 1 else 0
        depth_path = self.get_depth_path(folder, frame_index)
        return os.path.isfile(depth_path)

    def get_color(self, folder, frame_index, side=None, do_flip=False):
        """
        Loads the color image for the given session and frame index.
        Ensures a PIL Image is always returned (never a tuple).
        Uses self.loader (like Monodepth2 wants). If do_flip is True, the image is flipped horizontally (for augmentation).
        """
        color_path = self.get_image_path(folder, frame_index)
        color = self.loader(color_path)
        # If loader returns a tuple (image, ...), extract the image
        if isinstance(color, tuple):
            color = color[0]
        if not isinstance(color, Image.Image):
            color = Image.fromarray(np.array(color))
        if do_flip:
            color = color.transpose(Image.FLIP_LEFT_RIGHT)
        return color

    def get_depth(self, folder, frame_index, side, do_flip):
        """
        Returns the ground truth depth map for a given session and frame index.
        The depth PNGs are 8-bit (0-255). For KITTI-style evaluation, values are converted to meters using:
        depth = value / 255.0 * (far - near) + near
        Conversion is done before resizing, so interpolation is in metric space.
        """
        depth_path = self.get_depth_path(folder, frame_index)
        depth_gt = Image.open(depth_path)
        depth_gt = np.array(depth_gt).astype(np.float32)
        near = 0.1
        far = 1000.0
        depth_gt = depth_gt / 255.0 * (far - near) + near
        depth_gt = Image.fromarray(depth_gt).resize(self.full_res_shape, Image.NEAREST)
        depth_gt = np.array(depth_gt).astype(np.float32)
        if do_flip:
            depth_gt = np.fliplr(depth_gt)
        return depth_gt
