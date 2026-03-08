#!/usr/bin/env bash
set -e

# -------------------------------
# ROS environment
# -------------------------------
source /opt/ros/humble/setup.bash



export ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
export RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION:-rmw_cyclonedds_cpp}

# -------------------------------
# Interactive shell handling
# -------------------------------
# Always ensure interactive bash loads ~/.bashrc when starting a shell
if [ $# -eq 0 ]; then
  exec bash -i
fi

if [ "$1" = "bash" ]; then
  shift
  exec bash -i "$@"
fi

exec "$@"