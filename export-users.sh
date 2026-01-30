#!/bin/bash
#
# export-users.sh - Export regular users to passwd file
#
# DESCRIPTION:
#   This script exports all regular users (UID 1000-59999) from the system
#   to a passwd-format file. This file can be used with import-users.sh
#   to replicate users on another system.
#
# USAGE:
#   ./export-users.sh
#
# OUTPUT:
#   - Creates 'passwd' file in current directory
#
# SEE ALSO:
#   import-users.sh - Import users from passwd file
#

# Export regular users (UID 1000-59999) to passwd file
getent passwd | awk -F: '$3 >= 1000 && $3 < 60000' > passwd
