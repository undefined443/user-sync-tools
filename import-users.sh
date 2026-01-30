#!/bin/bash
#
# sync_user.sh - Synchronize users from passwd file to local system
#
# DESCRIPTION:
#   This script reads user entries from a passwd-format file and creates
#   corresponding local users and groups. It only processes regular users
#   (UID >= 1000) and skips users that already exist on the system.
#
# USAGE:
#   ./sync_user.sh
#
# REQUIREMENTS:
#   - A 'passwd' file in the current directory (standard passwd format)
#   - sudo privileges for creating users and groups
#
# PASSWD FILE FORMAT:
#   username:password:uid:gid:gecos:home:shell
#   Example: john:x:1001:1001:John Doe:/home/john:/bin/bash
#
# OUTPUT:
#   - Displays statistics of users to create and existing users
#   - Creates users after confirmation
#   - Logs operations to sync_users.log
#
# EXIT CODES:
#   0 - Success or operation canceled by user
#   1 - passwd file not found
#

PASSWD_FILE="passwd"
LOG_FILE="sync_users.log"

if [[ ! -f "$PASSWD_FILE" ]]; then
  echo "Error: passwd does not exist: $PASSWD_FILE"
  exit 1
fi

declare -a create_list
declare -a exist_list

while IFS=':' read -r username _password uid gid gecos home shell; do
  # Skip empty lines and comments
  if [[ -z "$username" || "$username" =~ ^# ]]; then
    continue
  fi

  # Only process regular users (UID >= 1000)
  if [[ "$uid" -ge 1000 ]]; then
    if id "$username" &> /dev/null; then
      exist_list+=("$username")
    else
      create_list+=("$username:$uid:$gid:$gecos:$home:$shell")
    fi
  fi
done < "$PASSWD_FILE"

# Display statistics
echo "Number of user to create: ${#create_list[@]}"
echo "Number of existing user: ${#exist_list[@]}"
echo ""

# Display existing users
if [[ ${#exist_list[@]} -gt 0 ]]; then
  echo "Existing user:"
  for user in "${exist_list[@]}"; do
    echo "  - $user"
  done
  echo ""
fi

# Display users to be created
if [[ ${#create_list[@]} -gt 0 ]]; then
  echo "User to create:"
  echo "UserName        UID    GID    Description"
  echo "----------------------------------------"
  for user_info in "${create_list[@]}"; do
    IFS=':' read -r username uid gid gecos home shell <<< "$user_info"
    # Truncate GECOS to first 20 characters for display
    gecos_display="${gecos:0:20}"
    if [[ ${#gecos} -gt 20 ]]; then
      gecos_display="${gecos_display}..."
    fi
    printf "%-12s %-6s %-6s %s\n" "$username" "$uid" "$gid" "$gecos_display"
  done
  echo ""

  # Check for sudo privileges
  if ! sudo -n true 2> /dev/null; then
    echo "No sudo privileges, unable to create user."
    exit 0
  fi

  # Ask for user confirmation
  echo "Do you want to continue creating these users?"
  read -p "Enter 'yes' to continue, any other input will cancel: " confirm

  if [[ "$confirm" != "yes" ]]; then
    echo "Operation canceled."
    exit 0
  fi

  # Create users
  for user_info in "${create_list[@]}"; do
    IFS=':' read -r username uid gid gecos home shell <<< "$user_info"
    GROUPADD_CMD="sudo groupadd"
    USERADD_CMD="sudo useradd" # Build useradd command

    # Add UID if specified
    if [[ -n "$uid" ]]; then
      USERADD_CMD="$USERADD_CMD -u $uid"
    fi

    # Add GID if specified
    if [[ -n "$gid" ]]; then
      GROUPADD_CMD="$GROUPADD_CMD -g $gid"
      USERADD_CMD="$USERADD_CMD -g $gid"
    fi

    # Add GECOS info (full name, etc.)
    if [[ -n "$gecos" ]]; then
      USERADD_CMD="$USERADD_CMD -c \"$gecos\""
    fi

    # Add home directory
    if [[ -n "$home" ]]; then
      USERADD_CMD="$USERADD_CMD -d $home"
    fi

    # Add shell
    if [[ -n "$shell" ]]; then
      USERADD_CMD="$USERADD_CMD -s $shell"
    fi

    # Add username
    GROUPADD_CMD="$GROUPADD_CMD $username"
    USERADD_CMD="$USERADD_CMD $username"

    # Execute user creation command
    echo "Execute: $USERADD_CMD" >> "$LOG_FILE"

    if eval "$GROUPADD_CMD && $USERADD_CMD" 2>> "$LOG_FILE"; then
      echo "✓ Successfully created user: $username" | tee -a "$LOG_FILE"

      # Create home directory if it doesn't exist
      if [[ -n "$home" && ! -d "$home" ]]; then
        sudo mkdir -p "$home"
        sudo mkdir -p "$home/.ssh"
        sudo chown "$username:$username" "$home"
        echo "✓ Create home directory: $home" >> "$LOG_FILE"
      fi
    else
      echo "✗ Failed to create user: $username" | tee -a "$LOG_FILE"
    fi

    echo "---" >> "$LOG_FILE"
  done

  echo ""
  echo "User creation completed!"
  echo "Log: $LOG_FILE"
else
  echo "There is no need to create a user."
fi

echo ""
echo "List of regular users in the current system:"
echo "=========================="
# Display users with UID >= 1000
getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 {print $1 " (UID: " $3 ")"}' | sort
