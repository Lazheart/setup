#!/bin/bash

# Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt --fix-broken install -y

# Steam
wget https://cdn.fastly.steamstatic.com/client/installer/steam.deb
sudo dpkg -i steam.deb
sudo apt --fix-broken install -y

# Heroic
wget https://github.com/Heroic-Games-Launcher/HeroicGamesLauncher/releases/download/v2.22.1/Heroic-2.22.1-linux-amd64.deb
sudo dpkg -i Heroic-2.22.1-linux-amd64.deb
sudo apt --fix-broken install -y

# Antigravity
wget https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.5.5-4923483625488384/linux-x64/Antigravity%20IDE.tar.gz

# Extract
tar -xf Antigravity\ IDE.tar.gz

# Move
sudo rm -rf /opt/antigravity
sudo mv Antigravity\ IDE /opt/antigravity

# Terminal command
sudo tee /usr/local/bin/antigravity > /dev/null <<'EOF'
#!/bin/bash
nohup /opt/antigravity/antigravity-ide "$@" >/dev/null 2>&1 &
disown
EOF
sudo chmod +x /usr/local/bin/antigravity

# Application menu
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/antigravity.desktop <<EOF
[Desktop Entry]
Name=Antigravity IDE
Exec=/opt/antigravity/antigravity-ide %F
Icon=/opt/antigravity/resources/app/resources/linux/code.png
Terminal=false
Type=Application
Categories=Development;IDE;
EOF

update-desktop-database ~/.local/share/applications 2>/dev/null || true

# AnyDesk
wget https://download.anydesk.com/linux/anydesk_8.0.4-1_amd64.deb
sudo dpkg -i anydesk_8.0.4-1_amd64.deb
sudo apt --fix-broken install -y
