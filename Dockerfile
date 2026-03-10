FROM osrf/ros:humble-desktop-full

ARG USER=work
ARG GROUP=work
ARG UID=1000
ARG GID=1000
ARG SHELL=/bin/bash

ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-c"]

# base tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    git \
    wget \
    curl \
    htop \
    tmux \
    psmisc \
    terminator \
    python3-pip \
    python3-dev \
    python3-setuptools \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
    build-essential \
    cmake \
    pkg-config \
    libusb-1.0-0-dev \
    libglfw3-dev \
    libgtk-3-dev \
    libssl-dev \
    ros-humble-rmw-cyclonedds-cpp \
    ros-humble-moveit \
    ros-humble-moveit-setup-assistant \
    ros-humble-navigation2 \
    ros-humble-nav2-bringup \
    ros-humble-ros2-control \
    ros-humble-ros2-controllers \
    ros-humble-geometric-shapes \
    ros-humble-srdfdom \
    ros-humble-visp \
 && rm -rf /var/lib/apt/lists/*

# rosdep
RUN rosdep init || true && rosdep update

# librealsense
RUN git clone --depth 1 -b v2.57.5 https://github.com/realsenseai/librealsense.git /tmp/librealsense \
 && cd /tmp/librealsense \
 && mkdir build \
 && cd build \
 && cmake .. \
 && make -j$(nproc) \
 && make install \
 && rm -rf /tmp/librealsense

# python deps
RUN pip install --no-cache-dir \
    opencv-python==4.11.0.86 \
    opencv-contrib-python==4.11.0.86 \
    numpy==1.26.4

# -----------------------------
# underlay workspace in image
# -----------------------------
RUN mkdir -p /opt/robot_ws/src
WORKDIR /opt/robot_ws

# copy repos file for underlay deps
COPY src/tb4_arm_ros2/dynamixel_control.repos /tmp/dynamixel_control.repos

# import source deps into underlay
RUN vcs import src < /tmp/dynamixel_control.repos

# install dependencies for underlay
# skip dynamixel_sdk if you provide it from source in repos
RUN source /opt/ros/humble/setup.bash \
 && rosdep install \
      --from-paths src \
      --ignore-src \
      --rosdistro humble \
      -r -y \
      --skip-keys="dynamixel_sdk"

# build underlay
# RUN source /opt/ros/humble/setup.bash \
#  && colcon build --symlink-install

# -----------------------------
# user workspace mount point
# -----------------------------
RUN mkdir -p /work/src

# entrypoint
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# create user
RUN groupadd -g ${GID} ${GROUP} \
 && useradd -m -u ${UID} -g ${GID} -s ${SHELL} ${USER} \
 && usermod -aG sudo ${USER} \
 && echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} \
 && chmod 0440 /etc/sudoers.d/${USER}

RUN chown -R ${UID}:${GID} /opt/robot_ws /work /home/${USER}

USER ${USER}
ENV HOME=/home/${USER}
WORKDIR /work

RUN echo "source /opt/ros/humble/setup.bash" >> /home/${USER}/.bashrc \
 && echo "source /opt/robot_ws/install/setup.bash" >> /home/${USER}/.bashrc \
 && echo 'if [ -f /work/install/setup.bash ]; then source /work/install/setup.bash; fi' >> /home/${USER}/.bashrc

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]