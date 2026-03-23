# tp-fanctl

Adaptive fan controller for ThinkPad laptops. Automatically switches between quiet and gaming fan curves based on CPU load — no manual intervention needed.

Built on top of [thinkfan](https://github.com/vmatare/thinkfan). Designed for ThinkPads with `thinkpad_acpi` fan control. Tested on the T580 but should work on any ThinkPad that thinkfan supports.

## How it works

`tp-fanctl` monitors CPU utilization by reading `/proc/stat` every 3 seconds. When sustained load is detected, it switches thinkfan to an aggressive cooling profile. When load drops, it switches back to a quiet profile.

**Hysteresis prevents thrashing:**
- Gaming mode engages after **12 seconds** of sustained >55% CPU
- Quiet mode re-engages after **30 seconds** of sustained <25% CPU
- Counter decay (not hard reset) absorbs transient spikes and dips

The asymmetry is deliberate — ramp up fast to protect thermals, ramp down slow to survive loading screens.

On shutdown, BIOS auto fan control is restored.

## Components

| File | Purpose |
|------|---------|
| `tp-fanctl` | Adaptive fan daemon (Python 3, zero deps) |
| `tp-fanctl-tray` | System tray applet (GTK3 + AppIndicator3) |
| `tp-fanctl-gaming` | Manual switch to gaming profile |
| `tp-fanctl-quiet` | Manual switch to quiet profile |

The tray applet shows a **purple Q** in quiet mode and a **blue G** in gaming mode. Right-click for manual override.

## Requirements

- A ThinkPad with `thinkpad_acpi` kernel module
- `thinkfan` installed and working
- Python 3.10+
- `python3-gobject` + `libappindicator-gtk3` (for tray applet only)

## Install

```bash
git clone <this-repo>
cd tp-fanctl
sudo ./install.sh
sudo reboot  # required for fan_control=1 to take effect
```

The installer:
1. Copies binaries to `/usr/local/bin/`
2. Installs fan curve configs to `/etc/`
3. Enables `thinkpad_acpi fan_control=1` via modprobe
4. Configures thinkfan to use the active profile
5. Installs and enables the systemd service
6. Sets up tray applet autostart

### Immutable distros (Bazzite, Silverblue, etc.)

Layer thinkfan first:
```bash
rpm-ostree install thinkfan
sudo reboot
```

Then run the installer as normal. All files go to `/usr/local/` and `/etc/`, which persist across updates.

## Fan curves

Edit `/etc/thinkfan.yaml` (quiet) and `/etc/thinkfan-gaming.yaml` (gaming) to adjust temperature thresholds and fan levels.

You may need to adjust the `coretemp` sensor indices to match your CPU core count. Find your sensors:

```bash
find /sys/class/hwmon -name name -exec sh -c 'echo "$(cat {}): $(dirname {})"' \;
sensors
```

## Uninstall

```bash
sudo ./uninstall.sh
```

## License

MIT
