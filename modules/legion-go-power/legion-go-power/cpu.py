import subprocess
import logging

logger = logging.getLogger(__name__)

def runCommand(cmd: str):
    logger.info(f"Running command: \n{cmd}")
    return subprocess.run(cmd, shell=True, check=True)

def set_cpu_boost(enabled: bool):
    logger.info(f"Changing CPU boost to {enabled}")
    boost = 1 if enabled else 0
    runCommand(f'''echo {boost} | tee /sys/devices/system/cpu/cpufreq/boost''')

def set_cpu_governor(governor: str):
    logger.info(f"Changing CPU governor to {governor}")
    runCommand(f'''echo {governor} | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor''')

def set_cpu_epp(epp: str):
    logger.info(f"Changing CPU EPP to {epp}")
    runCommand(f'''echo {epp} | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference''')

def set_cpu_min_freq(min_freq: int = 0):
    _min_freq: str = '$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq)' if min_freq == 0 else min_freq
    logger.info(f"Changing CPU min_freq to {"lowest possible" if min_freq == 0 else min_freq}")
    runCommand(f'''echo {_min_freq} | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq''')

def set_scx_scheduler(scheduler: str):
    logger.info(f"Changing SCX Scheduler to {scheduler}")
    runCommand(f'''[ "$(cat /sys/kernel/sched_ext/state)" = enabled ] && current_sched=$(cat /tmp/current-scx-scheduler) && pkill "$current_sched"; new_sched='{scheduler}'; echo "$new_sched" > /tmp/current-scx-scheduler && nohup $new_sched >/dev/null 2>&1 &''')
