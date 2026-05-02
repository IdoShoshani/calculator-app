# CLAUDE.md — Calculator App

## Project Overview

Spring Boot REST calculator with a full CI/CD pipeline: GitHub Actions → Docker Hub → AWS EC2 via Terraform.

## Commands

All common tasks are automated via [Task](https://taskfile.dev). Run `task` (no args) to list everything.

```bash
task check          # lint + test + terraform fmt/validate (what CI runs)
task test           # unit tests only
task run            # local Spring Boot dev server (port 8090 by default)
task docker:build   # build Docker image locally
task docker:run     # run Docker image locally
task tf:plan        # terraform plan
task tf:apply       # terraform apply
task tf:destroy     # terraform destroy
task tf:output      # show terraform outputs
```

On Windows use these same commands — Taskfile handles the `mvnw.cmd` vs `./mvnw` switch automatically.

## Architecture

```
src/
  main/java/com/example/calculator/
    CalculatorApplication.java      # Spring Boot entry point
    controller/CalculatorController.java  # REST layer (HTTP ↔ service)
    service/CalculatorService.java        # Pure business logic (testable)
  main/resources/
    application.properties
    static/                         # Frontend UI (index.html, app.js, styles.css)
  test/java/.../service/
    CalculatorServiceTest.java      # Unit tests (5 cases, no HTTP layer)
terraform/
  main.tf         # VPC, subnet, IGW, security group, EC2, SSH key pair
  variables.tf    # All inputs with descriptions and validations
  outputs.tf      # public_ip, app_url, ssh_command, private_key_path
  terraform.tfvars         # Local values (git-ignored — never commit)
  terraform.tfvars.example # Template to copy
  user_data.sh.tpl         # EC2 bootstrap: installs Docker, starts container
.github/workflows/ci-cd.yml  # CI/CD pipeline (3 jobs)
Taskfile.yml                 # All CLI automation
Dockerfile                   # Multi-stage build (JDK builder → JRE runtime)
```

## API Endpoints

| Method | Path | Params | Notes |
|--------|------|--------|-------|
| GET | `/api/calculate/add` | `a`, `b` | |
| GET | `/api/calculate/subtract` | `a`, `b` | |
| GET | `/api/calculate/multiply` | `a`, `b` | |
| GET | `/api/calculate/divide` | `a`, `b` | Returns 400 on divide-by-zero |
| GET | `/actuator/health` | — | Used by Docker HEALTHCHECK |

## CI/CD Pipeline

Three jobs that run sequentially on `push` to `main` (test job also runs on PRs):

```
test → build-and-push → deploy
       (main only)      (main only)
```

**Required GitHub Secrets:**

| Secret | Value |
|--------|-------|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `EC2_HOST` | EC2 public IP (from `task tf:output`) |
| `EC2_USER` | `ubuntu` |
| `EC2_SSH_PRIVATE_KEY` | Contents of `terraform/calculator-key.pem` |

## Terraform Infrastructure

- **No default VPC assumed** — creates its own VPC + subnet + IGW + route table
- **SSH key pair managed by Terraform** — private key saved to `terraform/calculator-key.pem` (git-ignored)
- **SSH restricted by IP** — set `allowed_ssh_ipv4_cidr` or `allowed_ssh_ipv6_cidr` in `terraform.tfvars`; `/0` is rejected by validation
- **AMI resolved dynamically** — always uses latest Ubuntu 22.04 LTS (Canonical account)
- **`user_data_replace_on_change = true`** — changing `docker_image` in tfvars triggers EC2 replacement

### First-time setup

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# edit terraform.tfvars with your values

export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...

task tf:apply
task tf:output   # copy EC2_HOST value to GitHub Secrets
```

After `apply`, copy `terraform/calculator-key.pem` contents into the `EC2_SSH_PRIVATE_KEY` GitHub Secret.

## Docker Image

- **Registry:** Docker Hub (`idoshoshani123/calculator-app`)
- **Tags:** `latest` + `sha-<short-sha>` on every main push
- **Platforms:** `linux/amd64` + `linux/arm64` (multi-arch manifest)
- **Base images:** `eclipse-temurin:21-jdk-alpine` (builder) → `eclipse-temurin:21-jre-alpine` (runtime)
- **Runs as:** non-root user `appuser`

## Git Workflow

- Feature branch per change (`feat/`, `fix/`, `ci/`, `infra/`, `docs/`)
- Squash merge to `main` via PR
- Branch protection: 1 required reviewer, no force push to `main` (`enforce_admins=false` — repo owner can bypass)
- Commit style: [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `ci:`, `infra:`, `docs:`, `chore:`)

## Known Constraints

- **SSH access is IPv6-only by default** — the `terraform.tfvars` has only `allowed_ssh_ipv6_cidr` set. If your IPv6 address changes (e.g., reconnecting to a different network), update the CIDR and run `task tf:apply`.
- **Free-tier EC2** — `t2.micro` in `us-east-1`. The instance has no persistent storage for Docker volumes.
- **No HTTPS** — the app is served over plain HTTP on port 8080. Add an ALB + ACM certificate if TLS is needed.
