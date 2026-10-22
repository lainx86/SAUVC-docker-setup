FROM osrf/ros:lyrical-desktop-full

LABEL maintainer="feby <feby@computer.org>"

ARG USERNAME=lain
ARG USER_UID=1000
ARG USER_GID=1000

# Install project dependencies and refresh related ROS libraries in one transaction chain.
# Updating only MAVROS can leave older message/type-support libraries with incompatible symbols.
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    git \
    nano \
    ros-dev-tools \
    python3-numpy \
    python3-opencv \
    python3-pytest \
    python3-setuptools \
    python3-yaml \
    ros-${ROS_DISTRO}-ament-cmake-gtest \
    ros-${ROS_DISTRO}-ament-cmake-pytest \
    ros-${ROS_DISTRO}-cv-bridge \
    ros-${ROS_DISTRO}-mavlink \
    ros-${ROS_DISTRO}-mavros \
    ros-${ROS_DISTRO}-mavros-msgs \
    ros-${ROS_DISTRO}-message-filters \
    ros-${ROS_DISTRO}-ros2bag \
    ros-${ROS_DISTRO}-rosbag2-py \
    ros-${ROS_DISTRO}-rosbag2-storage-mcap \
    ros-${ROS_DISTRO}-vision-msgs \
    && dpkg-query -W -f='${Package}\n' "ros-${ROS_DISTRO}-*" \
       | awk '/(-msgs|-interfaces|-srvs)$/ || /-rosidl/ || /-rmw-fastrtps/' \
       | xargs -r apt-get install -y --no-install-recommends --only-upgrade \
    && geographiclib-get-geoids egm96-5 \
    && if [ ! -f /etc/ros/rosdep/sources.list.d/20-default.list ]; then rosdep init; fi \
    && rm -rf /var/lib/apt/lists/*

# Ubuntu image sudah bisa punya UID/GID 1000.
# Kalau sudah ada, pakai user/group itu dan ubah namanya.
RUN OLD_USER="$(getent passwd ${USER_UID} | cut -d: -f1)" && \
    OLD_GROUP="$(getent group ${USER_GID} | cut -d: -f1)" && \
    if [ -n "$OLD_GROUP" ] && [ "$OLD_GROUP" != "$USERNAME" ]; then \
        groupmod -n "$USERNAME" "$OLD_GROUP"; \
    elif [ -z "$OLD_GROUP" ]; then \
        groupadd --gid ${USER_GID} "$USERNAME"; \
    fi && \
    if [ -n "$OLD_USER" ] && [ "$OLD_USER" != "$USERNAME" ]; then \
        usermod -l "$USERNAME" \
                -d "/home/$USERNAME" \
                -m \
                -s /bin/bash \
                "$OLD_USER"; \
    elif [ -z "$OLD_USER" ]; then \
        useradd --uid ${USER_UID} \
                --gid ${USER_GID} \
                --create-home \
                --shell /bin/bash \
                "$USERNAME"; \
    fi && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME" && \
    chmod 0440 "/etc/sudoers.d/$USERNAME"

RUN mkdir -p /home/${USERNAME}/ros2_ws/src && \
    chown -R ${USER_UID}:${USER_GID} /home/${USERNAME}

RUN echo 'source /opt/ros/lyrical/setup.bash' >> /home/${USERNAME}/.bashrc

ENV PYTHONNOUSERSITE=1

USER ${USERNAME}

# rosdep keeps its database in the current user's home directory.
RUN rosdep update --rosdistro "${ROS_DISTRO}"

WORKDIR /home/${USERNAME}/ros2_ws

# Keep ROS nodes and the CLI daemon on the same transport in every shell.
ENV RMW_IMPLEMENTATION=rmw_fastrtps_cpp \
    FASTDDS_BUILTIN_TRANSPORTS="LARGE_DATA?max_msg_size=1MB&sockets_size=2MB&non_blocking=true"
