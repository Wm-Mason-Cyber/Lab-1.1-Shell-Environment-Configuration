#!/bin/bash
# ci/grade_all_students.sh
#
# Teacher-side batch grading script for Lab 1.1.3.
# Clones every student repo from the Gitea org and grades them using the
# authoritative local copy of ci/grade_checks.sh (not the copy in each
# student repo) so teacher-side grading always reflects the latest logic.
#
# USAGE:
#   GITEA_URL=http://192.168.1.50:3000 \
#   GITEA_TOKEN=<your-api-token>        \
#   CLASS_ORG=lab-1-1                   \
#   bash ci/grade_all_students.sh
#
# REQUIREMENTS: git, curl, jq
#
# GITEA API TOKEN: Gitea → Settings → Applications → Access Tokens.
# Needs read:organization + read:repository scopes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GRADE_SCRIPT="$SCRIPT_DIR/grade_checks.sh"

GITEA_URL="${GITEA_URL:-http://classroom-gitea:3000}"
GITEA_TOKEN="${GITEA_TOKEN:-}"
CLASS_ORG="${CLASS_ORG:-lab-1-1}"
OUTPUT_CSV="lab1_1_3_grades_$(date +%Y%m%d_%H%M%S).csv"
WORKDIR=$(mktemp -d)

trap 'echo "Cleaning up..."; rm -rf "$WORKDIR"' EXIT

# ── Preflight ─────────────────────────────────────────────────────────────────
for cmd in git curl jq; do
    command -v "$cmd" &>/dev/null || { echo "ERROR: '$cmd' not installed."; exit 1; }
done

if [ ! -x "$GRADE_SCRIPT" ]; then
    echo "ERROR: $GRADE_SCRIPT not found or not executable."
    exit 1
fi

if [ -z "$GITEA_TOKEN" ]; then
    read -rsp "Gitea API token: " GITEA_TOKEN
    echo
fi

# ── Fetch student repo list ───────────────────────────────────────────────────
echo "Fetching repos from $GITEA_URL/api/v1/orgs/$CLASS_ORG/repos ..."

HTTP_RESPONSE=$(curl -sw "\n%{http_code}" \
    -H "Authorization: token $GITEA_TOKEN" \
    -H "Accept: application/json" \
    "$GITEA_URL/api/v1/orgs/$CLASS_ORG/repos?limit=50&page=1")

HTTP_BODY=$(echo "$HTTP_RESPONSE" | head -n -1)
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n 1)

if [ "$HTTP_CODE" != "200" ]; then
    echo "ERROR: Gitea API returned HTTP $HTTP_CODE"
    echo "Check GITEA_URL, GITEA_TOKEN, CLASS_ORG."
    echo "Response: $HTTP_BODY"
    exit 1
fi

REPO_COUNT=$(echo "$HTTP_BODY" | jq 'length')
if [ "$REPO_COUNT" -eq 0 ]; then
    echo "ERROR: No repos found in org '$CLASS_ORG'."
    exit 1
fi
echo "Found $REPO_COUNT repos."
echo ""

# ── CSV header ────────────────────────────────────────────────────────────────
echo "student,gitignore_exists,gitignore_blocks_env,env_not_tracked,env_not_in_history,architect_clearance,score,grade_percent" \
    > "$OUTPUT_CSV"

# ── Grade each repo ───────────────────────────────────────────────────────────
FULL_PASS=0
PARTIAL=0
ERRORS=0

while IFS= read -r CLONE_URL; do
    STUDENT=$(basename "$CLONE_URL" .git)
    REPO_DIR="$WORKDIR/$STUDENT"

    printf "  %-20s ... " "$STUDENT"

    if ! git clone -q "$CLONE_URL" "$REPO_DIR" 2>/dev/null; then
        echo "CLONE FAILED"
        echo "$STUDENT,ERROR,ERROR,ERROR,ERROR,ERROR,0/5,0%" >> "$OUTPUT_CSV"
        ERRORS=$((ERRORS + 1))
        continue
    fi

    # Grade using the teacher's authoritative grade_checks.sh, not the
    # student's copy. GRADE_STUDENT overrides the git email in the report.
    pushd "$REPO_DIR" > /dev/null
    GRADE_STUDENT="$STUDENT" bash "$GRADE_SCRIPT" > /dev/null 2>&1 || true
    REPORT=$(cat grade_report.json 2>/dev/null || echo "{}")
    popd > /dev/null

    # Parse JSON fields
    C1=$(echo "$REPORT" | jq -r '.checks.gitignore_exists     // "ERROR"')
    C2=$(echo "$REPORT" | jq -r '.checks.gitignore_blocks_env // "ERROR"')
    C3=$(echo "$REPORT" | jq -r '.checks.env_not_tracked      // "ERROR"')
    C4=$(echo "$REPORT" | jq -r '.checks.env_not_in_history   // "ERROR"')
    C5=$(echo "$REPORT" | jq -r '.checks.architect_clearance  // "ERROR"')
    PASSED=$(echo "$REPORT" | jq -r '.passed // 0')
    GRADE=$(echo "$REPORT"  | jq -r '.grade_percent // 0')

    echo "$PASSED/5  ($GRADE%)"
    echo "$STUDENT,$C1,$C2,$C3,$C4,$C5,$PASSED/5,$GRADE%" >> "$OUTPUT_CSV"

    if [ "$PASSED" -eq 5 ]; then
        FULL_PASS=$((FULL_PASS + 1))
    else
        PARTIAL=$((PARTIAL + 1))
    fi

done < <(echo "$HTTP_BODY" | jq -r '.[].clone_url')

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "  BATCH GRADING COMPLETE"
echo "  100%   : $FULL_PASS students"
echo "  <100%  : $PARTIAL students"
echo "  Errors : $ERRORS (clone/network failures)"
echo "============================================================"
echo ""
echo "Gradebook: $OUTPUT_CSV"
echo ""
column -t -s ',' "$OUTPUT_CSV"
