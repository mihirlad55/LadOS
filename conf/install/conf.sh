#!/usr/bin/bash

echo "Sourcing conf.sh"
### Global ###
# Set to yes to skip script pauses
CONF_NOCONFIRM=no

### Wifi ###
# Set to yes to use WiFi for installation
CONF_USE_WIFI=yes
# Set to name of network card (i.e. wlan0)
CONF_WIFI_ADAPTER=""

### Ranking Mirrorlist ###
# Set to your country code to rank mirrors
CONF_COUNTRY_CODE="US"

### Timezone ###
# Set to path to timezone region including /usr/share/zoneinfo
CONF_TIMEZONE_PATH="/usr/share/zoneinfo/America/New_York"

### Locale ###
# Set to locale from /etc/locale.gen. Locales are the first column
CONF_LOCALE="en_US.UTF-8"

### Hostname ###
# Set to hostname of computer
CONF_HOSTNAME=""

### Hosts ###
# Set to yes to edit hosts file during installation
CONF_EDIT_HOSTS=no

### Root Password ###
# Set to root password for computer
CONF_ROOT_PASSWORD=''

### Default User ###
# Set to your desired username
CONF_USERNAME=""
# Set to your desired password
CONF_PASSWORD=''

### Packages ###
# Set to no to not install packages marked as extra
CONF_INSTALL_EXTRA=yes

### Extra Features ###
# Set to array of names of extra features to not install. Use exact folder
# names from the extra-features directory.
CONF_EXCLUDE_FEATURES=( "corsair-headset" \
                            "gogh" \
                            "huion" \
                            "hp-printer" \
                            "setup-gpu-passthrough")
