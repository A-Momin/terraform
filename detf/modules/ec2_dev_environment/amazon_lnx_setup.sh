#!/bin/bash

# =========================================================================
# 1. SYSTEM-WIDE SETUP (MUST RUN AS ROOT)
# =========================================================================

# --- Install Dependencies for Python tools (pyenv/uv) ---
# Note: Amazon Linux 2023 uses dnf, not apt
dnf update -y
dnf groupinstall -y "Development Tools" # equivalent of build-essential
dnf install -y openssl-devel zlib-devel bzip2 bzip2-devel \
  readline-devel sqlite sqlite-devel wget curl llvm \
  ncurses-devel xz-devel tk-devel libxml2-devel libffi-devel

# --- Install essential base tools ---
dnf install -y git vim

# --- Docker Installation (Root) ---
# Docker setup is simpler on AL2023
dnf install -y docker
systemctl start docker
systemctl enable docker

# --- Jenkins Installation (Root) ---
# AL2023 package names are different; installing Java and Jenkins dependencies
dnf install -y java-17-amazon-corretto wget
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf install -y jenkins

# Start and enable Jenkins service
systemctl daemon-reload
systemctl start jenkins
systemctl enable jenkins

TARGET_USER="ec2-user"
# Add the 'ec2-user' to the 'docker' group while running as root
usermod -aG docker ${TARGET_USER}

# =========================================================================
# 2. USER-LEVEL SETUP (SWITCH TO EC2-USER)
# =========================================================================


# Execute all user-level setup commands as the 'ec2-user'
sudo -H -u $TARGET_USER bash -c "
  set -e
  curl https://pyenv.run | bash

  echo 'export PYENV_ROOT=\"\$HOME/.pyenv\"' >> ~/.bashrc
  echo 'command -v pyenv >/dev/null || export PATH=\"\$PYENV_ROOT/bin:\$PATH\"' >> ~/.bashrc
  echo 'eval \"\$(pyenv init -)\"' >> ~/.bashrc

  curl -LsSf https://astral.sh/uv/install.sh | sh
  echo 'export PATH=\"\$HOME/.cargo/bin:\$PATH\"' >> ~/.bashrc
  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc
  echo 'export UV=\"\$HOME/.local/share/uv\"' >> ~/.bashrc
"