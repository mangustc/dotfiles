import lenovo
import cpu
import logging
import subprocess
import tomllib
import sys
import os
import shutil

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# TODO: add some way to change and view these values in plasma and steam gamescope session

if len(sys.argv) > 1:
    user = sys.argv[1]
else:
    logger.info("You should provide user to start the service")
    sys.exit(1)

# Config paths
user_config_dir = f'/home/{user}/.config/legion-go-power'
user_config_path = f'{user_config_dir}/config.toml'
system_config_path = '/usr/local/lib/legion-go-power/config.toml'
user_uid = int(subprocess.check_output(f'id -u {user}', shell=True).decode().strip())
user_gid = int(subprocess.check_output(f'id -g {user}', shell=True).decode().strip())

os.makedirs(user_config_dir, mode=0o755, exist_ok=True)
if not os.path.exists(user_config_path):
    logger.info(f"User config not found at {user_config_path}, copying from system template")
    shutil.copy2(system_config_path, user_config_path)

os.chown(user_config_path, user_uid, user_gid)
os.chmod(user_config_path, 0o644)
os.chown(user_config_dir, user_uid, user_gid)
os.chmod(user_config_dir, 0o755)

with open(user_config_path, 'rb') as f:
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

