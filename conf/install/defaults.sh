#!/usr/bin/bash

echo "Sourcing defaults.sh"
### Global ###
# Set to yes to skip script pauses
DEFAULTS_NOCONFIRM=no

### Wifi ###
# Set to yes to use WiFi for installation
DEFAULTS_USE_WIFI=yes
# Set to name of network card (i.e. wlan0)
DEFAULTS_WIFI_ADAPTER=""

### Ranking Mirrorlist ###
# Set to your country code to rank mirrors
DEFAULTS_COUNTRY_CODE="US"

### Timezone ###
# Set to path to timezone region including /usr/share/zoneinfo
DEFAULTS_TIMEZONE_PATH="/usr/share/zoneinfo/America/New_York"

### Locale ###
# Set to locale from /etc/locale.gen. Locales are the first column
DEFAULTS_LOCALE="en_US.UTF-8"

### Hostname ###
# Set to hostname of computer
DEFAULTS_HOSTNAME=""

### Hosts ###
# Set to yes to edit hosts file during installation
DEFAULTS_EDIT_HOSTS=no

### Root Password ###
# Set to root password for computer
DEFAULTS_ROOT_PASSWORD=''

### Default User ###
# Set to your desired username
DEFAULTS_USERNAME=""
# Set to your desired password
DEFAULTS_PASSWORD=''

### Packages ###
# Set to no to not install packages marked as extra
DEFAULTS_INSTALL_EXTRA=yes

### Extra Features ###
# Set to array of names of extra features to not install. Use exact folder
# names from the extra-features directory.
DEFAULTS_EXCLUDE_FEATURES=( "corsair-headset" \
                            "gogh" \
                            "huion" \
                            "printer" \
                            "setup-gpu-passthrough")
