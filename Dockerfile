# 1. Базовый образ: Ubuntu 22.04 - по требованию из тз
FROM ubuntu:22.04

# Избегаем интерактивных запросов при установке пакетов
ENV DEBIAN_FRONTEND=noninteractive

# 2. Установка базовых утилит
RUN apt-get update && apt-get install -y \
    locales \
    curl \
    gnupg \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*
RUN locale-gen en_US en_US.UTF-8 
RUN update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/ros2.list > /dev/null

# 3. Устанавливаем ROS 2 Humble и Cyclone DDS
RUN apt-get update && apt-get install -y \
	ros-humble-ros-base \
	ros-humble-rmw-cyclonedds-cpp \
	python3-colcon-common-extensions \
	&& rm -rf /var/lib/apt/lists/*

# 4. Настройка окружения ROS 2 и DDS по умолчанию
ENV ROS_DISTRO=humble
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
# Автоматически сорсим ROS 2 при старте bash
RUN echo "source /opt/ros/humble/setup.bash" >> /etc/bash.bashrc

# 5. Создание non-root пользователя
RUN useradd -m -u 1000 -s /bin/bash participant

# 6. Копируем entrypoint.sh и задаём владельца (COPY работает от root)
COPY --chown=participant:participant entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# 7. Переключаемся на пользователя
USER participant
WORKDIR /home/participant

# 8. Точка входа
ENTRYPOINT ["/entrypoint.sh"]
