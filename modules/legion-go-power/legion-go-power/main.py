import lenovo
import cpu
import logging
import subprocess

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# TODO: add some way to change and view these values in plasma and steam gamescope session

lenovo.set_full_fan_speed(False)
lenovo.set_fan_curve(arr=[44, 48, 55, 60, 71, 80, 90, 115, 115, 115], lim=lenovo.MIN_CURVE)
lenovo.set_power_light(False)
lenovo.set_charge_limit(True)
lenovo.set_tdp_mode("custom")
lenovo.set_steady_tdp(22)
lenovo.set_fast_tdp(22)
lenovo.set_slow_tdp(22)

cpu.set_cpu_boost(False)
cpu.set_cpu_governor("powersave")
cpu.set_cpu_epp("balance_performance")
cpu.set_cpu_min_freq()
cpu.set_scx_scheduler("scx_lavd")

