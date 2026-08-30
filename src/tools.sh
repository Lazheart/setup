# Java
sudo apt install openjdk-21-jdk -y

# Docker
sudo apt install docker.io docker-compose -y
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker

# Qt 5
sudo apt install qtcreator qtbase5-dev qt5-qmake cmake

# Pnpm

curl -fsSL https://get.pnpm.io/install.sh | sh -

