#!/bin/bash
# Launch RF-DETR detection pipeline — one gnome-terminal tab per node.
# Usage:
#   ./launch.sh /path/to/video.mp4          # single file
#   ./launch.sh /path/to/folder/            # all .mp4 files in folder, played sequentially
# Edit SENSOR_NAME and DET_CONFIGS below before running.

export MSIGHT_EDGE_DEVICE_NAME=mcity_edge
VENV="/home/dataengine/Mcity/Msight/venv/bin/activate"
INPUT="${1:-/home/dataengine/Mcity/Msight/SIP_GS_Feeds/}"
SENSOR_NAME="my_camera"
DET_CONFIGS="$(dirname "$(realpath "$0")")/rfdetr_config.yaml"

# Clear stale node registrations left by any previous unclean exit.
# MSight stores node state in the Redis hash MSIGHT:NODES keyed by node name.
redis-cli hdel MSIGHT:NODES video_source rfdetr_detector detection_viewer > /dev/null 2>&1 || true

# Choose launcher based on whether INPUT is a directory or a file.
if [ -d "$INPUT" ]; then
  SOURCE_CMD="msight_launch_mp4_folder --name video_source --sensor-name ${SENSOR_NAME} --publish-topic camera/${SENSOR_NAME} --folder ${INPUT}"
else
  SOURCE_CMD="msight_launch_rtsp --name video_source --sensor-name ${SENSOR_NAME} --publish-topic camera/${SENSOR_NAME} --url ${INPUT}"
fi

gnome-terminal \
  --tab --title="Redis" \
    --command="bash -c 'redis-server; exec bash'" \
  --tab --title="Video Source" \
    --command="bash -c 'source ${VENV} && ${SOURCE_CMD}; exec bash'" \
  --tab --title="RF-DETR Detector" \
    --command="bash -c 'source ${VENV} && msight_launch_rfdetr_detection \
      --name rfdetr_detector \
      --subscribe-topic camera/${SENSOR_NAME} \
      --publish-topic detection/${SENSOR_NAME} \
      --det-configs ${DET_CONFIGS}; exec bash'" \
  --tab --title="2D Viewer" \
    --command="bash -c 'source ${VENV} && msight_launch_2d_viewer \
      --name detection_viewer \
      --subscribe-topic detection/${SENSOR_NAME}; exec bash'"
