#!/usr/bin/env bash
set -e

source /opt/ros/humble/setup.bash

if [ -f /work/install/setup.bash ]; then
    source /work/install/setup.bash
fi

exec "$@"