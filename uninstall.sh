#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GRN='\033[0;32m'
DIM='\033[2m'
RST='\033[0m'

info()  { echo -e "${GRN}[+]${RST} $1"; }
dim()   { echo -e "${DIM}    $1${RST}"; }

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[!]${RST} Run as root: sudo ./uninstall.sh"
    exit 1
fi

info "Stopping services"
systemctl stop tp-fanctl.service 2>/dev/null || true
systemctl disable tp-fanctl.service 2>/dev/null || true

info "Restoring BIOS fan control"
echo "level auto" > /proc/acpi/ibm/fan 2>/dev/null || true

info "Removing files"
rm -f /usr/local/bin/tp-fanctl
rm -f /usr/local/bin/tp-fanctl-tray
rm -f /usr/local/bin/tp-fanctl-gaming
rm -f /usr/local/bin/tp-fanctl-quiet
rm -f /etc/systemd/system/tp-fanctl.service
rm -f /etc/xdg/autostart/tp-fanctl-tray.desktop
rm -f /etc/thinkfan-active.yaml
rm -rf /etc/systemd/system/thinkfan.service.d/override.conf

systemctl daemon-reload

echo ""
info "Uninstalled. Fan profiles and thinkfan configs left in /etc/ for manual cleanup."
dim "  /etc/thinkfan.yaml"
dim "  /etc/thinkfan-gaming.yaml"
dim "  /etc/modprobe.d/thinkfan.conf"
