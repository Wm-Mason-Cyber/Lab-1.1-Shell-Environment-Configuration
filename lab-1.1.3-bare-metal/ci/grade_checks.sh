#!/bin/bash
# ci/grade_checks.sh
#
# SINGLE SOURCE OF TRUTH for Lab 1.1.3 grading logic.
# Used by: ci/grade.yml (Gitea CI), ci/grade_all_students.sh (teacher batch).
#
# USAGE: Run from the root of a student's host-deployment-project repo.
#   bash ci/grade_checks.sh
#
# ENV:
#   GRADE_STUDENT  override the student identifier in the report
#                  (defaults to the git committer email of HEAD)
#
# OUTPUT:
#   - Human-readable report  → stdout
#   - grade_report.json      → current directory
#   - Exit 0 all pass / Exit 1 any fail

set -uo pipefail

STUDENT="${GRADE_STUDENT:-$(git log -1 --format='%ae' 2>/dev/null || echo 'unknown')}"
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "none")
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

C1="FAIL" C2="FAIL" C3="FAIL" C4="FAIL" C5="FAIL"
NOTES=()

# ── Check 1: .gitignore exists ────────────────────────────────────────────────
if [ -f .gitignore ]; then
    C1="PASS"
else
    NOTES+=("[1] .gitignore not found in repo root")
fi

# ── Check 2: .gitignore explicitly blocks .env ────────────────────────────────
if grep -qE '^\.env$' .gitignore 2>/dev/null; then
    C2="PASS"
else
    NOTES+=("[2] .gitignore missing an exact '.env' line (wildcards don't count)")
fi

# ── Check 3: .env not currently tracked ──────────────────────────────────────
TRACKED=$(git ls-files .env 2>/dev/null)
if [ -z "$TRACKED" ]; then
    C3="PASS"
else
    NOTES+=("[3] .env is tracked — run: git rm --cached .env && git commit")
fi

# ── Check 4: .env never committed to any branch ───────────────────────────────
COMMIT_COUNT=$(git log --all --full-history --oneline -- .env 2>/dev/null | wc -l | tr -d '[:space:]')
if [ "$COMMIT_COUNT" -eq 0 ]; then
    C4="PASS"
else
    NOTES+=("[4] .env appears in $COMMIT_COUNT commit(s) — history is permanent without git filter-repo")
    while IFS= read -r line; do
        NOTES+=("    $line")
    done < <(git log --all --full-history --oneline -- .env 2>/dev/null | head -5)
fi

# ── Check 5: ARCHITECT_CLEARANCE evidence file ────────────────────────────────
if [ -f env_evidence.txt ] && grep -q "^LEVEL_4_HOST$" env_evidence.txt; then
    C5="PASS"
else
    NOTES+=("[5] env_evidence.txt missing or does not contain exactly 'LEVEL_4_HOST'")
    NOTES+=("    Run: printenv ARCHITECT_CLEARANCE > env_evidence.txt && git add env_evidence.txt && git commit")
fi

# ── Tally ─────────────────────────────────────────────────────────────────────
PASSED=0
[ "$C1" = "PASS" ] && PASSED=$((PASSED + 1))
[ "$C2" = "PASS" ] && PASSED=$((PASSED + 1))
[ "$C3" = "PASS" ] && PASSED=$((PASSED + 1))
[ "$C4" = "PASS" ] && PASSED=$((PASSED + 1))
[ "$C5" = "PASS" ] && PASSED=$((PASSED + 1))
GRADE=$((PASSED * 100 / 5))

# ── Human-readable report ─────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "  LAB 1.1.3 GRADE REPORT"
echo "  Student  : $STUDENT"
echo "  Commit   : $COMMIT"
echo "  Graded   : $TIMESTAMP"
echo "============================================================"
printf "  %-42s %s\n" "[1] .gitignore exists"             "$C1"
printf "  %-42s %s\n" "[2] .gitignore blocks .env"         "$C2"
printf "  %-42s %s\n" "[3] .env not in working tree"        "$C3"
printf "  %-42s %s\n" "[4] .env never committed"            "$C4"
printf "  %-42s %s\n" "[5] ARCHITECT_CLEARANCE evidence"    "$C5"
echo "------------------------------------------------------------"
echo "  Score : $PASSED / 5  ($GRADE%)"
echo "============================================================"

if [ "${#NOTES[@]}" -gt 0 ]; then
    echo ""
    echo "  What to fix:"
    for note in "${NOTES[@]}"; do
        echo "  $note"
    done
    echo ""
fi

# ── JSON report (for machine parsing by grade_all_students.sh) ────────────────
cat > grade_report.json <<EOF
{
  "student": "$STUDENT",
  "commit": "$COMMIT",
  "timestamp": "$TIMESTAMP",
  "checks": {
    "gitignore_exists":     "$C1",
    "gitignore_blocks_env": "$C2",
    "env_not_tracked":      "$C3",
    "env_not_in_history":   "$C4",
    "architect_clearance":  "$C5"
  },
  "passed": $PASSED,
  "total": 5,
  "grade_percent": $GRADE
}
EOF

[ "$PASSED" -eq 5 ]
