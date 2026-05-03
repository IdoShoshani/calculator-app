# Calculator App

A Spring Boot REST calculator with a browser UI, containerized with Docker and deployed to AWS EC2 via a fully automated GitHub Actions + Terraform pipeline.

---

![Calculator UI](docs/screenshot.png)

---

## Prerequisites

| Tool      | macOS                                                             | Windows                                                           |
| --------- | ----------------------------------------------------------------- | ----------------------------------------------------------------- |
| Java 21+  | `brew install --cask temurin@21`                                  | [adoptium.net](https://adoptium.net)                              |
| Task      | `brew install go-task`                                            | `winget install Task.Task`                                        |
| Docker    | [Docker Desktop](https://www.docker.com/products/docker-desktop/) | [Docker Desktop](https://www.docker.com/products/docker-desktop/) |
| Terraform | `brew install terraform`                                          | `choco install terraform`                                         |
| AWS CLI   | `brew install awscli`                                             | `choco install awscli`                                            |

---

## Run Locally

```bash
task run
```

Opens on `http://localhost:8090`. Run `task --list` to see all available commands.

### Unit Tests

```bash
task test
```

---

## Run with Docker

```bash
task docker:build
task docker:run
```

Opens on `http://localhost:8080`.

---

## API

| Method | Path                      | Params   | Response           |
| ------ | ------------------------- | -------- | ------------------ |
| GET    | `/`                       | —        | Browser UI         |
| GET    | `/api/calculate/add`      | `a`, `b` | `{"result": 7.0}`  |
| GET    | `/api/calculate/subtract` | `a`, `b` | `{"result": 1.0}`  |
| GET    | `/api/calculate/multiply` | `a`, `b` | `{"result": 12.0}` |
| GET    | `/api/calculate/divide`   | `a`, `b` | `{"result": 2.5}`  |
| GET    | `/actuator/health`        | —        | `{"status": "UP"}` |

`/divide` returns HTTP 400 with `{"error": "Division by zero"}` when `b=0`.

**Example:**

```bash
curl "http://localhost:8090/api/calculate/add?a=3&b=4"
# {"result":7.0}
```

---

## CI/CD Pipeline

Every push to `main` runs three sequential jobs:

```text
test → build-and-push → deploy
        (main only)     (main only)
```

| Job              | Trigger          | What it does                                              |
| ---------------- | ---------------- | --------------------------------------------------------- |
| `test`           | all pushes & PRs | Runs `task check`: lint + unit tests + Terraform validate |
| `build-and-push` | push to `main`   | Builds multi-arch Docker image, pushes to Docker Hub      |
| `deploy`         | push to `main`   | Deploys to EC2 via AWS SSM (no SSH required)              |

### Required GitHub Secrets

**Settings → Secrets and variables → Actions:**

| Secret                  | Value                   |
| ----------------------- | ----------------------- |
| `DOCKERHUB_USERNAME`    | Docker Hub username     |
| `DOCKERHUB_TOKEN`       | Docker Hub access token |
| `AWS_ACCESS_KEY_ID`     | AWS IAM access key      |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret key      |

---

## Infrastructure

Terraform provisions a VPC, subnet, internet gateway, security group (port 8080 only — no SSH), and a `t2.micro` EC2 instance on Ubuntu 22.04. Remote access is via **AWS SSM Session Manager**.

### First-time deploy

```bash
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...

cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# edit: set docker_image = "yourdockerhubuser/calculator-app:latest"

task tf:init
task tf:apply

task tf:output -- app_url   # copy the URL once provisioning is done
```

> Wait ~60 seconds after `apply` for the EC2 bootstrap script to finish.

### Tear down

```bash
task tf:destroy
```

---

## Project Structure

```text
calculator-app/
├── .github/workflows/ci-cd.yml      # 3-job pipeline: test → build → deploy
├── src/
│   ├── main/java/com/example/calculator/
│   │   ├── CalculatorApplication.java
│   │   ├── controller/CalculatorController.java
│   │   └── service/CalculatorService.java
│   ├── main/resources/
│   │   ├── application.properties
│   │   └── static/                  # Browser UI (index.html, app.js, styles.css)
│   └── test/java/.../service/
│       └── CalculatorServiceTest.java
├── terraform/
│   ├── main.tf                      # VPC, SG, EC2, IAM
│   ├── variables.tf
│   ├── outputs.tf
│   ├── user_data.sh.tpl             # EC2 bootstrap: installs Docker, starts container
│   └── terraform.tfvars.example
├── docs/screenshot.png
├── Dockerfile                       # Multi-stage: JDK builder → JRE runtime
├── Taskfile.yml
└── pom.xml
```
