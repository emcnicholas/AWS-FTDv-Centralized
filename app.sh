#!/bin/bash

# Check if the required number of arguments (at least 1) is provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <host_ip>"
    exit 1
fi

# Define variables
HOST="$1"
USER="ec2-user"
KEY_PATH="/home/ec2-user/GLIC-private-key.pem"
REPO_URL="https://github.com/emcnicholas/web-traffic-generator.git"
TARGET_DIR="web-traffic-generator"
ENV_NAME="myenv"

# SSH command with "yes" answer for all prompts, yum update, yum install git, git clone, create/activate Python virtual environment, install requirements, and run gen.py
yes | ssh -o StrictHostKeyChecking=no -i "$KEY_PATH" "$USER@$HOST" << EOF
  yes | sudo yum update
  yes | sudo yum install git
  git clone "$REPO_URL" "$TARGET_DIR"
  cd "$TARGET_DIR"
  python3 -m venv "$ENV_NAME"
  source "$ENV_NAME/bin/activate"
  pip3 install -r requirements.txt
  python3 gen.py
EOF
