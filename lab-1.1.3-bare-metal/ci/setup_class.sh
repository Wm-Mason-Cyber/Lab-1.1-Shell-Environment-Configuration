#!/bin/bash
# ci/setup_class.sh
#
# One-time class provisioning for Lab 1.1.3.
# Run once at term start from the teacher's machine.
#
# WHAT IT DOES (per student in the CSV):
#   1. Creates Gitea org 'lab-1-1' (once, idempotent)
#   2. Creates a Gitea user account
#   3. Creates repo  lab-1-1/<username>  initialized on 'main'
#   4. Grants the student write access to their own repo
#   5. Seeds .gitea/workflows/grade.yml  (the CI workflow)
#   6. Seeds ci/grade_checks.sh          (the grading logic)
#
# USAGE:
#   GITEA_URL=http://192.168.1.50:3000 \
#   GITEA_TOKEN=<admin-api-token>       \
#   bash ci/setup_class.sh students.csv
#
# CSV FORMAT (same as lab-1.1.2-shared-container/setup/students.csv):
#   username,password,first_name,last_name
#   (header row is skipped automatically)
#
# REQUIREMENTS: git, curl, jq
#
# NOTE: GITEA_TOKEN must be an ADMIN token.
#   Gitea → Site Administration → User Management → your admin account
#   → Settings → Applications → Generate Token  (check all scopes)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_FILE="$SCRIPT_DIR/grade.yml"
CHECKS_FILE="$SCRIPT_DIR/grade_checks.sh"
CSV_FILE="${1:-}"

GITEA_URL="${GITEA_URL:-http://classroom-gitea:3000}"
GITEA_TOKEN="${GITEA_TOKEN:-}"
ORG_NAME="lab-1-1"
DEFAULT_BRANCH="main"

# ── Preflight ─────────────────────────────────────────────────────────────────
for cmd in curl jq; do
    command -v "$cmd" &>/dev/null || { echo "ERROR: '$cmd' not installed."; exit 1; }
done

if [ -z "$CSV_FILE" ]; then
    echo "USAGE: bash setup_class.sh students.csv"
    exit 1
fi

if [ ! -f "$CSV_FILE" ]; then
    echo "ERROR: CSV not found: $CSV_FILE"
    exit 1
fi

if [ ! -f "$WORKFLOW_FILE" ] || [ ! -f "$CHECKS_FILE" ]; then
    echo "ERROR: grade.yml or grade_checks.sh not found next to this script."
    echo "       Expected: $WORKFLOW_FILE"
    echo "       Expected: $CHECKS_FILE"
    exit 1
fi

if [ -z "$GITEA_TOKEN" ]; then
    read -rsp "Gitea admin API token: " GITEA_TOKEN
    echo
fi

# ── Helpers ───────────────────────────────────────────────────────────────────

# POST/PUT/GET to Gitea API; prints response body.
api() {
    local method="$1" path="$2" data="${3:-}"
    curl -s -X "$method" \
        -H "Authorization: token $GITEA_TOKEN" \
        -H "Content-Type: application/json" \
        ${data:+-d "$data"} \
        "$GITEA_URL/api/v1$path"
}

# Returns the HTTP status code only.
api_code() {
    local method="$1" path="$2" data="${3:-}"
    curl -s -o /dev/null -w "%{http_code}" -X "$method" \
        -H "Authorization: token $GITEA_TOKEN" \
        -H "Content-Type: application/json" \
        ${data:+-d "$data"} \
        "$GITEA_URL/api/v1$path"
}

# Base64-encode a file (portable: strips newlines).
b64() { base64 "$1" | tr -d '\n'; }

# Create a file in a Gitea repo via the contents API.
# Args: owner repo filepath local_file commit_message
seed_file() {
    local owner="$1" repo="$2" filepath="$3" local_file="$4" msg="$5"
    local encoded
    encoded=$(b64 "$local_file")
    local body
    body=$(jq -n \
        --arg msg "$msg" \
        --arg content "$encoded" \
        --arg branch "$DEFAULT_BRANCH" \
        '{"message": $msg, "content": $content, "branch": $branch}')
    local code
    code=$(api_code POST "/repos/$owner/$repo/contents/$filepath" "$body")
    if [ "$code" = "201" ]; then
        echo "    seeded $filepath"
    else
        echo "    WARNING: seed $filepath returned HTTP $code (may already exist)"
    fi
}

