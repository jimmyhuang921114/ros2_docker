# base image
FROM osrf/ros:humble-desktop-full

# arguments
ARG USER=work
ARG GROUP=work
ARG UID=1000
ARG GID=1000
ARG SHELL=/bin/bash

# environment
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ENV DEBIAN_FRONTEND=noninteractive


SHELL ["/bin/bash", "-c"]

# ROS2 dep
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo git htop wget curl psmisc tmux udev libtool \
    terminator \
    python3-pip python3-dev python3-setuptools \
    python3-colcon-common-extensions \
    python3-rosdep python3-vcstool \
    software-properties-common lsb-release \
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

# rosdep init
RUN rosdep init || true && rosdep update

# realsense install
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake pkg-config \
    libusb-1.0-0-dev libglfw3-dev libgtk-3-dev \
    libssl-dev \
 && rm -rf /var/lib/apt/lists/*

# clone and cmake librealsense
RUN git clone --depth 1 -b v2.57.5 https://github.com/realsenseai/librealsense.git /tmp/librealsense \
 && cd /tmp/librealsense \
 && mkdir -p build && cd build \
 && cmake .. \
 && make -j"$(nproc)" \
 && make install \
 && rm -rf /tmp/librealsense

# create workspace
WORKDIR /ros_ws
RUN mkdir -p /ros_ws/src

# copy repos file into tmp package
COPY src/tb4_arm_ros2/dynamixel_control.repos /tmp/dynamixel_control.repos

# using vcs to install repos dep
RUN vcs import /ros_ws/src < /tmp/dynamixel_control.repos

#install rosdep in workspace 
RUN apt-get update \
 && rosdep install --from-paths /ros_ws/src --ignore-src -r -y --rosdistro humble \
 && rm -rf /var/lib/apt/lists/*

# python dep
RUN python3 -m pip install --no-cache-dir \
    opencv-python==4.11.0.86 \
    opencv-contrib-python==4.11.0.86 \
    numpy==1.26.4

RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc

# copy entrypoint script
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# create user and add into group
RUN groupadd -g ${GID} ${GROUP} \
 && useradd -m -u ${UID} -g ${GID} -s ${SHELL} ${USER} \
 && usermod -aG sudo ${USER} \
 && echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} \
 && chmod 0440 /etc/sudoers.d/${USER}

# make sure bashrc exists for the user
RUN mkdir -p /home/${USER} \
 && chown -R ${UID}:${GID} /home/${USER} \
 && touch /home/${USER}/.bashrc \
 && chown ${UID}:${GID} /home/${USER}/.bashrc


USER ${USER}
ENV HOME=/home/${USER}
WORKDIR /home/${USER}

RUN echo "source /opt/ros/humble/setup.bash" >> /home/${USER}/.bashrc



# container start use this entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# bash
CMD ["bash"]