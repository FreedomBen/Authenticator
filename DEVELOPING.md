# Developing Authenticator

## Install dependencies

### Fedora

First install build dependencies:

If you want to build with flatpak:

```bash
sudo dnf install -y flatpak flatpak-builder ninja-build meson rpm-build

sudo dnf install -y gtk4-devel libadwaita-devel gstreamer1-devel gstreamer1-plugins-base-devel

# For building against stable SDK rather than master
flatpak install flathub org.gnome.Sdk//48 org.gnome.Platform//48
flatpak install flathub org.freedesktop.Sdk.Extension.rust-stable//24.08
flatpak install flathub org.freedesktop.Sdk.Extension.llvm20//24.08
```

If you want to build natively:

```bash
sudo dnf install -y gtk4-devel libadwaita-devel gstreamer1-devel gstreamer1-plugins-base-devel
```


## Building the flatpak locally

```bash
flatpak-builder --force-clean --repo=_flatpak_repo _flatpak build-aux/com.belmoussaoui.Authenticator.Devel.json

flatpak build-bundle _flatpak_repo Authenticator.flatpak com.belmoussaoui.Authenticator.Devel
```
