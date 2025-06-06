{ config, lib, pkgs, ... }:

let
	cfg = config.modules.vm;
in {
	options.modules.vm = {
		enable = lib.mkEnableOption "Enable boot loader";
		gpuPassthrough.enable = lib.mkEnableOption "Enable gpu passthrough";
		defaultDomain = lib.mkOption {
			default = "win-passthrough";
			description = "default libvirt domain";
		};
		defaultUSBDevices = lib.mkOption {
			default = "$HOME/virt/usb.json";
			description = "path to usb devices json";
		};
	};

	config = lib.mkIf cfg.enable {
		boot.kernelParams = [
			"intel_iommu=on"
			"amd_iommu=on"
		];
		users.users.ivan.extraGroups = [
			"kvm"
			"libvirtd"
		];
		systemd.services.libvirtd = lib.mkIf cfg.gpuPassthrough.enable {
			preStart = ''
rm -rf /var/lib/libvirt/hooks
mkdir -p /var/lib/libvirt/hooks
mkdir -p /var/lib/libvirt/hooks/qemu.d/win-passthrough/prepare/begin
mkdir -p /var/lib/libvirt/hooks/qemu.d/win-passthrough/release/end

echo '#!/run/current-system/sw/bin/bash

GUEST_NAME="$1"
HOOK_NAME="$2"
STATE_NAME="$3"

BASEDIR="$(dirname $0)"

if [ "$(echo "$GUEST_NAME" | grep "tmp-")" ]; then
	GUEST_NAME="$(echo "$GUEST_NAME" | sed "s|tmp-||")"
fi
HOOKPATH="$BASEDIR/qemu.d/$GUEST_NAME/$HOOK_NAME/$STATE_NAME"
set -e # If a script exits with an error, we should as well.

if [ -f "$HOOKPATH" ]; then
	eval \""$HOOKPATH"\" "$@"
elif [ -d "$HOOKPATH" ]; then
	while read file; do
		eval \""$file"\" "$@"
	done <<< "$(find -L "$HOOKPATH" -maxdepth 1 -type f -executable -print;)"
fi
' > /var/lib/libvirt/hooks/qemu
echo '#!/run/current-system/sw/bin/bash
set -x

echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind
modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia snd_hda_intel

systemctl set-property --runtime -- system.slice AllowedCPUs=5
systemctl set-property --runtime -- user.slice AllowedCPUs=5
systemctl set-property --runtime -- init.scope AllowedCPUs=5
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
' > /var/lib/libvirt/hooks/qemu.d/win-passthrough/prepare/begin/start.sh
echo '#!/run/current-system/sw/bin/bash
set -x

systemctl set-property --runtime -- system.slice AllowedCPUs=0-5
systemctl set-property --runtime -- user.slice AllowedCPUs=0-5
systemctl set-property --runtime -- init.scope AllowedCPUs=0-5
echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo balance_performance | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference

echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind
modprobe nvidia_drm
modprobe nvidia_modeset
modprobe nvidia_uvm
modprobe nvidia
modprobe snd_hda_intel
' > /var/lib/libvirt/hooks/qemu.d/win-passthrough/release/end/stop.sh

chmod +x /var/lib/libvirt/hooks/qemu
chmod +x /var/lib/libvirt/hooks/qemu.d/win-passthrough/prepare/begin/start.sh
chmod +x /var/lib/libvirt/hooks/qemu.d/win-passthrough/release/end/stop.sh
			'';
		};
		virtualisation.libvirtd = {
			enable = true;
			qemu = {
				package = pkgs.qemu_kvm;
				ovmf = {
					enable = true;
					packages = [ pkgs.OVMFFull.fd ];
				};
			};
			onBoot = "ignore";
			onShutdown = "shutdown";
		};
		programs.virt-manager.enable = true;
		services.spice-vdagentd.enable = true;
		environment.variables = {
			VIRT_BASE_DOMAIN = cfg.defaultDomain;
			VIRT_USB_DEVICES = cfg.defaultUSBDevices;
			LIBVIRT_DEFAULT_URI = "qemu:///system";
		};
		environment.systemPackages = with pkgs; [
			(pkgs.writeScriptBin "virt" ''
#!/usr/bin/env python

from argparse import ArgumentParser
import subprocess
import os
import sys
import json
from pathlib import Path
import xml.etree.ElementTree as ET


def run_command(cmd: str) -> tuple[str, int]:
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode == 1:
        print(f${"'''"}Warning: command [{cmd}] failed to run. Log:\n{result.stderr.strip()}${"'''"})
    return result.stdout.strip(), result.returncode


if __name__ == "__main__":
    parser = ArgumentParser(prog="virt", description="A libvirt domains manager")
    parser.add_argument("command", choices=["start", "usbdump", "xmlsave"])
    parser.add_argument("-c", "--cdrom", default=[os.getenv("VIRT_CDROM_PATH")] if os.getenv("VIRT_CDROM_PATH") else [], action='append', type=os.path.expanduser, help="path to a cdrom device file")
    parser.add_argument("-u", "--usb", default=os.getenv("VIRT_USB_DEVICES", ""), type=os.path.expanduser, help="path to a usb passthrough file")
    parser.add_argument("-b", "--base", default=os.getenv("VIRT_BASE_DOMAIN", ""), help="base domain name")
    parser.add_argument("path", nargs="?", default="")
    args = parser.parse_args()

    match args.command:
        case "start":
            print(f"domain: {args.base}\ncdrom_path: {args.cdrom}\nusb_devices: {args.usb}\nimage_path: {args.path}")

            _out, _code = run_command(f${"'''"}virsh dominfo "{args.base}"${"'''"})
            if _code == 1:
                raise Exception()
            for cdrom in args.cdrom:
                if not os.path.isfile(cdrom):
                    raise Exception()
            if args.usb != "":
                if not os.path.isfile(args.usb):
                    raise Exception()
            if not os.path.isfile(args.path):
                raise Exception()
            print(_out)

            run_command("systemctl stop scx.service")
            run_command("cpuperf performance")

            tmp_domain = f"tmp-{args.base}"
            tmp_xml_path = f"/tmp/{tmp_domain}.xml"
            _, _code = run_command(f${"'''"}virsh dumpxml "{args.base}" > "{tmp_xml_path}"${"'''"})
            if _code == 1:
                raise Exception()
            tmp_xml = Path(tmp_xml_path)

            root = ET.fromstring(tmp_xml.read_text())
            devs_free: set[str] = { "sda", "sdb", "sdc", "sdd" }
            units_free: set[str] = { "0", "1", "2", "3" }
            for disk in root.findall(".//devices/disk"):
                target = disk.find("target")
                if target is None:
                    devs_free.discard(target.get("dev"))
                address = disk.find("address")
                if address is not None:
                    if address.get("type") == "drive":
                        units_free.discard(address.get("unit"))
            usb_ports_free: set[str] = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" }
            for hostdev in root.findall(".//devices/hostdev"):
                if hostdev.get("type") != "usb":
                    continue
                address = disk.find("address")
                if address is None:
                    continue
                usb_ports_free.discard(target.get("port"))


            devices_tag = root.find("devices")
            for cdrom in args.cdrom:
                if (len(devs_free) == 0) or (len(units_free) == 0):
                    raise Exception(f"No available devs and units left:\n\tdevs: {devs_free}\n\tunits: {units_free}")
                cdrom_dev = devs_free.pop()
                cdrom_unit = units_free.pop()
                cdrom_xml, _ = run_command(f${"'''"}virsh attach-disk --print-xml --domain "{args.base}" --source "{cdrom}" --target "{cdrom_dev}" --type "cdrom" --targetbus "sata" --sourcetype "file" --mode "readonly" --driver "qemu" --subdriver "raw" --address "sata:0.0.{cdrom_unit}" | tr -d "\n"${"'''"})

                devices_tag.append(ET.fromstring(cdrom_xml))


            if args.usb != "":
                with open(args.usb, 'rb') as f:
                    usbs = json.load(f)
                for usb in usbs:
                    if (not usb['active']) or (not (args.base in usb['domains'])):
                        continue
                    devices_tag.append(ET.fromstring(f${"'''"}<hostdev mode='subsystem' type='usb' managed='yes'><source><vendor id='0x{usb['vendor_id']}'/><product id='0x{usb['product_id']}'/></source><address type='usb' bus='0' port='{usb_ports_free.pop()}'/></hostdev>${"'''"}))

            name = root.find("name")
            if name is None:
                raise Exception("Cannot find name tag on domain xml")
            name.text = tmp_domain

            uuid = root.find("uuid")
            if uuid is not None:
                root.remove(uuid)

            tmp_xml.write_text(
                ET.tostring(root, encoding='unicode')
                   .replace("CONFIG_DISK_PATH", args.path)
                   .replace("CONFIG_NVRAM_PATH", f"/var/lib/libvirt/qemu/nvram/{os.path.basename(args.path)}_VARS.fd")
            )

            run_command(f"virsh create {tmp_xml.absolute()}")
        case "xmlsave":
            output_dir = Path(args.path)
            if not output_dir.is_dir():
                raise Exception()

            _out, _ = run_command(${"'''"}virsh list --all | tail -n 3 | head -n -1 | cut -d " " -f 6${"'''"})
            domains = _out.split('\n')

            for domain in domains:
                output_file = output_dir / f"{domain}.xml"
                run_command(f${"'''"}virsh dumpxml '{domain}' > '{output_file}' ${"'''"})
                print(f"{domain} -> {output_file.absolute()}")
        case "usbdump":
            output_file = Path(args.path if args.path != "" else args.usb)

            _out, _ = run_command(${"'''"}lsusb | cut -d " " -f 6-${"'''"})
            usbs_str = _out.split('\n')
            usbs = []
            for usb_str in usbs_str:
                usbs.append({
                    "vendor_id": usb_str.split(' ')[0].split(':')[0],
                    "product_id": usb_str.split(' ')[0].split(':')[1],
                    "comment": " ".join(usb_str.split(' ')[1:]),
                    "domains": [ args.base ],
                    "active": False,
                })

            print(f"--> {args.usb}")
            output_file.write_text(json.dumps(usbs, indent=4))
'')
			pkgs.usbutils
			pkgs.python3Minimal
		];
	};
}

