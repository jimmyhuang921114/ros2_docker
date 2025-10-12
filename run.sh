#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="my-ros2:dev"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

LEVELS_UP=${LEVELS_UP:-1}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOUNT_DIR="$SCRIPT_DIR"
for _ in $(seq 1 "${LEVELS_UP}"); do
  MOUNT_DIR="$(dirname "$MOUNT_DIR")"
done

echo -e "${YELLOW}Mounting host dir: ${MOUNT_DIR}${NC}"

GPU_FLAG=""
if command -v nvidia-smi &>/dev/null; then  
  GPU_FLAG="--gpus all"
  echo -e "${GREEN}GPU detected.${NC} Enabling GPU support for Docker."
else
  echo -e "${YELLOW}Warning:${NC} GPU not detected. Running without GPU support."
fi



# X11
: "${DISPLAY:=${DISPLAY:-:0}}"
XAUTH_HOST="${XAUTHORITY:-$HOME/.Xauthority}"
if [[ ! -f "$XAUTH_HOST" ]]; then
  echo -e "${YELLOW}Warn:${NC} $XAUTH_HOST 不存在"
fi



echo -e "${YELLOW}Running Docker container from image '$IMAGE_NAME'...${NC}"
docker run -it --rm \
  --net=host --ipc=host --privileged \
  -e DISPLAY="$DISPLAY" \
  -e QT_X11_NO_MITSHM=1 \
  -e XAUTHORITY="$XAUTH_HOST" \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v "$XAUTH_HOST":"$XAUTH_HOST":ro \
  -v /dev:/dev \
  -v "${MOUNT_DIR}":/workspace \
  -w /workspace \
  $GPU_FLAG \
  "$IMAGE_NAME"

rc=$?
if [ $rc -eq 0 ]; then
  echo -e "${GREEN}Success:${NC} Docker container exited successfully."
else
  echo -e "${RED}Error:${NC} Docker container failed to run. (exit $rc)"
  exit $rc
fi