# ── Step 1: Create org (idempotent) ──────────────────────────────────────────
echo "Creating org '$ORG_NAME' ..."
ORG_CODE=$(api_code POST "/orgs" \
    "{\"username\": \"$ORG_NAME\", \"visibility\": \"private\"}")
if [ "$ORG_CODE" = "201" ]; then
    echo "  Org created."
elif [ "$ORG_CODE" = "422" ]; then
    echo "  Org already exists — continuing."
else
    echo "  ERROR: org creation returned HTTP $ORG_CODE"
    exit 1
fi

# ── Step 2: Provision each student ───────────────────────────────────────────
echo ""
echo "Provisioning students from $CSV_FILE ..."
echo ""

CREATED=0
SKIPPED=0
FAILED=0

tail -n +2 "$CSV_FILE" | while IFS=, read -r username password first_name last_name; do
    # Strip carriage returns (Windows CSV safety)
    username=$(echo "$username" | tr -d '\r')
    password=$(echo "$password" | tr -d '\r')
    first_name=$(echo "$first_name" | tr -d '\r')
    last_name=$(echo "$last_name" | tr -d '\r')

    [ -z "$username" ] && continue

    printf "  %-20s" "$username"

    # ── 2a. Create user account ───────────────────────────────────────────────
    USER_CODE=$(api_code POST "/admin/users" "$(jq -n \
        --arg login "$username" \
        --arg password "$password" \
        --arg email "${username}@lab.local" \
        --arg source_id 0 \
        --arg login_name "$username" \
        '{"login_name": $login, "username": $login, "email": $email,
          "password": $password, "source_id": 0,
          "must_change_password": false}')")

    if [ "$USER_CODE" = "201" ]; then
        printf " user=created"
    elif [ "$USER_CODE" = "422" ]; then
        printf " user=exists "
    else
        printf " user=ERROR(%s)" "$USER_CODE"
        FAILED=$((FAILED + 1))
        echo ""
        continue
    fi

    # ── 2b. Create repo ───────────────────────────────────────────────────────
    REPO_CODE=$(api_code POST "/orgs/$ORG_NAME/repos" "$(jq -n \
        --arg name "$username" \
        --arg branch "$DEFAULT_BRANCH" \
        '{"name": $name, "private": true, "auto_init": true,
          "default_branch": $branch}')")

    if [ "$REPO_CODE" = "201" ]; then
        printf " repo=created"
    elif [ "$REPO_CODE" = "409" ]; then
        printf " repo=exists "
    else
        printf " repo=ERROR(%s)" "$REPO_CODE"
        FAILED=$((FAILED + 1))
        echo ""
        continue
    fi

    # ── 2c. Grant student write access ────────────────────────────────────────
    COLLAB_CODE=$(api_code PUT "/repos/$ORG_NAME/$username/collaborators/$username" \
        '{"permission": "write"}')
    if [ "$COLLAB_CODE" = "204" ]; then
        printf " access=granted"
    else
        printf " access=ERROR(%s)" "$COLLAB_CODE"
    fi

    echo ""

    # ── 2d. Seed grading files (only if repo was just created) ───────────────
    if [ "$REPO_CODE" = "201" ]; then
        seed_file "$ORG_NAME" "$username" \
            ".gitea/workflows/grade.yml" "$WORKFLOW_FILE" \
            "ci: add automated grading workflow"
        seed_file "$ORG_NAME" "$username" \
            "ci/grade_checks.sh" "$CHECKS_FILE" \
            "ci: add grading logic"
        CREATED=$((CREATED + 1))
    else
        SKIPPED=$((SKIPPED + 1))
    fi

done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "  SETUP COMPLETE"
echo "  Org      : $ORG_NAME  ($GITEA_URL/$ORG_NAME)"
echo "  Created  : $CREATED repos"
echo "  Skipped  : $SKIPPED repos (already existed)"
echo "  Errors   : $FAILED"
echo "============================================================"
echo ""
echo "Each student's push URL:"
echo "  http://GITEA_IP:3000/$ORG_NAME/<username>"
echo ""
echo "Student git commands:"
echo "  git remote add origin http://GITEA_IP:3000/$ORG_NAME/<username>"
echo "  git push -u origin main"
