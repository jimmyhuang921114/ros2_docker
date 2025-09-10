FROM ros:humble-ros-base 

RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential python3-colcon-common-extensions git && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash work && \
    echo "work ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER work

COPY ./src ./src
# RUN . /opt/ros/$ROS_DISTRO/setup.sh && colcon build --symlink-install


