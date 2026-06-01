#!/bin/bash
# /opt/setup/grade_lab1_1.sh
# Run this as root to evaluate all users simultaneously.

CSV_FILE="/opt/setup/students.csv"

if [ ! -f "$CSV_FILE" ]; then
    echo "Error: Student roster CSV file missing at $CSV_FILE"
    exit 1
fi

echo "=================================================="
echo "      LAB 1.1 GRADING REPORT: SHELL CONFIG        "
echo "=================================================="
echo "Username,PATH_Status,Flag_Status,Grade"

# Skip the CSV header row and process each student entry
tail -n +2 "$CSV_FILE" | while IFS=, read -r username password first_name last_name; do
    # Verify the user profile actually exists on the system
    if ! id "$username" &>/dev/null; then
        echo "$username,User Missing,User Missing,0%"
        continue
    fi

    # 1. TEST PATH EXTENSION: Simulate an interactive login shell as the student
    # Check if they appended the required local lab bin directory to their PATH
    PATH_CHECK=$(su -l "$username" -c 'echo $PATH' | grep "/custom/lab/bin")
    
    if [ -n "$PATH_CHECK" ]; then
        PATH_SCORE=1
        PATH_STATUS="PASS"
    else
        PATH_SCORE=0
        PATH_STATUS="FAIL"
    fi

    # 2. TEST ENVIRONMENT FLAG: Check if the required local variable is active
    FLAG_CHECK=$(su -l "$username" -c 'echo $CYBER_DEFENDER_ROLE' | grep "Level_1_Engineer")
    
    if [ -n "$FLAG_CHECK" ]; then
        FLAG_SCORE=1
        FLAG_STATUS="PASS"
    else
        FLAG_SCORE=0
        FLAG_STATUS="FAIL"
    fi

    # 3. CALCULATE WEIGHTED PROFICIENCY METRIC
    TOTAL_PASSED=$((PATH_SCORE + FLAG_SCORE))
    GRADE_PERCENT=$(( (TOTAL_PASSED * 100) / 2 ))

    # Output directly as a scannable CSV string for the grade book
    echo "$username,$PATH_STATUS,$FLAG_STATUS,${GRADE_PERCENT}%"
done
