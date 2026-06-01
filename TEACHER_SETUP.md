# Teacher Setup Guide — Lab 1.1

Step-by-step instructions to deploy all three lab levels. Each level is independent; you can run them in any order or skip levels your class won't use.

---

## Prerequisites

| Tool | Required for | Install |
|------|-------------|---------|
| Docker + Docker Compose v2 | Lab 1.1.1 & 1.1.2 | `apt install docker.io` or Docker Desktop |
| Git | All levels | `apt install git` |
| Gitea | Lab 1.1.3 | See [Lab 1.1.3 Setup](#lab-113--bare-metal) below |
| gitea-act-runner | Lab 1.1.3 CI | See [Act Runner](#act-runner) below |
| `curl`, `jq` | Lab 1.1.3 scripts | `apt install curl jq` |

---

## Student Roster CSV

All scripts share the same CSV format. Copy the example and fill it in:

```bash
cp lab-1.1.2-shared-container/setup/students.csv.example \
   lab-1.1.2-shared-container/setup/students.csv
```

**Format:** `username,password,first_name,last_name,period,student_id,grade_level`

- `username` — no spaces, no special characters. Used as the Linux/Gitea account name.
- `password` — temporary lab password. Students change it if needed.
- `period` — must match the `PERIOD` values in `compose.yaml` (default: `1`–`7`).
- Extra columns (`student_id`, `grade_level`) are ignored by scripts but preserved in the file.

`students.csv` is gitignored. Only `students.csv.example` is tracked.

---

## Lab 1.1.1 — Sandbox

One isolated Docker container per student. Students SSH in, do the git conflict exercise, and run `submit-lab` to self-grade.

### Build the image

```bash
cd lab-1.1.1-sandbox-sandbox
docker build -t lab1_1-sandbox:latest .
```

### Deploy containers for a period

Edit `orchestrate_labs.py` if needed, then run:

```bash
# Period 1 students from period1_roster.csv
python3 orchestrate_labs.py
# deploy_class(1, "period1_roster.csv")
```

Containers are named `p<period>-<username>` and assigned sequential ports starting at `2001` (Period 1), `2101` (Period 2), etc.

### Student connection

```
ssh student@<classroom-ip> -p <assigned-port>
Password: CyberDefender2026
```

### Grading

Grade results are written to the host volume automatically when students run `submit-lab`:

```
/var/lab_data/<container-name>/grades/results.json
```

---

## Lab 1.1.2 — Shared Container

One container per class period. All students in a period SSH into the same container with individual accounts. They collaborate on a shared git repo at `/srv/class/network_matrix.git`.

### One-time setup

```bash
cd lab-1.1.2-shared-container
cp setup/students.csv.example setup/students.csv
# Edit students.csv with real student data
```

### Build and start

```bash
docker compose build
docker compose up -d          # starts all 7 periods (p1–p7)
docker compose up -d p3       # or start just one period
```

On first start, each container automatically:
1. Creates student accounts from the CSV (filtered to that period)
2. Initializes the shared git repo at `/srv/class/network_matrix.git`

### Student connection

```
ssh <username>@<classroom-ip> -p <port>
```

| Period | Port |
|--------|------|
| p1 | 2201 |
| p2 | 2202 |
| p3 | 2203 |
| p4 | 2204 |
| p5 | 2205 |
| p6 | 2206 |
| p7 | 2207 |

Students tell the system who they are once connected:

```bash
git config user.name "First Last"
git config user.email "username@lab.local"
```

Then clone the shared repo:

```bash
git clone /srv/class/network_matrix.git ~/network_matrix
```

### Student self-check

Students run from their SSH session:

```bash
check-lab
```

Reports 3 checks: `.bashrc` variable, seat PROVISIONED in repo, repo cloned correctly.

### Teacher grading

```bash
docker compose exec p3 bash /opt/setup/grade_lab1_1.sh
```

Outputs a CSV: `username, PATH_Status, Flag_Status, Grade%`

### Viewing the shared repo state

```bash
docker compose exec p3 git -C /srv/class/network_matrix.git log --oneline
docker compose exec p3 git -C /srv/class/network_matrix.git show main:network_matrix.json
```

### Emergency repo reset (mid-period)

Only needed if a student corrupts the central repo. Between periods this is not needed — each container starts fresh.

```bash
docker compose exec p3 bash /opt/setup/reset_homes.sh /opt/setup/students.csv
```

Type `yes` at the prompt. Wipes all student `solution/`, `scratch/`, and `network_matrix/` directories, then reseeds the bare repo to its baseline state.

### Stopping

```bash
docker compose stop      # preserves /home volumes (student work saved)
docker compose down      # stops and removes containers (volumes kept)
docker compose down -v   # destroys everything including /home volumes
```

---

## Lab 1.1.3 — Bare Metal

Students work on their real Linux partition. They push a `host-deployment-project/` repo to a classroom Gitea server, where CI automatically grades their git hygiene.

### Gitea installation

On the teacher/classroom server (one-time):

```bash
# Download the binary for your architecture from gitea.io
wget https://dl.gitea.io/gitea/1.21.0/gitea-1.21.0-linux-amd64
chmod +x gitea-1.21.0-linux-amd64
sudo mv gitea-1.21.0-linux-amd64 /usr/local/bin/gitea

# Create service user and directories
sudo adduser --system --shell /bin/bash --group --disabled-password gitea
sudo mkdir -p /var/lib/gitea /etc/gitea
sudo chown gitea:gitea /var/lib/gitea /etc/gitea

# Start (or run as a systemd service)
sudo -u gitea gitea web --port 3000
```

Navigate to `http://<server-ip>:3000` and complete the first-run setup wizard. Create an admin account.

### Act Runner

Required for CI jobs to execute on push:

```bash
# Download gitea-act-runner from gitea.com/gitea/act_runner
# Register it against your Gitea instance
./act_runner register --instance http://localhost:3000 --token <runner-token>
./act_runner daemon
```

Runner tokens: Gitea → Site Administration → Runners → Create Runner.

### Provision student repos

Generate an admin API token: Gitea → Settings → Applications → Generate Token (all scopes).

```bash
cd lab-1.1.3-bare-metal/ci

GITEA_URL=http://192.168.1.50:3000 \
GITEA_TOKEN=<admin-token> \
bash setup_class.sh ../../lab-1.1.2-shared-container/setup/students.csv
```

This creates, per student:
- A Gitea user account (credentials from CSV)
- A private repo at `lab-1-1/<username>`
- Student granted write access to their own repo
- `.gitea/workflows/grade.yml` and `ci/grade_checks.sh` seeded into the repo

### Student push URL

```
http://<gitea-ip>:3000/lab-1-1/<username>
```

Students add the remote and push:

```bash
git remote add origin http://GITEA_IP:3000/lab-1-1/<their-username>
git push -u origin main
```

CI runs automatically on every push to `main`. Results appear in the Gitea Actions tab.

### Student self-grading (local)

From the student's own machine inside `host-deployment-project/`:

```bash
bash ~/path/to/self_grade.sh
```

Requires Docker on the student's machine. Runs pytest checks against their local `.bashrc` in a clean container.

### Teacher batch grading

Pulls all student repos and runs the same grading logic locally:

```bash
cd lab-1.1.3-bare-metal/ci

GITEA_URL=http://192.168.1.50:3000 \
GITEA_TOKEN=<token> \
CLASS_ORG=lab-1-1 \
bash grade_all_students.sh
```

Outputs a timestamped CSV: `lab1_1_3_grades_YYYYMMDD_HHMMSS.csv`

### Grading criteria (5 checks, 20% each)

| # | Check |
|---|-------|
| 1 | `.gitignore` exists in repo root |
| 2 | `.gitignore` contains an exact `^\.env$` line |
| 3 | `.env` not currently tracked by git |
| 4 | `.env` never committed to any branch in history |
| 5 | `env_evidence.txt` contains exactly `LEVEL_4_HOST` |

Check 4 intentionally fails for students who committed `.env` and then removed it with `git rm --cached`. That's the lesson — `git rm --cached` doesn't erase history.

### Updating grading logic

All check logic lives in one file: `ci/grade_checks.sh`. Edit it there and it propagates to both the CI workflow and the teacher batch script automatically. To update already-provisioned student repos, re-run `setup_class.sh` (it skips existing repos — you'd need to push the updated file manually via the Gitea API or re-create the repos).

---

## Troubleshooting

**Students get "WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED" (Lab 1.1.2)**
SSH host keys are baked into the image at build time. This warning appears only if the image was rebuilt. Students clear it with:
```bash
ssh-keygen -R "[classroom-ip]:2202"
```

**`check-lab` Check 2 fails with permission denied (Lab 1.1.2)**
Students can't read the bare repo objects. Verify `init_class_repo.sh` ran at startup:
```bash
docker compose exec p3 ls -la /srv/class/network_matrix.git/objects/
# Should show group = students, permissions = 775
```
If not, fix manually:
```bash
docker compose exec p3 bash /opt/setup/init_class_repo.sh
```

**Gitea CI jobs queue but never run (Lab 1.1.3)**
The act-runner is not registered or not running. Check: Gitea → Site Administration → Runners.

**`setup_class.sh` returns HTTP 403 (Lab 1.1.3)**
The API token lacks admin scope. Regenerate with all scopes checked.

**Students CSV — Windows line endings**
All scripts strip `\r` characters, so Windows-edited CSVs are safe.
