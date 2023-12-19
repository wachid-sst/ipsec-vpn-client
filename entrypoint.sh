#!/bin/sh
#
# Docker script to configure and start an IPsec VPN server
#
# DO NOT RUN THIS SCRIPT ON YOUR PC OR MAC! THIS IS ONLY MEANT TO BE RUN
# IN A DOCKER CONTAINER!
# 
# vpn client base on nmcli
# Based on the work of (C) 2016-2017 Lin Song <linsongui@gmail.com>
# Based on the work of Thomas Sarlandie (Copyright 2012)
#
# This work is licensed under the Creative Commons Attribution-ShareAlike 3.0
# Unported License: http://creativecommons.org/licenses/by-sa/3.0/
#
# Attribution required: please include my name in any derivative and let me
# know how you have improved it!

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

exiterr()  { echo "Error: $1" >&2; exit 1; }
nospaces() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }
noquotes() { printf '%s' "$1" | sed -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/"; }

check_ip() {
  IP_REGEX='^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'
  printf '%s' "$1" | tr -d '\n' | grep -Eq "$IP_REGEX"
}

if [ ! -f "/.dockerenv" ]; then
  exiterr "This script ONLY runs in a Docker container."
fi

# Mengecek status privileged mode dari dalam kontainer
if ip link add dummy0 type dummy 2>&1 | grep -q "not permitted"; then
    echo "Kontainer tidak berjalan dalam mode privileged."
    echo "Kontainer harus di jalankan dalam mode privileged"
else
    echo "Kontainer berjalan dalam mode privileged."
   ip link delete dummy0 >/dev/null 2>&1
fi

#mkdir -p /opt/src
#vpn_env="/opt/src/vpn-gen.env"

#$VPN_IPSEC_PSK="$(cat $vpn_env  | grep VPN_IPSEC_PSK | cut -d'=' -f2)"
#$VPN_USER="$(cat $vpn_env  | grep VPN_USER | cut -d'=' -f2)"
#$VPN_PASSWORD="$(cat $vpn_env  | grep VPN_PASSWORD | cut -d'=' -f2)"

# Remove whitespace and quotes around VPN variables, if any
VPN_IPSEC_PSK="$(nospaces "$VPN_IPSEC_PSK")"
VPN_IPSEC_PSK="$(noquotes "$VPN_IPSEC_PSK")"
VPN_USER="$(nospaces "$VPN_USER")"
VPN_USER="$(noquotes "$VPN_USER")"
VPN_PASSWORD="$(nospaces "$VPN_PASSWORD")"
VPN_PASSWORD="$(noquotes "$VPN_PASSWORD")"

if [ -z "$VPN_IPSEC_PSK" ] || [ -z "$VPN_USER" ] || [ -z "$VPN_PASSWORD" ]; then
  exiterr "All VPN credentials must be specified. Edit your 'env' file and re-enter them."
fi

if printf '%s' "$VPN_IPSEC_PSK $VPN_USER $VPN_PASSWORD" | LC_ALL=C grep -q '[^ -~]\+'; then
  exiterr "VPN credentials must not contain non-ASCII characters."
fi

case "$VPN_IPSEC_PSK $VPN_USER $VPN_PASSWORD" in
  *[\\\"\']*)
    exiterr "VPN credentials must not contain these special characters: \\ \" '"
    ;;
esac

echo
echo 'Trying to auto discover IP of this server...'

# In case auto IP discovery fails, manually define the public IP
# of this server in your 'env' file, as variable 'VPN_SERVER_PUBLIC_IP'.
VPN_SERVER_PUBLIC_IP=${VPN_PUBLIC_IP:-''}
VPN_SERVER_IPV4_ROUTES=${VPN_SERVER_IPV4_ROUTES:-''}

VPN_SERVER_LOCAL_SEGMENT=${VPN_LOCAL_SEGMENT:-''}
VPN_SERVER_INTERNAL_SEGMENT=${VPN_INTERNAL_SEGMENT:-''}

L2TP_NET=${VPN_L2TP_NET:-'192.168.42.0/24'}
L2TP_LOCAL=${VPN_L2TP_LOCAL:-'192.168.42.1'}
L2TP_POOL=${VPN_L2TP_POOL:-'192.168.42.10-192.168.42.250'}
XAUTH_NET=${VPN_XAUTH_NET:-'192.168.43.0/24'}
XAUTH_POOL=${VPN_XAUTH_POOL:-'192.168.43.10-192.168.43.250'}
DNS_SRV1=${VPN_DNS_SRV1:-'8.8.8.8'}
DNS_SRV2=${VPN_DNS_SRV2:-'8.8.4.4'}

echo 'Membuat koneksi L2TP ...'

nmcli connection add connection.id vpn-mikro con-name vpn-mikro type VPN vpn-type l2tp ifname -- connection.autoconnect yes ipv4.method auto ipv4.routes "$VPN_SERVER_IPV4_ROUTES"  vpn.data "gateway = $VPN_SERVER_PUBLIC_IP, ipsec-enabled = yes, mru = 1400, mtu = 1400, password-flags = 0, refuse-chap = yes, refuse-mschap = yes, re
fuse-pap = yes, require-mppe= yes, user = dnsdev" vpn.secrets "$VPN_PASSWORD, ipsec-psk = $VPN_IPSEC_PSK" ipv6.method disable

echo 'Berhasil membuat sambungan L2TP ...'

# Replace 'YourConnectionName' with the name of the connection you want to check
connection_name="vpn-mikro"

# Check if the connection is up
if nmcli connection show --active | grep -q "$connection_name"; then
    echo "$connection_name is up."
else
    echo "$connection_name is not up."
    echo "starting $connection_name"
    nmcli conn up vpn-mikro
fi

echo 'Sambungan vpn berhasil, berjalan di background ...'

exec /bin/bash $@

echo 'Refresh Koneksi L2TP ...'
