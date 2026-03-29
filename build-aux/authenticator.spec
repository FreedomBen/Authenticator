%global app_id com.belmoussaoui.Authenticator

Name:           authenticator
Version:        4.6.2
Release:        1%{?dist}
Summary:        Two-factor authentication code generator for GNOME

License:        GPL-3.0-or-later
URL:            https://gitlab.gnome.org/World/Authenticator
Source0:        %{url}/-/archive/%{version}/Authenticator-%{version}.tar.gz
# Generate with: cd Authenticator-$VERSION && cargo vendor
Source1:        vendor.tar.xz

BuildRequires:  meson >= 0.59
BuildRequires:  rust-packaging
BuildRequires:  cargo
BuildRequires:  pkgconfig(glib-2.0) >= 2.56
BuildRequires:  pkgconfig(gio-2.0) >= 2.56
BuildRequires:  pkgconfig(gtk4) >= 4.10
BuildRequires:  pkgconfig(libadwaita-1) >= 1.8
BuildRequires:  pkgconfig(gstreamer-1.0) >= 1.18
BuildRequires:  pkgconfig(gstreamer-base-1.0) >= 1.18
BuildRequires:  pkgconfig(gstreamer-plugins-base-1.0) >= 1.18
BuildRequires:  pkgconfig(sqlite3)
BuildRequires:  desktop-file-utils
BuildRequires:  gettext

Requires:       gtk4 >= 4.10
Requires:       libadwaita >= 1.8
Requires:       gstreamer1 >= 1.18
Requires:       gstreamer1-plugins-base >= 1.18

%description
Authenticator is a GNOME application for generating two-factor authentication
codes (TOTP, HOTP, and Steam). It supports scanning QR codes, importing and
exporting accounts from various formats (Aegis, FreeOTP+, Google Authenticator,
andOTP, Bitwarden), and integrates with GNOME Shell search.

%prep
%autosetup -n Authenticator-%{version}
# Set up vendored Cargo dependencies
%if 0%{?Source1:1}
tar xf %{SOURCE1}
mkdir -p .cargo
cat > .cargo/config.toml << 'EOF'
[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "vendor"
EOF
%endif

%build
%meson -Dprofile=default
%meson_build

%install
%meson_install
%find_lang %{name}

%check
desktop-file-validate %{buildroot}%{_datadir}/applications/%{app_id}.desktop

%files -f %{name}.lang
%license LICENSE
%doc README.md
%{_bindir}/authenticator
%{_datadir}/applications/%{app_id}.desktop
%{_datadir}/metainfo/%{app_id}.metainfo.xml
%{_datadir}/glib-2.0/schemas/%{app_id}.gschema.xml
%{_datadir}/icons/hicolor/scalable/apps/%{app_id}.svg
%{_datadir}/icons/hicolor/symbolic/apps/%{app_id}-symbolic.svg
%{_datadir}/dbus-1/services/%{app_id}.service
%{_datadir}/dbus-1/services/%{app_id}.SearchProvider.service
%{_datadir}/gnome-shell/search-providers/%{app_id}.search-provider.ini
%{_datadir}/authenticator/

%post
%if 0%{?fedora} || 0%{?rhel} >= 9
/usr/bin/glib-compile-schemas %{_datadir}/glib-2.0/schemas &>/dev/null || :
/usr/bin/gtk4-update-icon-cache %{_datadir}/icons/hicolor &>/dev/null || :
/usr/bin/update-desktop-database %{_datadir}/applications &>/dev/null || :
%endif

%postun
%if 0%{?fedora} || 0%{?rhel} >= 9
/usr/bin/glib-compile-schemas %{_datadir}/glib-2.0/schemas &>/dev/null || :
/usr/bin/gtk4-update-icon-cache %{_datadir}/icons/hicolor &>/dev/null || :
/usr/bin/update-desktop-database %{_datadir}/applications &>/dev/null || :
%endif

%changelog
* Sun Mar 29 2026 Authenticator Maintainers - 4.6.2-1
- Initial RPM package
