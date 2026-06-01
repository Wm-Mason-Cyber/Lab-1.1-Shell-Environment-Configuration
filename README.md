# Lab 1.1 — Git-Conflicts-Secrets

AP Cybersecurity Unit 1 lab. Students configure shell environments, manipulate `.bashrc`, practice `git` branching and conflict resolution, and learn why secrets must never be committed to version control.

The lab runs at three escalating risk levels. Students complete all three, with each level raising the stakes until they work on their actual machine.

---

## Lab Levels

| Level | Name | Risk | Environment | Core Skill |
|-------|------|------|-------------|------------|
| [1.1.1](lab-1.1.1-sandbox-sandbox/) | Sandbox | Zero | Isolated Docker container per student | Git branching + merge conflict |
| [1.1.2](lab-1.1.2-shared-container/) | Shared Container | Medium | One SSH container per class period | Shared-repo race condition + conflict |
| [1.1.3](lab-1.1.3-bare-metal/) | Bare Metal | High | Student's real Linux partition | `.gitignore`, secret leakage, Gitea CI |

---

## Architecture Overview

```
CLASSROOM NETWORK (air-gapped or local)
│
├── TEACHER MACHINE
│   ├── Docker host (Lab 1.1.1 & 1.1.2)
│   │   ├── lab111-sandbox containers  (ports 2001–2100+ per period)
│   │   └── lab112-p1..p7 containers   (ports 2201–2207)
│   │
│   └── Gitea server (Lab 1.1.3)       (port 3000)
│       └── org: lab-1-1
│           ├── <username>/            (one repo per student)
│           └── CI: grade_checks.sh runs on every push
│
└── STUDENT WORKSTATIONS (bare-metal Linux)
    ├── SSH → lab112 container         (Lab 1.1.2)
    ├── git push → Gitea               (Lab 1.1.3)
    └── self-grade scripts run locally
```

---

## Grading Summary

| Level | Student Self-Check | Teacher Grading |
|-------|--------------------|-----------------|
| 1.1.1 | `submit-lab` (pytest inside container) | `/var/grading_output/results.json` per student |
| 1.1.2 | `check-lab` (SSH session, 3 checks) | `bash /opt/setup/grade_lab1_1.sh` inside container |
| 1.1.3 | `bash self_grade.sh` (Docker + pytest locally) | `ci/grade_all_students.sh` pulls all Gitea repos |

---

## Repository Structure

```
Lab-1.1-Shell-Environment-Configuration/
│
├── lab-1.1.1-sandbox-sandbox/
│   ├── Dockerfile              # Per-student container image
│   ├── orchestrate_labs.py     # Spin up containers from a roster CSV
│   └── test_lab1_1.py          # Automated pytest grading suite
│
├── lab-1.1.2-shared-container/
│   ├── Dockerfile              # Shared period container image
│   ├── compose.yaml            # 7-period docker compose (p1–p7, ports 2201–2207)
│   └── setup/
│       ├── students.csv.example
│       ├── create_users.sh     # Provision student accounts from CSV
│       ├── entrypoint.sh       # Container startup (users + repo init)
│       ├── init_class_repo.sh  # Creates /srv/class/network_matrix.git
│       ├── network_matrix.json # 30-seat allocation matrix (A1–E6)
│       ├── check_lab.sh        # → /usr/local/bin/check-lab (student self-check)
│       ├── grade_lab1_1.sh     # Teacher grading script (run as root in container)
│       └── reset_homes.sh      # Emergency mid-period repo + home reset
│
└── lab-1.1.3-bare-metal/
    ├── self_grade.sh           # Student local self-grader (Docker + pytest)
    └── ci/
        ├── grade_checks.sh     # SINGLE SOURCE: all 5 grading checks
        ├── grade.yml           # Gitea Actions workflow (seeded into student repos)
        ├── grade_all_students.sh  # Teacher batch grader (clones all repos)
        └── setup_class.sh      # One-time Gitea provisioning from CSV
```

---

## Quick Reference

**Lab 1.1.2 — start all periods:**
```bash
cd lab-1.1.2-shared-container
cp setup/students.csv.example setup/students.csv   # fill in real data
docker compose build
docker compose up -d
```

**Lab 1.1.2 — grade a period:**
```bash
docker compose exec p3 bash /opt/setup/grade_lab1_1.sh
```

**Lab 1.1.3 — provision Gitea repos:**
```bash
cd lab-1.1.3-bare-metal/ci
GITEA_URL=http://192.168.1.50:3000 GITEA_TOKEN=<token> bash setup_class.sh students.csv
```

**Lab 1.1.3 — batch grade all students:**
```bash
GITEA_URL=http://192.168.1.50:3000 GITEA_TOKEN=<token> CLASS_ORG=lab-1-1 bash ci/grade_all_students.sh
```

See [TEACHER_SETUP.md](TEACHER_SETUP.md) for full setup instructions.
