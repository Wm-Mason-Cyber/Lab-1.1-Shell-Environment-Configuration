#!/bin/bash
# check_lab.sh — Lab 1.1.2 student self-check.
# Installed at /usr/local/bin/check-lab so students run it as: check-lab
#
# No root required. Runs as the calling student user.

STUDENT="$USER"
REPO=/srv/class/network_matrix.git

C1="FAIL" C2="FAIL" C3="FAIL"
NOTES=()

# ── Check 1: ARCHITECT_CLEARANCE set in .bashrc ───────────────────────────────
if grep -qE 'export ARCHITECT_CLEARANCE="LEVEL_4_HOST"' "$HOME/.bashrc" 2>/dev/null || \
   grep -qE "export ARCHITECT_CLEARANCE='LEVEL_4_HOST'" "$HOME/.bashrc" 2>/dev/null; then
    C1="PASS"
else
    NOTES+=("[1] Add this line to ~/.bashrc:  export ARCHITECT_CLEARANCE=\"LEVEL_4_HOST\"")
    NOTES+=("    Then run:  source ~/.bashrc")
fi

# ── Check 2: Seat PROVISIONED with student's username in the central repo ──────
# Reads network_matrix.json directly from the bare repo — no clone needed.
if git -C "$REPO" show main:network_matrix.json 2>/dev/null \
        | grep -q "\"provisioned_by\": \"$STUDENT\""; then
    C2="PASS"
else
    NOTES+=("[2] Your seat is not marked PROVISIONED in the central repo.")
    NOTES+=("    Open ~/network_matrix/network_matrix.json, find your seat,")
    NOTES+=("    set status to PROVISIONED and provisioned_by to \"$STUDENT\",")
    NOTES+=("    then commit and push.")
fi

# ── Check 3: ~/network_matrix is a clone of the class repo ────────────────────
if git -C "$HOME/network_matrix" remote get-url origin 2>/dev/null \
        | grep -q "$REPO"; then
    C3="PASS"
else
    NOTES+=("[3] ~/network_matrix not found or not cloned from the class repo.")
    NOTES+=("    Run:  git clone $REPO ~/network_matrix")
fi

# ── Tally ─────────────────────────────────────────────────────────────────────
PASSED=0
[ "$C1" = "PASS" ] && PASSED=$((PASSED + 1))
[ "$C2" = "PASS" ] && PASSED=$((PASSED + 1))
[ "$C3" = "PASS" ] && PASSED=$((PASSED + 1))
GRADE=$((PASSED * 100 / 3))

# ── Report ────────────────────────────────────────────────────────────────────
echo ""
echo "=============================================="
echo "  LAB 1.1.2 SELF-CHECK  —  $STUDENT"
echo "=============================================="
printf "  %-38s %s\n" "[1] ARCHITECT_CLEARANCE in .bashrc"  "$C1"
printf "  %-38s %s\n" "[2] Seat PROVISIONED in central repo" "$C2"
printf "  %-38s %s\n" "[3] network_matrix cloned"            "$C3"
echo "----------------------------------------------"
echo "  Score: $PASSED / 3  ($GRADE%)"
echo "=============================================="

if [ "${#NOTES[@]}" -gt 0 ]; then
    echo ""
    echo "  What to fix:"
    for note in "${NOTES[@]}"; do
        echo "  $note"
    done
    echo ""
fi
