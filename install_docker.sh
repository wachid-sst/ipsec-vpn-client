#!/bin/bash

DEBIAN_FRONTEND=noninteractive
# update repo
sudo apt update -y && sudo apt upgrade -y
# install depedensi
sudo apt-get install ca-certificates curl gnupg
# Mendownload gpg key docker:
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
#Menambahkan repository kedalam system operasi
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Melakukan update package:
sudo apt update && apt upgrade
# Melakukan instalasi package docker
sudo apt install install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Check informasi versi docker
sudo docker --version
# Check informasi status service docker
sudo systemctl status docker
Untuk menjalankan service docker, jalankan perintah berikut
sudo systemctl start docker
# Mensetting aplikasi docker berjalan di start up
sudo systemctl enable docker
