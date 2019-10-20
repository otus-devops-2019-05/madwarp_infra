#!/bin/bash
cat <<EOF> /etc/systemd/system/reddit.service
[Unit]
Description=Reddit Service
After=network.target
[Service]
WorkingDirectory=/home/user/reddit
ExecStart=/usr/local/bin/pumactl start
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable reddit.service

