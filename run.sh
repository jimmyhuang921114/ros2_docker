#!/usr/bin/env bash

docker run --rm \
    --privileged \
    --network=host \
    --ipc=host \
    ${GPU_FLAG} \
    -v /tmp/.Xauthority:/home/"${USER}"/.Xauthority \
    -e XAUTHORITY=/home/"${USER}"/.Xauthority \
    -e DISPLAY="${DISPLAY}" \
    -e QT_X11_NO_MITSHM=1 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /etc/timezone:/etc/timezone:ro \
    -v /etc/localtime:/etc/localtime:ro \
    -v /dev:/dev \
    -v "$PWD/..":/work \
    -it --name my_container robotsot:latest