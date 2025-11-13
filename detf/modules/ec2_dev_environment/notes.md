You **cannot** run the _entire_ `user_data` script as the `ubuntu` user for two key reasons:

1.  **Execution Context:** AWS always executes `user_data` scripts as the `root` user by default.
2.  **Permissions:** Many commands in your script (like `apt install`, `systemctl`, and modifying files in `/etc`) require root privileges.

The solution is to **keep the root-required commands as they are** and use a targeted command to switch to the `ubuntu` user **only for the user-level installations** (`pyenv`, `uv`, etc.).

Here is the structure for doing this safely and effectively:

## 🛠️ The Correct Structure for `user_data`

The pattern is: `sudo -H -u ubuntu bash -c 'YOUR USER-LEVEL COMMANDS HERE'`

I will generate the corrected `user_data` script, separating the root-level system setup from the user-level profile configuration.

http://googleusercontent.com/immersive_entry_chip/0

### Why this fixes the issues:

1.  **Pyenv/UV Availability:** By running the `curl | bash` commands inside the `sudo -H -u $TARGET_USER bash -c '...'` block, the installers see `ubuntu`'s home directory (`/home/ubuntu`) as their destination (`$HOME`), and the required paths are added correctly to the `ubuntu` user's `.bashrc`.
2.  **VS Code Lockout:** We have **removed the dangerous `newgrp docker`** command (which is known to cause shell instability) and isolated the group changes. If you still face a lockout, the issue is almost certainly within the scripts the pyenv/uv installers wrote to your `.bashrc`. You'll need to follow the previous step and wrap those initialization commands within an `if [[ $- == *i* ]]; then` block.
