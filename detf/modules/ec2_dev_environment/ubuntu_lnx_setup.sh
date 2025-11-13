#!/bin/bash

# =========================================================================
# 1. SYSTEM-WIDE SETUP (MUST RUN AS ROOT)
#    - Installing packages, setting up services (Docker, Jenkins, Git, Vim)
# =========================================================================

# --- Dependencies for Python tools (pyenv/uv) ---
sudo apt update -y
sudo apt install -y build-essential libssl-dev zlib1g-dev libbz2-dev \
libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils \
tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# --- Install essential base tools ---
sudo apt install git vim -y

# --- Docker Installation (Root) ---
sudo apt-get update -y
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo apt install docker-compose -y

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# --- Jenkins Installation (Root) ---
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
/etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins -y
sudo systemctl daemon-reload
sudo systemctl start jenkins
sudo systemctl enable jenkins

# --- Java Installation (Root) ---
sudo apt install openjdk-17-jre -y

# =========================================================================
# 2. USER-LEVEL SETUP (SWITCH TO UBUNTU USER)
#    - Installing pyenv, uv, and configuring bash environment variables.
#    - We switch to 'ubuntu' user for these commands.
# =========================================================================

# The target user is 'ubuntu' on AWS/EC2 Ubuntu AMIs
TARGET_USER="ubuntu" 

# Execute all user-level setup commands as the 'ubuntu' user
sudo -H -u $TARGET_USER bash -c '

    # Add the user to the docker group (must be done after system install)
    # Note: Changes to user groups (usermod) require a *new* login session to take effect.
    sudo usermod -aG docker '$TARGET_USER'

    # --- Install pyenv ---
    curl https://pyenv.run | bash

    # Configure pyenv environment variables in .bashrc
    echo "export PYENV_ROOT=\"\$HOME/.pyenv\"" >> ~/.bashrc
    echo "command -v pyenv >/dev/null || export PATH=\"\$PYENV_ROOT/bin:\$PATH\"" >> ~/.bashrc
    echo "eval \"\$(pyenv init -)\"" >> ~/.bashrc
    echo "pyenv installation complete."


    # --- Install uv ---
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Configure uv environment variables in .bashrc
    echo "export PATH=\"\$HOME/.cargo/bin:\$PATH\"" >> ~/.bashrc
    echo "uv installation complete."
'

# =========================================================================
# 3. FINAL SYSTEM ACTIONS (MUST RUN AS ROOT)
# =========================================================================

# Restart the Docker service to ensure the group membership changes are processed system-wide
# (This still won't apply to the user until their next login, but it's good practice)
sudo systemctl restart docker

# Final check: Do NOT disable firewalls here, but ensure they are not accidentally enabled.
# If you found ufw was the issue, you must ensure it is disabled here:
# ufw disable

# ============================================================================
# END OF SCRIPT
# ============================================================================
