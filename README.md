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
| Docker | [Docker Desktop](https://www.docker.com/products/docker-desktop/) | [Docker Desktop](https://www.docker.com/products/docker-desktop/) |
| Terraform | `brew install terraform` | `choco install terraform` |
| AWS CLI | `brew install awscli` | `choco install awscli` |
| GitHub CLI | `brew install gh` | `choco install gh` |

---

## 1 — Run locally

**macOS / Linux:**
```bash
./mvnw spring-boot:run
```

**Windows:**
```cmd
mvnw.cmd spring-boot:run
```

Then:
```bash
curl "http://localhost:8080/api/calculate/add?a=3&b=4"
# → {"result":7.0}
```

### Run unit tests

```bash
# macOS / Linux
./mvnw test

# Windows
mvnw.cmd test
```

---

## 2 — Run with Docker

```bash
# Build
docker build -t calculator-app .

# Run
docker run -p 8080:8080 calculator-app

# Test
curl "http://localhost:8080/api/calculate/multiply?a=6&b=7"
# → {"result":42.0}
```

---

## 3 — CI/CD Pipeline (GitHub Actions)

The pipeline in [`.github/workflows/ci-cd.yml`](.github/workflows/ci-cd.yml) runs automatically:

| Job | Trigger | Action |
|-----|---------|--------|
| `test` | every push & PR | Runs `./mvnw test` with Maven cache |
| `build-and-push` | push to `main` only | Builds Docker image, pushes to Docker Hub with `latest` + `sha-*` tags |
| `deploy` | push to `main` only | SSH into EC2, zero-downtime container swap |

### Required GitHub Secrets

Go to **Settings → Secrets and variables → Actions** and add:

| Secret | Value |
|--------|-------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token (create at hub.docker.com → Account Settings → Security) |
| `EC2_HOST` | Public IP from `terraform output public_ip` |
| `EC2_USER` | `ubuntu` |
| `EC2_SSH_PRIVATE_KEY` | Full contents of your `.pem` key file |

---

## 4 — Provision infrastructure with Terraform

### AWS credentials

```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
```

### Create an EC2 key pair (first time only)

```bash
aws ec2 create-key-pair --key-name calculator-key \
  --query 'KeyMaterial' --output text > calculator-key.pem
chmod 400 calculator-key.pem   # macOS/Linux only
```

### Deploy

```bash
cd terraform

# Copy and edit the example vars file
cp terraform.tfvars.example terraform.tfvars
# Set: ssh_key_name = "calculator-key"
#      docker_image = "yourdockerhubuser/calculator-app:latest"

terraform init
terraform plan
terraform apply
```

### Get the app URL

```bash
terraform output app_url
# → http://<public-ip>:8080/api/calculate
```

> **Note:** After `terraform apply`, wait ~60 seconds for the EC2 user data script to finish installing Docker and pulling the image.

### Tear down

```bash
terraform destroy
```

---

## Project structure

```
calculator-app/
├── .github/workflows/ci-cd.yml   # GitHub Actions pipeline
├── src/
│   ├── main/java/com/example/calculator/
│   │   ├── CalculatorApplication.java
│   │   ├── controller/CalculatorController.java
│   │   └── service/CalculatorService.java
│   ├── main/resources/application.properties
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
