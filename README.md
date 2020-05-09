# LadOS

This repo contains setup/install scripts to install a heavily-riced version of
Arch Linux.

# Pre-Install

Before you begin an install of LadOS, you can create some files that can reduce
manual input during the installation and futher manual installation later.
All such files should be placed accordingly in the `conf` directory.

## For Main Installation

You can edit `conf/install/defaults.sh` to configure some default installation
settings such as the default locale, timezone, etc. to avoid having to specify
this during the installation.

The `conf/install/hosts` file can be edited to include additional entries for
the /etc/hosts file. The default entries included by the installation process
are:
```
localhost   127.0.0.1
::1         127.0.0.1
```

The `conf/install/network.conf` file can be edited to include a wpa\_supplicant
formatted configuration to be used during the installation process.
For example,
```
network={
    ssid="Example WiFi"
    psk="Example Password"
}
```
can be used to connect to `Example WiFi` with `Example Password` during the
installation process.


## openvpn-expressvpn Feature
In the `/conf/openvpn-expressvpn/client` folder, the unmodified .ovpn
configuration files from ExpressVPN can be copied.
In addition, a `login.conf` file with the following credential format can be
created:
```
<username>
<password>
```


## weather-polybar-module Feature
In the `/conf/weather-polybar-module` folder, a `openweathermap.key` file can
be created containing an OpenWeatherMap key which can be obtained from
https://home.openweathermap.org/api\_keys.
This is used to retreive weather information for polybar.


## webkit2 Feature
In the `/conf/webkit2` folder, a picture named `user.png` can be created to be
used as your account avatar which will be displayed on
`lightdm-webkit2-greeter`.
In addition, background images for the login screen can put in
`/conf/webkit2/backgrounds/`.


## win10-fonts Feature
In the `/conf/win10-fonts` folder, the windows 10 fonts can be copied to be
installed by the win10-fonts feature.



# Install

To install LadOS, follow the below steps:

1. Download the Arch Linux image from https://www.archlinux.org/download/ and
use the following command to copy it to a USB.
Warning: this will wipe all data on the USB:
`dd bs=4M if=path/to/archlinux.iso of=/dev/sdx status=progress oflag=sync`

2. Boot into the archiso on your computer.

3. Download and unzip the repo using the following commands:
```
curl -L https://github.com/mihirlad55/LadOS/archive/master.zip \
    --output LadOS.zip
unzip LadOS.zip
```

4. Copy over any pre-installation files from another USB/storage medium or by
downloading them.

5. Run the installer by running setup.sh and then selecting
`Install Arch Linux`.
```
% ./setup.sh
-----Main Menu-----
1. Install Arch Linux
2. Install Required Features
3. Install Extra Features
4. Fixes
5. Scripts
6. Exit
Option: 1

```

6. Follow any on-screen prompts and wait for the installation to complete.
