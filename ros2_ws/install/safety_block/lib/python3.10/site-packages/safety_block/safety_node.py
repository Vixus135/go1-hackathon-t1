import rclpy
from rclpy.node import Node
from unitree_go.msg import LowCmd, LowState
import math

class SafeNode(Node):
    def __init__(self):
        super().__init__('safe_node')

        # Подписки и публикации
        self.sub_in = self.create_subscription(LowCmd, '/lowcmd_bare', self.cb_in, 10)
        self.sub_st = self.create_subscription(LowState, '/lowstate', self.cb_st, 10)
        self.pub_out = self.create_publisher(LowCmd, '/lowcmd', 10)

        # Таймер 50 Гц
        self.tmr = self.create_timer(0.02, self.cb_tmr)

        # Переменные
        self.q_safe = [0.0] * 12
        self.t_last = self.get_clock().now()
        self.last_msg = LowCmd()

        # Лимиты из ТЗ
        self.q_min = [-0.863, -0.686, -2.818, -0.863, -0.686, -2.818,
                      -0.863, -0.686, -2.818, -0.863, -0.686, -2.818]
        self.q_max = [0.863, 4.501, -0.888, 0.863, 4.501, -0.888,
                      0.863, 4.501, -0.888, 0.863, 4.501, -0.888]

        self.dq_max = math.radians(5.0)

    def cb_st(self, msg):
        pass # Состояние пока не используем

    def cb_in(self, msg):
        self.t_last = self.get_clock().now()

        # Проверка на NaN и Inf
        for i in range(12):
            v = msg.motor_cmd[i].q
            if math.isnan(v) or math.isinf(v):
                return # Отбрасываем

        out = LowCmd()

        for i in range(12):
            q_tar = msg.motor_cmd[i].q

            # Ограничение угла
            if q_tar < self.q_min[i]:
                q_tar = self.q_min[i]
            elif q_tar > self.q_max[i]:
                q_tar = self.q_max[i]

            # Ограничение скорости (5 градусов)
            dq = q_tar - self.q_safe[i]
            if abs(dq) > self.dq_max:
                q_tar = self.q_safe[i] + math.copysign(self.dq_max, dq)

            self.q_safe[i] = q_tar

            # Заполняем команду
            out.motor_cmd[i].mode = 0x0A
            out.motor_cmd[i].q = q_tar
            out.motor_cmd[i].dq = 0.0
            out.motor_cmd[i].tau = 0.0
            out.motor_cmd[i].kp = 40.0
            out.motor_cmd[i].kd = 1.0

        self.last_msg = out
        self.pub_out.publish(out)

    def cb_tmr(self):
        # Проверка таймаута (0.5 сек)
        now = self.get_clock().now()
        dt = (now - self.t_last).nanoseconds / 1e9
        if dt > 0.5:
            # Удержание
            hold = LowCmd()
            for i in range(12):
                hold.motor_cmd[i].mode = 0x0A
                hold.motor_cmd[i].q = self.q_safe[i]
                hold.motor_cmd[i].dq = 0.0
                hold.motor_cmd[i].tau = 0.0
                hold.motor_cmd[i].kp = 40.0
                hold.motor_cmd[i].kd = 1.0
            self.pub_out.publish(hold)
        else:
            # Шлем последнюю команду
            self.pub_out.publish(self.last_msg)

rclpy.init()
node = SafeNode()
rclpy.spin(node)
node.destroy_node()
rclpy.shutdown()
