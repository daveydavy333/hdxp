#!/bin/sh
# 03-udev.sh - start eudev: daemon, coldplug the devices already present, wait for the nodes
UDEVD=/usr/local/sbin/udevd
UDEVADM=/usr/local/bin/udevadm
[ -x "$UDEVD" ] && [ -x "$UDEVADM" ] || { echo "udev: not installed, skipping"; exit 0; }
mkdir -p /run/udev
# no hotplug helper: udevd listens for kernel events itself
[ -w /proc/sys/kernel/hotplug ] && echo "" > /proc/sys/kernel/hotplug
"$UDEVD" --daemon
"$UDEVADM" trigger --type=subsystems --action=add
"$UDEVADM" trigger --type=devices --action=add
"$UDEVADM" settle --timeout=10
:
