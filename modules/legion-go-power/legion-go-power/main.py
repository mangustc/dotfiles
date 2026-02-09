import lenovo
import cpu
import logging
import subprocess
import tomllib

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# TODO: add some way to change and view these values in plasma and steam gamescope session

with open('/etc/legion-go-power.toml', 'rb') as f:
    config = tomllib.load(f)

# Lenovo settings
lenovo.set_full_fan_speed(config['lenovo']['full_fan_speed'])
lenovo.set_fan_curve(arr=config['lenovo']['fan_curve'], lim=lenovo.MIN_CURVE)
lenovo.set_power_light(config['lenovo']['power_light'])
lenovo.set_charge_limit(config['lenovo']['charge_limit'])
lenovo.set_tdp_mode(config['lenovo']['tdp_mode'])
lenovo.set_steady_tdp(config['lenovo']['steady_tdp'])
lenovo.set_fast_tdp(config['lenovo']['fast_tdp'])
lenovo.set_slow_tdp(config['lenovo']['slow_tdp'])

# CPU settings
cpu.set_cpu_boost(config['cpu']['cpu_boost'])
cpu.set_cpu_governor(config['cpu']['cpu_governor'])
cpu.set_cpu_epp(config['cpu']['cpu_epp'])
cpu.set_cpu_min_freq(config['cpu']['cpu_min_freq'])
cpu.set_scx_scheduler(config['cpu']['scx_scheduler'])

