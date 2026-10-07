FROM osrf/ros:lyrical-desktop-full

ARG USERNAME=lain
ARG USER_UID=1000
ARG USER_GID=1000

RUN apt-get update && apt-get install -y \
    sudo \
    git \
    nano \
    ros-dev-tools \
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

RUN echo 'source /opt/ros/lyrical/setup.bash' >> /home/${USERNAME}/.bashrc && \
    echo 'export PYTHONNOUSERSITE=1' >> /home/${USERNAME}/.bashrc

USER ${USERNAME}

WORKDIR /home/${USERNAME}/ros2_ws
