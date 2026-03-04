# base
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



# ---- base tools + ros dev tools ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo git htop wget curl psmisc tmux udev libtool \
    python3-pip python3-dev python3-setuptools \
    python3-colcon-common-extensions \
    python3-rosdep python3-vcstool \
    software-properties-common lsb-release \
    ros-humble-rmw-cyclonedds-cpp \
 && rm -rf /var/lib/apt/lists/*

# ---- MoveIt2 (Humble) ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-moveit \
    ros-humble-moveit-setup-assistant \
 && rm -rf /var/lib/apt/lists/*

# ---- Nav2 (Humble) ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-humble-navigation2 \
    ros-humble-nav2-bringup \
 && rm -rf /var/lib/apt/lists/*

RUN if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then \
      rosdep init; \
    fi && rosdep update

# ----- realsense -----
RUN git clone https://github.com/realsenseai/librealsense.git -b v2.57.5 && cd librealsense \
    && mkdir build && cd build && cmake .. && make uninstall && make clean && make && sudo make install


# dynamixel ros2 dep
RUN rosdep init || true
RUN rosdep update

# Create ROS 2 workspace
WORKDIR /ws/src

# Clone packages into src
RUN git clone -b ros2 https://github.com/ROBOTIS-GIT/dynamixel-workbench.git
RUN git clone -b ros2 https://github.com/ROBOTIS-GIT/dynamixel-workbench-msgs.git


# Install dependencies of all packages under src
WORKDIR /ws

RUN apt-get update && apt-get install -y \
    python3-rosdep \
    ros-humble-ros2-control \
    ros-humble-ros2-controllers \
    && rm -rf /var/lib/apt/lists/*

    
# tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3-rosdep \
  && rosdep init || true \
  && rosdep update \
  && rm -rf /var/lib/apt/lists/*

# your source must already be in /ws/src here (COPY or git clone)
WORKDIR /ws

# IMPORTANT: refresh apt lists again (because we deleted them above)
RUN apt-get update \
  && rosdep install --from-paths src --ignore-src -r -y --rosdistro humble \
  && rm -rf /var/lib/apt/lists/*

# ----- other -----
RUN sudo mkdir -p /home/"${USER}"/work
WORKDIR /home/"${USER}"/work

# convenience: auto-source ROS
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc


#moveit update lacking of lib, manaual install here
RUN sudo apt update
RUN sudo apt install -y ros-humble-geometric-shapes
RUN sudo apt install -y ros-humble-srdfdom
RUN sudo apt install -y ros-humble-visp
RUN sudo pip install opencv-python==4.11.0.86
RUN sudo pip install opencv--contrib-python==4.11.0.86
RUN sudo pip install numpy==1.26.4

WORKDIR /home/"${USER}"/work

# ---- create user ----
RUN groupadd -g ${GID} ${GROUP} \
 && useradd -m -u ${UID} -g ${GID} -s ${SHELL} ${USER} \
 && usermod -aG sudo ${USER} \
 && echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER} \
 && chmod 0440 /etc/sudoers.d/${USER}

USER ${USER}
WORKDIR /home/${USER}/work/work


