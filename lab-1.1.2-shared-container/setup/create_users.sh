#!/bin/bash
# create_users.sh — Create student user accounts from a CSV file
#
# CSV format (with header row):
#   username,password,first_name,last_name
#
# Each user is:
#   - Added to the 'students' group
#   - Given a private home directory (chmod 700)
#   - Given a ~/scratch/ directory to practice rm -r on
#
# Already-existing users are skipped (passwords are NOT reset).
# Re-run create_users.sh after reset_homes.sh if you need fresh scratch dirs.
#
# Usage:
#   sudo bash setup/create_users.sh setup/students.csv

set -e

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: This script must be run as root." >&2
    exit 1
fi

CSV_FILE="${1:-}"

if [ -z "$CSV_FILE" ] || [ ! -f "$CSV_FILE" ]; then
    echo "Usage: sudo bash $0 <students.csv>" >&2
    echo "  CSV format: username,password,first_name,last_name" >&2
    exit 1
fi

# Create students group if it doesn't exist
if ! getent group students > /dev/null 2>&1; then
    groupadd students
    echo "Created group: students"
fi

created=0
skipped=0
line_num=0

while IFS=',' read -r username password first_name last_name _rest; do
    line_num=$((line_num + 1))

    # Skip header row
    [ "$line_num" -eq 1 ] && [ "$username" = "username" ] && continue
    # Skip blank lines
    [ -z "$username" ] && continue

    # Strip whitespace and Windows carriage returns
    username=$(echo "$username"   | tr -d '[:space:]')
    password=$(echo "$password"   | tr -d '\r')
    first_name=$(echo "$first_name" | tr -d '\r')
    last_name=$(echo "$last_name"   | tr -d '\r')

    if id "$username" &>/dev/null; then
        echo "  [skip]    $username — already exists"
        skipped=$((skipped + 1))
        continue
    fi

    # Create the user account
    useradd \
        --create-home \
        --shell /bin/bash \
        --comment "$first_name $last_name" \
        --groups students \
        "$username"

    # Set password
    echo "$username:$password" | chpasswd

    # Private home directory — only the student can read it
    chmod 700 "/home/$username"

    # Create scratch/ with a nested directory so rm -r is required
    mkdir -p "/home/$username/scratch/old_notes"

    cat > "/home/$username/scratch/test.txt" << 'SCRATCHEOF'
Just a scratch file. Nothing useful here.

When you are ready to clean up, delete this whole folder:
  rm -r scratch
SCRATCHEOF

    cat > "/home/$username/scratch/old_notes/reminder.txt" << 'SCRATCHEOF'
Old notes — safe to delete.
Try:  cd ~  then  rm -r scratch
SCRATCHEOF

    chown -R "$username:$username" "/home/$username/scratch"

    echo "  [created] $username ($first_name $last_name)"
    created=$((created + 1))

done < "$CSV_FILE"

echo ""
echo "Done.  Created: $created   Skipped (already existed): $skipped"