# LadOS

## Overview
This repo contains setup/install scripts to install a heavily-riced version of
Arch Linux.

This repo contains two types of features: **required** and **optional**.
Required features are those that are either required to have a functional system
or those that I consider vital to defining what LadOS is. Optional features are
extra features that either improve the system in some additional way or fix a
system-specific issue.


### Required Features
- **dracut**: A replacement for mkinitcpio. It's included for its simplicity and
support for unified kernel images.
- **sudoers:** Sudo with additional configuration added
- **enable-community-repo**: Enable pacman community repo
- **yay**: AUR helper
- **rEFInd-minimal-black**: rEFInd bootloader with minimal-black theme applied.
The main **bootloade**r for the system.
- **dwm**: A window manager. My patched version of dwm.
- **st**: A terminal emulator. My patched version of st.
- **crontab**: Cronie with additional configuration added
- **dotfiles**: My dotfiles and configuration files


### Optional Features
- **auto-mirror-rank**: Auto-ranks pacman mirrors every boot
- **configure-backlight**: intel\_backlight X11 config file for controlling
display backlight
- **configure-touchpad**: Touchpad configuration for X11 which enables tapping,
natural scrolling, and an lrm button map.
- **corsair-headset**: Corsair headset X11 config file to fix buggy behavior
(https://www.c0urier.net/2016/corsair-gaming-void-usb-rgb-linux-fun)
- **doom-emacs**: Installs doom emacs
- **gcp-tunnel**: Sets up remote port forwarding using SSH with a Google Cloud
Platform Compute instance which enables SSH over the Internet through the
GCP instance no matter what network the computer is connected to.
- **gogh**: Installs a gogh theme on gnome-terminal (Not fully implemented)
- **gtk-greeter**: Installs lightdm-gtk-greeter with the maia-gtk-theme and
custom configuration
- **hp-printer**: Installs hplip, CUPS, and setups up an HP printer
- **huion**: Installs drivers and additional configuration for a huion graphics
tablet
- **luks-encryption-tpm**: Installs a dracut module to allow storing and
retreiving the encryption key of a LUKS root partition from the system's TPM
- **on-monitor-change**: Auto-outputs connected displays above the main display
and restarts polybar on connecting new displays
- **openvpn-expressvpn**: Setups up openvpn with ExpressVPN servers (requires
ExpressVPN account)
- **physlock**: Sets up a physlock service to prevent TTY switching
- **plymouth**: Installs plymouth with deus\_ex boot animation (credits to
[adi1090x](https://github.com/adi1090x))
- **power-desktop-options**: Installs desktop files that execute power options
such as poweroff, reboot, etc.
- **powertop**: Installs powertop and service
- **recovery-mode**: Installs a recovery partition
- **redshift**: Installs redshift with geoclue for location-based updates
- **restic-b2**: Installs services and scripts to auto-backup computer to B2
Cloud Storage using restic
- **secure-boot-custom**: Sets up secure boot with custom keys
- **secure-boot-preloader**: Sets up secure boot with Preloader
- **secure-boot-shim**: Sets up secure boot with Shim
- **setup-gpu-passthrough**: Sets up the computer to allow GPU passthrough (Not
fully implemented)
- **ssh-keys**: Installs existing user and root SSH keys into system
- **steam**: Installs steam and enables multilib repos
- **systemd-boot**: Installs the systemd-boot bootloader
- **user-services**: Installs a set of systemd services to autostart particular
applications such as compton, redshift, etc.
- **vifm**: Installs vifm with image previews using ueberzug
- **weather-polybar-module**: Installs existing OpenWeatherMap API key to use
with a custom weather module on polybar
- **webkit2-greeter**: Installs the lightdm-webkit2-greeter with user avatar and
backgrounds
- **win10-fonts**: Installs Windows 10 fonts (fonts must be acquired yourself)
- **wpa-supplicant**: Installs wpa\_supplicant with dhcpcd with existing network
configuration


## Pre-Install
Before you begin an install of LadOS, you can create some files that can reduce
manual input during the installation and futher manual installation later.
All such files should be placed accordingly in the `conf` directory. For more
details, see the [wiki](https://github.com/mihirlad55/LadOS/wiki).


# Install
To install LadOS, go to the
[install](https://github.com/mihirlad55/LadOS/Install)
page on the wiki.
