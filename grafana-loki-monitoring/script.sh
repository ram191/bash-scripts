#!/bin/bash
function loading_icon() {
    local load_interval="${1}"
    local loading_message="${2}"
    local elapsed=0
    local loading_animation=( '—' "\\" '|' '/' )

    printf "${loading_message} "

    # This part is to make the cursor not blink
    # on top of the animation while it lasts
    tput civis
    trap "tput cnorm" EXIT
    while [ "${load_interval}" -ne "${elapsed}" ]; do
        for frame in "${loading_animation[@]}" ; do
            printf "%s\b" "${frame}"
            sleep 0.25
        done
        elapsed=$(( elapsed + 1 ))
    done
    printf " \b\n"
}

function install() {
  LOKI_URL="https://github.com/grafana/loki/releases/download/v2.8.11/loki-linux-amd64.zip"
  PROMTAIL_URL="https://github.com/grafana/loki/releases/download/v2.8.11/promtail-linux-amd64.zip"

  cd ~/downloads && wget ${LOKI_URL} -O loki.zip
  unzip loki.zip
  mv loki-linux-amd64 /usr/local/bin/loki

  cd ~/downloads && wget ${PROMTAIL_URL} -O promtail.zip
  unzip promtail.zip
  mv promtail-linux-amd64 /usr/local/bin/promtail

  mkdir /etc/loki
  mkdir /etc/promtail

  echo "install finished"
}

function add_systemd() {
  cat <<EOF > /etc/systemd/system/loki.service
[Unit]
Description=Loki service
After=network.target

[Service]
Type=simple
User=loki
ExecStart=/usr/bin/loki -config.file /etc/loki/config.yml
# Give a reasonable amount of time for the server to start up/shut down
TimeoutSec = 120
Restart = on-failure
RestartSec = 2

[Install]
WantedBy=multi-user.target
EOF

  cat <<EOF > /etc/systemd/system/promtai.service
[Unit]
Description=Promtail service
After=network.target

[Service]
Type=simple
User=promtail
ExecStart=/usr/bin/promtail -config.file /etc/promtail/config.yml
# Give a reasonable amount of time for promtail to start up/shut down
TimeoutSec = 60
Restart = on-failure
RestartSec = 2

[Install]
WantedBy=multi-user.target
EOF
}

# Start the spinner in the background
loading_icon 2 "Updating apt..."
apt-get update -y > /dev/null

# Install Loki and Promtail
loading_icon 2 "Installing Loki and Promtail..."
install
add_systemd

# Copy the configuration files
if [ -f /etc/loki/config.yml ]; then
    printf "\nLoki configuration file already exists. Would you like to overwrite it?\n"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) cp ./loki-config.yml /etc/loki/config.yaml; break;;
            No ) break;;
        esac
    done
else
    cp ./loki-config.yml /etc/loki/config.yaml
fi

if [ -f /etc/promtail/config.yml ]; then
    printf "\nPromtail configuration file already exists. Would you like to overwrite it?\n"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) cp ./promtail-config.yml /etc/promtail/config.yml; break;;
            No ) break;;
        esac
    done
else
  cp ./promtail-config.yml /etc/promtail/config.yml
fi

# Export the Loki port
loading_icon 2 "Exposing Loki port"
sudo iptables -A INPUT -p tcp --dport 3100 -j ACCEPT

printf "\n\nInstallation complete!\n"
cat << "EOF"
To start Loki, run the following command:
sudo systemctl start loki

Loki is now running on port 3100.
EOF
