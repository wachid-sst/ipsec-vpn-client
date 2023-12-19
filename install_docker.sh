#!/bin/bash

DEBIAN_FRONTEND=noninteractive
# update repo
apt update -y && apt upgrade -y
# install depedensi
sudo apt-get install ca-certificates curl gnupg
# Mendownload gpg key docker:
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
#Menambahkan repository kedalam system operasi
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Melakukan update package:
apt update
# Melakukan instalasi package docker
apt install install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
# Check informasi versi docker
docker --version
# Check informasi status service docker
systemctl status docker
Untuk menjalankan service docker, jalankan perintah berikut
systemctl start docker
# Mensetting aplikasi docker berjalan di start up
systemctl enable docker
