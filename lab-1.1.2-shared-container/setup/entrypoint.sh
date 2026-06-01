#!/bin/bash
# Container entrypoint.
# 1. Creates student accounts for this period.
# 2. Initializes the shared class git repository.
# 3. Starts sshd.
#
# ENV:
#   PERIOD   if set, only students whose 'period' column (col 5) matches
#            are created. Unset = all students in the CSV.

set -e

CSV=/opt/setup/students.csv
FILTERED=/tmp/students_filtered.csv

# ── Student accounts ──────────────────────────────────────────────────────────
if [ ! -f "$CSV" ]; then
    echo "[entrypoint] WARNING: $CSV not found — no student accounts created."
    echo "[entrypoint] Mount students.csv at $CSV and restart the container."
else
    if [ -n "${PERIOD:-}" ]; then
        echo "[entrypoint] Filtering students for period $PERIOD ..."
        awk -F',' -v p="$PERIOD" \
            'NR==1 { print "username,password,first_name,last_name"; next }
             $5 == p { print $1","$2","$3","$4 }' \
            "$CSV" > "$FILTERED"
        bash /opt/setup/create_users.sh "$FILTERED"
    else
        echo "[entrypoint] PERIOD not set — creating all students in roster ..."
        bash /opt/setup/create_users.sh "$CSV"
    fi
fi

# ── Shared class git repository ───────────────────────────────────────────────
bash /opt/setup/init_class_repo.sh

echo "[entrypoint] Starting SSH daemon ..."
exec /usr/sbin/sshd -D
