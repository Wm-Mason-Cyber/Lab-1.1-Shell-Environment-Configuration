FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    openssh-server \
    python3 \
    sudo \
    git \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/run/sshd

# Pre-generate SSH host keys so they are stable across container restarts.
# Without this, keys regenerate on every start and students get
# "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED" errors.
RUN ssh-keygen -A

# Create the students group early so /srv/class permissions can be set here.
# create_users.sh also does this check idempotently at runtime.
RUN groupadd students

# Shared class git repository directory.
# The bare repo itself is initialized by entrypoint.sh (not here) so it
# always starts from a clean network_matrix.json on container creation.
RUN mkdir -p /srv/class && chgrp students /srv/class && chmod 2775 /srv/class

# Root/Teacher scripts — read-only to students.
# students.csv is NOT baked in; it is mounted at runtime via docker-compose.
RUN mkdir -p /opt/setup
COPY setup/create_users.sh      /opt/setup/create_users.sh
COPY setup/reset_homes.sh       /opt/setup/reset_homes.sh
COPY setup/grade_lab1_1.sh      /opt/setup/grade_lab1_1.sh
COPY setup/entrypoint.sh        /opt/setup/entrypoint.sh
COPY setup/init_class_repo.sh   /opt/setup/init_class_repo.sh
COPY setup/network_matrix.json  /opt/setup/network_matrix.json
RUN chmod 700 /opt/setup/*.sh && chmod 644 /opt/setup/network_matrix.json

# Student-facing self-check command. Run from SSH session as: check-lab
COPY setup/check_lab.sh /usr/local/bin/check-lab
RUN chmod 755 /usr/local/bin/check-lab

EXPOSE 22

ENTRYPOINT ["/opt/setup/entrypoint.sh"]
