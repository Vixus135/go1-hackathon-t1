FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Утилиты и локаль
RUN apt-get update && apt-get install -y \
    locales curl gnupg lsb-release sudo git \
    && rm -rf /var/lib/apt/lists/*
RUN locale-gen en_US en_US.UTF-8
RUN update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

# 2. Репозиторий ROS 2 Humble
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

# 3. Установка ROS 2 и Cyclone DDS
RUN apt-get update && apt-get install -y \
    ros-humble-ros-base \
    ros-humble-rmw-cyclonedds-cpp \
    ros-humble-rosidl-generator-dds-idl \
    python3-colcon-common-extensions \
    libyaml-cpp-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 4. Настройка окружения
ENV ROS_DISTRO=humble
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# 5. Создаем пользователя
RUN useradd -m -u 1000 -s /bin/bash participant

# 6. Копируем и собираем Unitree ROS 2 (из твоей папки)
# Создаем рабочую директорию для Unitree
WORKDIR /home/participant/unitree_ws
COPY --chown=participant:participant unitree_ros2/cyclonedds_ws /home/participant/unitree_ws
# Собираем Unitree (используем bash -c, чтобы засорсить окружение перед сборкой)
RUN /bin/bash -c "source /opt/ros/humble/setup.bash && colcon build"

# 7. Копируем и собираем твой пакет safety_block
WORKDIR /home/participant/ros2_ws
COPY --chown=participant:participant ros2_ws/src /home/participant/ros2_ws/src
RUN /bin/bash -c "source /opt/ros/humble/setup.bash && source /home/participant/unitree_ws/install/setup.bash && colcon build"

# 8. Копируем entrypoint.sh
WORKDIR /home/participant
COPY --chown=participant:participant entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER participant

ENTRYPOINT ["/entrypoint.sh"]
