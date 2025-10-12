# ==== ROS 2 Humble Desktop（含 RViz2 / rqt 等）====
FROM osrf/ros:humble-desktop

#environment setting
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Taipei \
    SHELL=/bin/bash
#install base tools
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      python3-colcon-common-extensions \
      tree \
      git \
      sudo \
      locales \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

#add user
RUN useradd -ms /bin/bash work && \
    echo "work ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER work

#set work dir
WORKDIR /home/work
RUN echo 'source /opt/ros/$ROS_DISTRO/setup.bash' >> ~/.bashrc
CMD ["bash"]
