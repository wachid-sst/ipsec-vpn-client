#!/bin/sh
#
# Docker script to configure and start an IPsec VPN server
#
# DO NOT RUN THIS SCRIPT ON YOUR PC OR MAC! THIS IS ONLY MEANT TO BE RUN
# IN A DOCKER CONTAINER!
#
# This file is part of IPsec VPN Docker image, available at:
# https://github.com/hwdsl2/docker-ipsec-vpn-server
#
# Copyright (C) 2016-2017 Lin Song <linsongui@gmail.com>
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
# of this server in your 'env' file, as variable 'VPN_PUBLIC_IP'.
VPN_SERVER_PUBLIC_IP=${VPN_PUBLIC_IP:-''}
VPN_LOCAL_IP=${VPN_LOCAL_IP:-''}

L2TP_NET=${VPN_L2TP_NET:-'192.168.42.0/24'}
L2TP_LOCAL=${VPN_L2TP_LOCAL:-'192.168.42.1'}
L2TP_POOL=${VPN_L2TP_POOL:-'192.168.42.10-192.168.42.250'}
XAUTH_NET=${VPN_XAUTH_NET:-'192.168.43.0/24'}
XAUTH_POOL=${VPN_XAUTH_POOL:-'192.168.43.10-192.168.43.250'}
DNS_SRV1=${VPN_DNS_SRV1:-'8.8.8.8'}
DNS_SRV2=${VPN_DNS_SRV2:-'8.8.4.4'}

# Create Stronswan config
cat > /etc/ipsec.conf <<EOF
# ipsec.conf - strongSwan IPsec configuration file

conn myvpn
  auto=add
  keyexchange=ikev1
  authby=secret
  type=transport
  left=%defaultroute
  leftprotoport=17/1701
  rightprotoport=17/1701
  right=$VPN_SERVER_PUBLIC_IP
  ike=aes128-sha1-modp2048
  esp=aes128-sha1
EOF

cat > /etc/ipsec.secrets <<EOF
: PSK "$VPN_IPSEC_PSK"
EOF

chmod 600 /etc/ipsec.secrets

# Create xl2tpd config
cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[lac myvpn]
lns = $VPN_SERVER_PUBLIC_IP
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
EOF

# Set xl2tpd options
cat > /etc/ppp/options.l2tpd.client <<EOF
ipcp-accept-local
ipcp-accept-remote
refuse-eap
require-chap
noccp
noauth
mtu 1280
mru 1280
noipdefault
nodefaultroute
usepeerdns
connect-delay 5000
name "$VPN_USER"
password "$VPN_PASSWORD"
EOF

chmod 600 /etc/ppp/options.l2tpd.client

#Create xl2tpd control file:
mkdir -p /var/run/xl2tpd
touch /var/run/xl2tpd/l2tp-control

## service rsyslog restart

Rsys=/run/rsyslogd.pid
if test -f "$Rsys"; then
    echo "Rsyslog pid exists."
    rm /run/rsyslogd.pid && /usr/sbin/rsyslogd
else
    /usr/sbin/rsyslogd
fi

Prn=/var/run/pernah-nyala.pid
if test -f "$Prn"; then
    echo "Container pernah nyala"
else
    echo "Menghapus myvpn dan mematikan service"
    ipsec down myvpn && ipsec status
    service ipsec stop && service xl2tpd stop && sleep 2
fi

#Start services:
service ipsec start && service xl2tpd start && sleep 2

#Start the IPsec connection:
ipsec up myvpn && ipsec status

#Start the L2TP connection:
echo 'Menjalankan koneksi L2TP ...'
echo "c myvpn" > /var/run/xl2tpd/l2tp-control && timeout -k 2s 10s sleep 10s

#Setup routes
GW="$(ip route | grep default | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")"

echo 'gateway yg terdeteksi : '$GW

# Mengecek apakah antarmuka ppp0 ada
if ip link show ppp0 &> /dev/null; then
    echo "Antarmuka ppp0 ada"
    echo 'menambahkan '$VPN_LOCAL_IP' IP ke routing...'
    ip route add $VPN_LOCAL_IP dev ppp0 && sleep 2
  # Jalankan tindakan di sini jika ppp0 ada
    # Misalnya:
    # command1
    # command2
else
    echo "Antarmuka ppp0 tidak ada"
    # Tindakan jika ppp0 tidak ada bisa ditambahkan di sini jika diperlukan

    touch /var/run/xl2tpd/l2tp-control

    echo "Merestart koneksi ipsec"

    #Restart services:
    service ipsec restart && service xl2tpd restart && sleep 2

    #Start the IPsec connection:
    ipsec up myvpn && ipsec status

    #Start the L2TP connection:
    echo 'Menjalankan koneksi L2TP kembali ...'
    echo "c myvpn" > /var/run/xl2tpd/l2tp-control && timeout -k 2s 10s sleep 10s

fi

#route add $LOCAL_IP gw $GW
#route add $PUBLIC_IP gw $GW
#Wait necessary time for ppp0 to be created
# sleep 10
#route add default dev ppp0

#Add statically dns from ppp due to docker issue
#TODO Need to find a better way to make it work
# cat /etc/ppp/resolv.conf > /etc/resolv.conf

Rslv=/etc/ppp/resolv.conf
if test -f "$Rslv"; then
    echo "File $Rslv exists."
    cat /etc/ppp/resolv.conf > /etc/resolv.conf
fi

echo 'Koneksi L2TP berhasil ...'
echo 'Berjalan di background ...'
touch /var/run/pernah-nyala.pid
sleep 7d

echo 'Refresh Koneksi L2TP ...'
