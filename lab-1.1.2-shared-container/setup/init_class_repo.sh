#!/bin/bash
# init_class_repo.sh
# Initialize (or fully reset) the shared class git repository.
# Creates a fresh bare repo seeded from /opt/setup/network_matrix.json.
#
# Called by: entrypoint.sh (container start), reset_homes.sh (between periods)
# Must run as root.

set -e

REPO=/srv/class/network_matrix.git
SEED=/opt/setup/network_matrix.json

if [ "$EUID" -ne 0 ]; then
    echo "ERROR: init_class_repo.sh must run as root." >&2
    exit 1
fi

echo "[repo] Resetting shared class repository at $REPO ..."

# Wipe and recreate the bare repo from scratch
rm -rf "$REPO"
git init --bare --shared=group "$REPO" --quiet
git -C "$REPO" symbolic-ref HEAD refs/heads/main
chgrp -R students /srv/class
chmod -R 2775 /srv/class

# Seed the initial commit via a temp working tree
# (bare repos can't have a working tree directly)
TMPWORK=$(mktemp -d)
trap 'rm -rf "$TMPWORK"' EXIT

git -C "$TMPWORK" init -b main --quiet
git -C "$TMPWORK" config user.email "instructor@lab.local"
git -C "$TMPWORK" config user.name "Lab Instructor"
cp "$SEED" "$TMPWORK/network_matrix.json"
git -C "$TMPWORK" add network_matrix.json
git -C "$TMPWORK" commit -m "init: baseline allocation matrix — all seats available" --quiet
git -C "$TMPWORK" remote add origin "$REPO"
git -C "$TMPWORK" push origin main --quiet

chmod -R g+r /srv/class/network_matrix.git/objects

echo "[repo] Done. Students clone with:"
echo "         git clone $REPO ~/network_matrix"
