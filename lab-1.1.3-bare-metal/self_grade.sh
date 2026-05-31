#!/bin/bash
# Self-Grading Script for Lab 1.1: Shell Environment Configuration

# Download (if needed) and run the grading test against your shell configuration
# in a clean, containerized environment that simulates a fresh login.

# You can run this repeatedly, until you are satisfied with your results.
# The grading script will simulate a fresh login and is a 1:1 match for the teacher's grading criteria.

# This script is designed to be run on the host machine, not inside the container.
# It will execute the grading script within a temporary container instance to ensure a clean environment for testing.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

LOCAL_TEST="$REPO_ROOT/lab-1.1.1-sandbox-sandbox/test_lab1_1.py"
REMOTE_URL="https://raw.githubusercontent.com/Wm-Mason-Cyber/Lab-1.1-Shell-Environment-Configuration/main/lab-1.1.1-sandbox-sandbox/test_lab1_1.py"
DOCKERFILE_DIR="$REPO_ROOT/lab-1.1.1-sandbox-sandbox"
IMAGE_NAME="lab1_1-selfgrade"

# ── Step 1: Get the grading test script ──────────────────────────────────────
if [ ! -f "$LOCAL_TEST" ]; then
    echo "Grading script not found locally. Downloading from course repo..."
    if ! curl -fsSL "$REMOTE_URL" -o "$LOCAL_TEST"; then
        echo "ERROR: Download failed. Check your internet connection and try again."
        exit 1
    fi
    echo "Downloaded: test_lab1_1.py"
fi

# ── Step 2: Check Docker availability ────────────────────────────────────────
if ! command -v docker &>/dev/null; then
    echo "ERROR: Docker is not installed or not found in PATH."
    echo "       Install Docker Desktop and try again."
    exit 1
fi

if ! docker info &>/dev/null 2>&1; then
    echo "ERROR: Docker daemon is not running."
    echo "       Start Docker Desktop and try again."
    exit 1
fi

# ── Step 3: Build the grading image if not already cached ────────────────────
if ! docker image inspect "$IMAGE_NAME" &>/dev/null 2>&1; then
    echo "Building grading environment (first-run only)..."
    docker build -q -t "$IMAGE_NAME" "$DOCKERFILE_DIR"
    echo "Environment ready."
fi

# ── Step 4: Run the grading tests inside a temporary container ───────────────
echo ""
echo "=================================================="
echo "   LAB 1.1.3 SELF-GRADING: BARE METAL CONFIG     "
echo "=================================================="
echo "Evaluating shell config for: $HOME"
echo ""

# Mount the student's home directory read-only so bash -l inside the container
# reads their actual .bashrc when running tests.
# HOME is set explicitly so bash login shells resolve ~ to the mounted directory.
set +e
docker run --rm \
    -v "$HOME:/home/student:ro" \
    -v "$LOCAL_TEST:/opt/grading/test_lab1_1.py:ro" \
    -e HOME=/home/student \
    "$IMAGE_NAME" \
    bash -c "pytest /opt/grading/test_lab1_1.py -v --tb=short --no-header"
RESULT=$?
set -e

echo ""
echo "=================================================="
if [ "$RESULT" -eq 0 ]; then
    echo "  All tests PASSED. You are ready to submit!"
else
    echo "  Some tests FAILED. Review output above,"
    echo "  fix your .bashrc, source it, and run again."
fi
echo "=================================================="

exit "$RESULT"
