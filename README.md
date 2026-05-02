# Calculator App

A simple REST calculator built with **Spring Boot 3.2** and **Java 21**, containerized with Docker, and deployed to AWS via a fully automated CI/CD pipeline.

> DevOps home assignment demonstrating: GitHub Actions, Docker (multi-stage build), and Terraform IaC.

---

## Architecture

```
Developer push to main
        │
        ▼
┌─────────────────────────────┐
│   GitHub Actions Pipeline   │
│  1. test  (all branches)    │
│  2. build & push → Docker Hub│
│  3. deploy via SSH → EC2    │
└─────────────────────────────┘
        │
        ▼
┌────────────────┐     ┌──────────────────────────┐
│   Docker Hub   │────▶│  AWS EC2 (t2.micro)       │
│  calculator-app│     │  Ubuntu 22.04 + Docker    │
└────────────────┘     │  :8080 → calculator-app   │
                       └──────────────────────────┘
```

## API Endpoints

| Method | Path | Params | Example Response |
|--------|------|--------|-----------------|
| GET | `/` | - | Browser calculator UI |
| GET | `/api/calculate/add` | `a`, `b` | `{"result": 7.0}` |
| GET | `/api/calculate/subtract` | `a`, `b` | `{"result": 1.0}` |
| GET | `/api/calculate/multiply` | `a`, `b` | `{"result": 12.0}` |
| GET | `/api/calculate/divide` | `a`, `b` | `{"result": 2.5}` |
| GET | `/actuator/health` | — | `{"status": "UP"}` |

`/divide` returns HTTP 400 `{"error": "Division by zero"}` when `b=0`.

---

## Prerequisites

| Tool | macOS | Windows |
|------|-------|---------|
| Java 21+ | `brew install --cask temurin@21` | [adoptium.net](https://adoptium.net) |
| Task | `brew install go-task` | `winget install Task.Task` |
| Docker | [Docker Desktop](https://www.docker.com/products/docker-desktop/) | [Docker Desktop](https://www.docker.com/products/docker-desktop/) |
| Terraform | `brew install terraform` | `choco install terraform` |
| AWS CLI | `brew install awscli` | `choco install awscli` |
| GitHub CLI | `brew install gh` | `choco install gh` |

---

## 1 — Task-first workflow

The repository ships with a root [`Taskfile.yml`](Taskfile.yml), so the recommended way to work with it is through `task`.

```bash
task --list
```

Common commands:

```bash
task run
task test
task package
task docker:build
task docker:run
task tf:init
task tf:plan
task tf:apply
task tf:destroy
task check
```

You can override variables from the command line when needed:

```bash
task docker:build DOCKER_IMAGE=yourdockerhubuser/calculator-app:latest
task docker:run DOCKER_IMAGE=yourdockerhubuser/calculator-app:latest HOST_PORT=8081
SERVER_PORT=8090 task run
task tf:plan -- -out=tfplan
```

---

## 2 — Run locally

```bash
task run
```

Then:
```bash
Visit http://localhost:8090/ in your browser
```

### Run unit tests

```bash
task test
```

---

## 3 — Run with Docker

```bash
# Build
task docker:build

# Run
task docker:run

# Open
Visit http://localhost:8090/ in your browser
```

---

## 4 — CI/CD Pipeline (GitHub Actions)

The pipeline in [`.github/workflows/ci-cd.yml`](.github/workflows/ci-cd.yml) runs automatically:

| Job | Trigger | Action |
|-----|---------|--------|
| `test` | every push & PR | Installs Terraform and Task, then runs `task check` with Maven cache |
| `build-and-push` | push to `main` only | Builds Docker image, pushes to Docker Hub with `latest` + `sha-*` tags |
| `deploy` | push to `main` only | SSH into EC2, zero-downtime container swap |

### Required GitHub Secrets

Go to **Settings → Secrets and variables → Actions** and add:

| Secret | Value |
|--------|-------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token (create at hub.docker.com → Account Settings → Security) |
| `EC2_HOST` | Public IP from `task tf:output -- public_ip` |
| `EC2_USER` | `ubuntu` |
| `EC2_SSH_PRIVATE_KEY` | Full contents of the generated `.pem` file from `task tf:output -- private_key_path` |

---

## 5 — Provision infrastructure with Terraform

### AWS credentials

```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
```

### EC2 SSH key pair

Terraform generates the EC2 key pair automatically and writes the private key to a local `.pem` file next to the Terraform configuration.

### Deploy

```bash
# Copy and edit the example vars file
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Set: docker_image = "yourdockerhubuser/calculator-app:latest"

task tf:init
task tf:plan
task tf:apply
```

### Get the app URL

```bash
task tf:output -- app_url
# → http://<public-ip>:8080/api/calculate
```

> **Note:** After `task tf:apply`, wait ~60 seconds for the EC2 user data script to finish installing Docker and pulling the image.

### Tear down

```bash
task tf:destroy
```

---

## Project structure

```
calculator-app/
├── Taskfile.yml                   # Top-level task runner commands
├── .github/workflows/ci-cd.yml   # GitHub Actions pipeline
├── src/
│   ├── main/java/com/example/calculator/
│   │   ├── CalculatorApplication.java
│   │   ├── controller/CalculatorController.java
│   │   └── service/CalculatorService.java
│   ├── main/resources/application.properties
│   ├── main/resources/static/
│   │   ├── index.html             # Browser calculator UI
│   │   ├── styles.css             # UI styling
│   │   └── app.js                 # UI logic
│   └── test/java/com/example/calculator/service/
│       └── CalculatorServiceTest.java
├── terraform/
│   ├── main.tf                   # EC2 + security group
│   ├── variables.tf
│   ├── outputs.tf
│   ├── user_data.sh.tpl          # Docker install + container start on boot
│   └── terraform.tfvars.example
├── Dockerfile                    # Multi-stage build (JDK builder → JRE runtime)
├── pom.xml
└── README.md
```
