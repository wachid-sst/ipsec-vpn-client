#!/bin/bash

#export "$(grep -vE "^(#.*|\s*)$" .env)"

if [ "$0" = "$BASH_SOURCE" ]; then
    echo "Skrip ini dijalankan menggunakan Bash"
else
    echo "Mohon jalankan script ini dengan shell bash"
    echo "Error, berhenti menjalankan script $1" >&2; exit 1
fi

env_file=".env"
workingdir=$(pwd)

if [ -f "$workingdir/$env_file" ]; then
    echo "Loading variables from $env_file..."
    source $workingdir/$env_file
    echo "Variables loaded."
else
    echo "Error: $env_file not found."
fi

exiterr()  { echo "Error: $1" >&2; exit 1; }
nospaces() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }
noquotes() { printf '%s' "$1" | sed -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'$/\1/"; }

check_ip() {
  IP_REGEX='^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'
  printf '%s' "$1" | tr -d '\n' | grep -Eq "$IP_REGEX"
}


if [ -f "/.dockerenv" ]; then
    echo "Running inside a container."
else
    echo "Not running inside a container."
fi

#!/bin/bash

# Mendapatkan informasi sistem operasi
os=$(lsb_release -si)

# Memeriksa distribusi dan memeriksa serta menginstal paket-paket jika belum terinstal
if [ "$os" = "Ubuntu" ] || [ "$os" = "Debian" ]; then
    # Mengecek dan menginstal xl2tpd
    if ! dpkg -l | grep -q "^ii\s*xl2tpd\s"; then
        echo "Package 'xl2tpd' is not installed. Installing..."
        sudo apt update
        sudo apt install -y xl2tpd

        if [ $? -eq 0 ]; then
            echo "Package 'xl2tpd' has been successfully installed."
        else
            echo "Failed to install 'xl2tpd'. Please check for errors."
        fi
    else
        echo "Package 'xl2tpd' is already installed."
    fi

    # Mengecek dan menginstal strongswan
    if ! dpkg -l | grep -q "^ii\s*strongswan\s"; then
        echo "Package 'strongswan' is not installed. Installing..."
        sudo apt update
        sudo apt install -y strongswan

        if [ $? -eq 0 ]; then
            echo "Package 'strongswan' has been successfully installed."
        else
            echo "Failed to install 'strongswan'. Please check for errors."
        fi
    else
        echo "Package 'strongswan' is already installed."
    fi

    # Mengecek dan menginstal rsyslog
    if ! dpkg -l | grep -q "^ii\s*rsyslog\s"; then
        echo "Package 'rsyslog' is not installed. Installing..."
        sudo apt update
        sudo apt install -y rsyslog

        if [ $? -eq 0 ]; then
            echo "Package 'rsyslog' has been successfully installed."
        else
            echo "Failed to install 'rsyslog'. Please check for errors."
        fi
    else
        echo "Package 'rsyslog' is already installed."
    fi

else
    echo "This script is intended for Debian or Ubuntu. Detected OS: $os. Exiting."
    exit 1
fi


# Remove whitespace and quotes around VPN variables, if any
VPN_IPSEC_PSK="$(nospaces "$VPN_IPSEC_PSK")"
VPN_IPSEC_PSK="$(noquotes "$VPN_IPSEC_PSK")"
VPN_USER="$(nospaces "$VPN_USER")"
VPN_USER="$(noquotes "$VPN_USER")"
VPN_PASSWORD="$(nospaces "$VPN_PASSWORD")"
VPN_PASSWORD="$(noquotes "$VPN_PASSWORD")"


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
  right=$VPN_SERVER_IP
  ike=aes128-sha1-modp2048
  esp=aes128-sha1
EOF

cat > /etc/ipsec.secrets <<EOF
: PSK "$VPN_IPSEC_PSK"
EOF

chmod 600 /etc/ipsec.secrets

cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[lac myvpn]
lns = $VPN_SERVER_IP
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
EOF

if [ -d /etc/ppp ]; then
  echo "Directory /etc/ppp exists."
else
  echo "Directory does not exist."
  mkdir -p /etc/ppp
  echo "create directory /etc/ppp"
fi


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
defaultroute
usepeerdns
connect-delay 5000
name "$VPN_USER"
password "$VPN_PASSWORD"
EOF

chmod 600 /etc/ppp/options.l2tpd.client

if [ -d /var/run/xl2tpd ]; then
  echo "Directory /var/run/xl2tpd exists."
else
  echo "Directory does not exist."
  mkdir -p /var/run/xl2tpd
  echo "create directory /var/run/xl2tpd"
fi

touch /var/run/xl2tpd/l2tp-control

# Check if lsb_release command exists
if command -v lsb_release > /dev/null 2>&1; then
    # Get distribution name
    distro=$(lsb_release -si)

    # Check for Ubuntu
    if [ "$distro" = "Ubuntu" ]; then
        echo "This is Ubuntu."

    # For Ubuntu 20.04, if strongswan service not found
    ipsec restart

    service xl2tpd restart

    #Start the IPsec connection:

    # Ubuntu and Debian
    ipsec up myvpn

    #Start the L2TP connection:

    echo "c myvpn" > /var/run/xl2tpd/l2tp-control


    # Check for Debian
    elif [ "$distro" = "Debian" ]; then
        echo "This is Debian."

    # For Ubuntu 20.04, if strongswan service not found
    ipsec restart

    service xl2tpd restart

    # Ubuntu and Debian
    ipsec up myvpn

    #Start the L2TP connection:

    echo "c myvpn" > /var/run/xl2tpd/l2tp-control

    # Check for CentOS
    elif [ "$distro" = "CentOS" ]; then
        echo "This is CentOS."

    # CentOS and Fedora
    service strongswan restart
    service xl2tpd restart

    # CentOS and Fedora
    strongswan up myvpn

    #Start the L2TP connection:

    echo "c myvpn" > /var/run/xl2tpd/l2tp-control

    # If none of the above
    else
        echo "This distribution is not Ubuntu, Debian, or CentOS."
    fi

# If lsb_release command is not available
else
    echo "lsb_release command not found. Unable to determine the distribution."
fi

#Start the IPsec connection:

# Ubuntu and Debian
## ipsec up myvpn

#Start the L2TP connection:

## echo "c myvpn" > /var/run/xl2tpd/l2tp-control
