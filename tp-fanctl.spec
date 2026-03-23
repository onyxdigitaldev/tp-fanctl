Name:           tp-fanctl
Version:        1.0.0
Release:        1%{?dist}
Summary:        Adaptive fan controller for ThinkPad laptops
License:        MIT
URL:            https://github.com/onyxdigitaldev/tp-fanctl
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
Requires:       python3 >= 3.10
Requires:       thinkfan
Recommends:     python3-gobject
Recommends:     libappindicator-gtk3

%description
Adaptive fan controller for ThinkPad laptops. Automatically switches between
quiet and gaming fan profiles based on CPU load. Built on top of thinkfan.

Features:
- Hysteresis with asymmetric thresholds prevents profile thrashing
- Fast engagement (12s), slow disengagement (30s)
- System tray applet with manual override
- Clean shutdown restores BIOS fan control

%prep
%setup -q

%install
install -Dm 755 bin/tp-fanctl %{buildroot}%{_bindir}/tp-fanctl
install -Dm 755 bin/tp-fanctl-tray %{buildroot}%{_bindir}/tp-fanctl-tray
install -Dm 755 bin/tp-fanctl-gaming %{buildroot}%{_bindir}/tp-fanctl-gaming
install -Dm 755 bin/tp-fanctl-quiet %{buildroot}%{_bindir}/tp-fanctl-quiet
install -Dm 644 config/thinkfan-quiet.yaml %{buildroot}%{_sysconfdir}/thinkfan.yaml
install -Dm 644 config/thinkfan-gaming.yaml %{buildroot}%{_sysconfdir}/thinkfan-gaming.yaml
install -Dm 644 systemd/tp-fanctl.service %{buildroot}%{_unitdir}/tp-fanctl.service
install -Dm 644 systemd/tp-fanctl-tray.desktop %{buildroot}%{_sysconfdir}/xdg/autostart/tp-fanctl-tray.desktop

%post
cp %{_sysconfdir}/thinkfan.yaml %{_sysconfdir}/thinkfan-active.yaml 2>/dev/null || true
if [ ! -f /etc/modprobe.d/thinkfan.conf ] || ! grep -q "fan_control=1" /etc/modprobe.d/thinkfan.conf 2>/dev/null; then
    mkdir -p /etc/modprobe.d
    echo "options thinkpad_acpi fan_control=1" > /etc/modprobe.d/thinkfan.conf
fi
mkdir -p %{_sysconfdir}/systemd/system/thinkfan.service.d
cat > %{_sysconfdir}/systemd/system/thinkfan.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=/usr/sbin/thinkfan -c /etc/thinkfan-active.yaml
EOF
%systemd_post tp-fanctl.service

%preun
%systemd_preun tp-fanctl.service

%postun
%systemd_postun_with_restart tp-fanctl.service

%files
%license LICENSE
%doc README.md
%{_bindir}/tp-fanctl
%{_bindir}/tp-fanctl-tray
%{_bindir}/tp-fanctl-gaming
%{_bindir}/tp-fanctl-quiet
%config(noreplace) %{_sysconfdir}/thinkfan.yaml
%config(noreplace) %{_sysconfdir}/thinkfan-gaming.yaml
%{_unitdir}/tp-fanctl.service
%{_sysconfdir}/xdg/autostart/tp-fanctl-tray.desktop

%changelog
* Sun Mar 23 2026 Onyx Digital <dev@onyxdigital.dev> - 1.0.0-1
- Initial release
