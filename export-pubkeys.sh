#!/bin/bash
#
# copy-pubkey.sh - Export SSH public keys from user home directories
#
# DESCRIPTION:
#   This script reads user entries from a passwd-format file and copies
#   each user's authorized_keys file to a centralized directory. Only
#   processes regular users (UID >= 1000) who have existing home directories.
#
# USAGE:
#   ./copy-pubkey.sh
#
# REQUIREMENTS:
#   - A 'passwd' file in the current directory (standard passwd format)
#   - sudo privileges for reading users' .ssh directories
#
# OUTPUT:
#   - Copies authorized_keys to pubkeys/<username> in the script directory
#   - Sets ownership of exported keys to current user
#
# EXIT CODES:
#   0 - Success
#   1 - passwd file not found
#

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

PASSWD_FILE="$SCRIPT_DIR/passwd"
KEY_DIR="$SCRIPT_DIR/pubkeys"

if [[ ! -f "$PASSWD_FILE" ]]; then
  echo "Error: passwd does not exist: $PASSWD_FILE"
  exit 1
fi

mkdir -p "$KEY_DIR"

while IFS=':' read -r username _password uid _gid _gecos home _shell; do
  # Skip empty lines and comments
  if [[ -z "$username" || "$username" =~ ^# ]]; then
    continue
  fi

  # Only process regular users (UID >= 1000)
  if [[ "$uid" -ge 1000 ]]; then
    # Check if user has a home directory
    if [[ -n "$home" && -d "$home" ]]; then
      sudo cp "$home/.ssh/authorized_keys" "$KEY_DIR/$username"
    fi
  fi
done < "$PASSWD_FILE"

sudo chown -R "$(id -un):$(id -gn)" "$KEY_DIR"
