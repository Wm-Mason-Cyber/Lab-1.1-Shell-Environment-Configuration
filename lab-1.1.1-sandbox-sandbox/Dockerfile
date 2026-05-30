FROM ubuntu:24.04

# Install basic tools, SSH server, and Python environment
RUN apt-get update && apt-get install -y \
    openssh-server \
    python3 \
    python3-pip \
    python3-pytest \
    sudo \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Configure SSH daemon
RUN mkdir /var/run/sshd

# Allow environment variables to be passed through SSH sessions if needed
RUN echo "PermitUserEnvironment yes" >> /etc/ssh/sshd_config

# Create the standard lab student user (Password: CyberDefender2026)
RUN useradd -m -s /bin/bash student && \
    echo "student:CyberDefender2026" | chpasswd

# Setup the testing framework in a read-only directory for the student
RUN mkdir -p /opt/grading
COPY test_lab1_1.py /opt/grading/test_lab1_1.py
RUN chmod 555 /opt/grading && chmod 444 /opt/grading/test_lab1_1.py

# Create a shortcut command for students to test their work easily
RUN echo '#!/bin/bash\npytest /opt/grading/test_lab1_1.py' > /usr/local/bin/submit-lab && \
    chmod +x /usr/local/bin/submit-lab

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
