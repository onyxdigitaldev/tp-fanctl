#!/bin/bash
set -euo pipefail

# tp-fanctl installer
# Works on Fedora, Bazzite, Arch, and any distro with thinkfan + thinkpad_acpi

RED='\033[0;31m'
GRN='\033[0;32m'
DIM='\033[2m'
RST='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

info()  { echo -e "${GRN}[+]${RST} $1"; }
warn()  { echo -e "${RED}[!]${RST} $1"; }
dim()   { echo -e "${DIM}    $1${RST}"; }

# ── Preflight ────────────────────────────────────────────

if [[ $EUID -ne 0 ]]; then
    warn "Run as root: sudo ./install.sh"
    exit 1
fi

if [[ ! -f /proc/acpi/ibm/fan ]]; then
    warn "No ThinkPad fan interface found (/proc/acpi/ibm/fan missing)"
    warn "This tool requires a ThinkPad with thinkpad_acpi loaded"
    exit 1
fi

if ! command -v thinkfan &>/dev/null; then
    warn "thinkfan not found. Install it first:"
    dim "Fedora/Bazzite: sudo dnf install thinkfan  (or rpm-ostree install thinkfan)"
    dim "Arch:           sudo pacman -S thinkfan"
    dim "Debian/Ubuntu:  sudo apt install thinkfan"
    exit 1
fi

if ! python3 -c "import gi" &>/dev/null; then
    warn "python3-gobject not found (needed for tray applet)"
    dim "Fedora/Bazzite: sudo dnf install python3-gobject"
    dim "Arch:           sudo pacman -S python-gobject"
    dim "Debian/Ubuntu:  sudo apt install python3-gi"
    dim "The daemon will still work without it — only the tray applet needs GTK"
fi

# ── Install binaries ─────────────────────────────────────

info "Installing binaries to /usr/local/bin/"
install -m 755 "$SCRIPT_DIR/bin/tp-fanctl"        /usr/local/bin/
install -m 755 "$SCRIPT_DIR/bin/tp-fanctl-tray"    /usr/local/bin/
install -m 755 "$SCRIPT_DIR/bin/tp-fanctl-gaming"  /usr/local/bin/
install -m 755 "$SCRIPT_DIR/bin/tp-fanctl-quiet"   /usr/local/bin/

# ── Install configs ──────────────────────────────────────

info "Installing fan profiles to /etc/"
if [[ ! -f /etc/thinkfan.yaml ]]; then
    install -m 644 "$SCRIPT_DIR/config/thinkfan-quiet.yaml" /etc/thinkfan.yaml
    dim "Installed quiet profile as /etc/thinkfan.yaml"
else
    dim "Skipping /etc/thinkfan.yaml (already exists)"
fi

if [[ ! -f /etc/thinkfan-gaming.yaml ]]; then
    install -m 644 "$SCRIPT_DIR/config/thinkfan-gaming.yaml" /etc/thinkfan-gaming.yaml
    dim "Installed gaming profile as /etc/thinkfan-gaming.yaml"
else
    dim "Skipping /etc/thinkfan-gaming.yaml (already exists)"
fi

# Set active profile to quiet
cp /etc/thinkfan.yaml /etc/thinkfan-active.yaml

# ── Enable fan control ───────────────────────────────────

info "Configuring thinkpad_acpi fan control"
MODPROBE_CONF="/etc/modprobe.d/thinkfan.conf"
if [[ ! -f "$MODPROBE_CONF" ]] || ! grep -q "fan_control=1" "$MODPROBE_CONF" 2>/dev/null; then
    echo "options thinkpad_acpi fan_control=1" > "$MODPROBE_CONF"
    dim "Created $MODPROBE_CONF"
    dim "NOTE: Reboot required for fan_control to take effect"
else
    dim "Already configured"
fi

# ── Thinkfan service override ────────────────────────────

info "Configuring thinkfan to use active profile"
mkdir -p /etc/systemd/system/thinkfan.service.d
cat > /etc/systemd/system/thinkfan.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=/usr/sbin/thinkfan -c /etc/thinkfan-active.yaml
EOF

# ── Install systemd service ──────────────────────────────

info "Installing tp-fanctl service"
install -m 644 "$SCRIPT_DIR/systemd/tp-fanctl.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable tp-fanctl.service
dim "Service enabled (will start after reboot, or: sudo systemctl start tp-fanctl)"

# ── Tray autostart ───────────────────────────────────────

info "Installing tray autostart"
# Install for all users via /etc/xdg
mkdir -p /etc/xdg/autostart
install -m 644 "$SCRIPT_DIR/systemd/tp-fanctl-tray.desktop" /etc/xdg/autostart/
dim "Tray applet will start on login for all users"

# ── Summary ──────────────────────────────────────────────

echo ""
info "Installation complete"
echo ""
dim "Files installed:"
dim "  /usr/local/bin/tp-fanctl           — adaptive fan daemon"
dim "  /usr/local/bin/tp-fanctl-tray      — system tray applet"
dim "  /usr/local/bin/tp-fanctl-gaming    — manual gaming profile switch"
dim "  /usr/local/bin/tp-fanctl-quiet     — manual quiet profile switch"
dim "  /etc/thinkfan.yaml                 — quiet fan curve"
dim "  /etc/thinkfan-gaming.yaml          — gaming fan curve"
dim "  /etc/thinkfan-active.yaml          — active profile (symlink target)"
dim "  /etc/systemd/system/tp-fanctl.service"
dim "  /etc/xdg/autostart/tp-fanctl-tray.desktop"
echo ""

FAN_CTRL=$(cat /sys/module/thinkpad_acpi/parameters/fan_control 2>/dev/null || echo "N")
if [[ "$FAN_CTRL" == "N" ]]; then
    warn "fan_control is not yet active — reboot required"
else
    info "fan_control is active — you can start now: sudo systemctl start tp-fanctl"
fi
