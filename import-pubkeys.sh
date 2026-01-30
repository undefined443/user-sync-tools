#!/bin/bash
#
# paste-pubkey.sh - Deploy SSH public keys to user home directories
#
# DESCRIPTION:
#   This script reads public key files from the current directory and
#   deploys them to corresponding users' ~/.ssh/authorized_keys.
#   The filename must match the username (e.g., file "john" -> /home/john/.ssh/).
#
# USAGE:
#   ./import-pubkeys.sh
#
# REQUIREMENTS:
#   - pubkeys/ directory must exist in the same directory as this script
#   - Filenames in pubkeys/ must match target usernames
#   - sudo privileges for writing to users' .ssh directories
#
# OUTPUT:
#   - Creates .ssh directory for each user (mode 700)
#   - Copies public key to authorized_keys
#   - Sets correct ownership (user:user)
#

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PUBKEYS_DIR="$SCRIPT_DIR/pubkeys"

# Check if pubkeys directory exists
if [ ! -d "$PUBKEYS_DIR" ]; then
  echo "Error: pubkeys directory not found at $PUBKEYS_DIR"
  exit 1
fi

# Iterate over all files in pubkeys directory
for file in "$PUBKEYS_DIR"/*; do
  if [ -f "$file" ]; then
    username="$(basename "$file")"
    # Create .ssh directory, copy key, set permissions
    sudo mkdir -p "/home/$username/.ssh"
    sudo cp "$file" "/home/$username/.ssh/authorized_keys"
    sudo chown -R "$username:$username" "/home/$username/.ssh"
    sudo chmod 700 "/home/$username/.ssh"
    sudo chmod 600 "/home/$username/.ssh/authorized_keys"
  fi
done
