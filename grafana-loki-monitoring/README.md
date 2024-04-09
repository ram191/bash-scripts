# Grafana Loki Monitoring

This script installs Loki and Promtail for Grafana monitoring by downloading the source binary for Loki and Promtail and adding the process to systemd. Port 3100 will be allowed and the configuration files are saved in `/etc/loki/config.yml` and `/etc/promtail/config.yml`. Change the Loki and Promtail source download by changing the `LOKI_URL` and `PROMTAIL_URL` variable

Running the script: `sudo ./script.sh`
