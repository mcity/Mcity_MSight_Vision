# MSight Vision

MSight Vision is the camera perception module of the MSight roadside intelligence ecosystem. It provides 2D object detection (YOLO and RF-DETR), fisheye localization, multi-camera fusion, multi-object tracking, and state estimation for intelligent transportation deployments.

It depends on two sibling packages:
- **MSight Base** — shared data types and trajectory abstractions
- **MSight Core** — distributed node runtime and Redis pub/sub orchestration

---

## Prerequisites

- Python 3.10+
- Redis server (`sudo apt install redis-server`)
- `gnome-terminal` (for `launch.sh`)
- Git

---

## Installation

### 1. Clone all three repositories

```bash
git clone https://github.com/michigan-traffic-lab/MSight_base.git
git clone https://github.com/michigan-traffic-lab/MSight_Core.git
git clone https://github.com/mcity/Mcity_MSight_Vision.git
```

### 2. Create a virtual environment inside `Mcity_MSight_Vision`

```bash
cd Mcity_MSight_Vision
python3 -m venv venv
source venv/bin/activate
```

### 3. Install dependencies

```bash
# MSight Base
pip install -e ../MSight_base

# MSight Core
pip install -e ../MSight_Core

# This package (MSight Vision) with RF-DETR support
pip install -e ".[rfdetr]"
```

> **OpenCV note:** `MSight_base` installs `opencv-python-headless`. The viewer node requires GUI support. Fix the conflict after installation:
> ```bash
> pip uninstall -y opencv-python-headless
> pip install --force-reinstall opencv-python
> ```

---

## Calibration Setup

Place camera calibration files for your deployment under `examples/rfdetr/calibration/`:

```
examples/rfdetr/
├── calibration/
│   ├── intrinsics.json        # fisheye camera intrinsics
│   └── locmap.npz             # localization map (x_map, y_map arrays)
└── rfdetr_config.yaml
```

**`intrinsics.json` format:**
```json
{
  "f":  1234.5,
  "x0": 960.0,
  "y0": 540.0
}
```
- `f` — focal length in pixels
- `x0`, `y0` — pixel coordinates of the fisheye optical axis centre

**`locmap.npz`** — a NumPy archive with `x_map` and `y_map` arrays of shape `(H, W)`, where each pixel maps to a latitude/longitude value. Generate this with your site-specific calibration tool.

---

## Model Weights

The RF-DETR weights file is **not included** in this repository. On first run, if `examples/rfdetr/weights/rfdetr_2xlarge_best.pt` is not found, it is downloaded automatically from HuggingFace:

- Repo: `mcity-ai/rfdetr_2xlarge`
- File: `rfdetr_2xlarge_best.pt`

You can also download it manually:
```bash
pip install huggingface_hub
python -c "from huggingface_hub import hf_hub_download; hf_hub_download('mcity-ai/rfdetr_2xlarge', 'rfdetr_2xlarge_best.pt', local_dir='examples/rfdetr/weights')"
```

---

## Configuration

Edit `examples/rfdetr/rfdetr_config.yaml` to match your deployment:

| Key | Description |
|-----|-------------|
| `rfdetr_config.model_name` | Model size: `rfdetr_nano` … `rfdetr_2xlarge` |
| `rfdetr_config.model_path` | Path to trained weights (relative to the config file) |
| `rfdetr_config.num_classes` | Number of classes the model was trained with |
| `rfdetr_config.class_names` | Human-readable class labels (index = class ID) |
| `rfdetr_config.detection_threshold` | Confidence threshold (default `0.2`) |
| `rfdetr_config.sensor_type` | Lens type forwarded to detection result (`fisheye`) |
| `intrinsics` | Path to `intrinsics.json` (relative to config file) |
| `loc_maps` | Path to `.npz` localization map (relative to config file) |

---

## Running the Pipeline

From the `Mcity_MSight_Vision` root directory:

```bash
# Single MP4 file
./launch.sh /path/to/video.mp4

# All MP4 files in a folder, played sequentially
./launch.sh /path/to/folder/
```

This opens four gnome-terminal tabs:

| Tab | Role |
|-----|------|
| **Redis** | Message broker between nodes |
| **Video Source** | Reads video frames and publishes to `camera/<sensor>` |
| **RF-DETR Detector** | Subscribes to frames, runs detection, publishes to `detection/<sensor>` |
| **2D Viewer** | Subscribes to detections and displays bounding boxes on screen |

> **First run:** the RF-DETR Detector tab will download model weights from HuggingFace before starting inference. This may take a few minutes depending on your connection.

### Environment variables

Set these in `launch.sh` before running:

| Variable | Description |
|----------|-------------|
| `MSIGHT_EDGE_DEVICE_NAME` | Unique identifier for this edge node (used in Redis registration) |
| `SENSOR_NAME` | Logical camera name; must match across source, detector, and viewer |

---

## Key Components

| Component | Description |
|-----------|-------------|
| `RFDETRDetectionNode` | RF-DETR inference with fisheye ground-contact localization |
| `YoloOneStageDetectionNode` | YOLO-based detection (multi-sensor, warp-aware) |
| `HashLocalizer` | Maps pixel coordinates to lat/lon via a pre-built lookup table |
| `MP4FolderSourceNode` | Plays all `.mp4` files in a folder sequentially as a camera source |
| `SortTracker` | Multi-object tracker |
| `FiniteDifferenceStateEstimator` | Kinematic state estimation for downstream analytics |

---

## CLI Entry Points

| Command | Description |
|---------|-------------|
| `msight_launch_rfdetr_detection` | RF-DETR detection node |
| `msight_launch_yolo_onestage_detection` | YOLO detection node |
| `msight_launch_mp4_folder` | Folder video source node |
| `msight_launch_rtsp` | RTSP / single-file video source node |
| `msight_launch_sort_tracker` | Tracking node |
| `msight_launch_custom_fuser` | Multi-camera fusion node |
| `msight_launch_finite_difference_state_estimator` | State estimation node |
| `msight_launch_2d_viewer` | Bounding-box viewer |
| `msight_launch_road_user_list_viewer` | Road-user list viewer |

Use `--help` on any command for argument details.

---

## Repository Structure

```
Mcity_MSight_Vision/
├── launch.sh                   # Pipeline launcher (start here)
├── pyproject.toml
├── cli/                        # Entry-point scripts
├── msight_vision/
│   └── msight_core/            # Detection, tracking, fusion, state estimation nodes
└── examples/
    └── rfdetr/
        ├── rfdetr_config.yaml  # Pipeline configuration
        ├── calibration/        # intrinsics.json + locmap.npz (user-provided)
        └── weights/            # Model checkpoint (auto-downloaded)
```

---

## License

BSD 3-Clause License. See [LICENSE](LICENSE) for details.

## Contact

Issues and collaboration requests: https://github.com/mcity/Mcity_MSight_Vision/issues

## Main Developers

- Rusheng Zhang
- Depu Meng
- Haoyu Han
