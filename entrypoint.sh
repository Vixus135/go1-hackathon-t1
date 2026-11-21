#!/bin/bash
source /opt/ros/humble/setup.bash

# Если передан аргумент ping
if [ "$1" = "ping" ]; then
    echo '{"protocol_version": "1.0", "supported_tasks": ["T2", "T3", "T4", "T5"], "self_trained_rl": false, "preferred_speed_mps": 0.3}'
    exit 0

elif [ "$1" = "T2" ]; then
    # Подключаем Unitree и наш пакет
    source /home/participant/unitree_ws/install/setup.bash
    source /home/participant/ros2_ws/install/setup.bash
    # Запускаем наш узел безопасности
    ros2 run safety_block safety_node

elif [ "$1" = "T3" ] || [ "$1" = "T4" ] || [ "$1" = "T5" ]; then
    echo "Запуск задания $1..." >&2
    sleep infinity
else
    echo "Неизвестный аргумент: $1. Используйте ping, T2, T3, T4 или T5." >&2
    exit 1
fi
