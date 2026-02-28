# CI/CD Workflow Documentation

## Pipeline Architecture

The GitHub Actions workflow runs jobs in parallel for maximum efficiency while maintaining logical dependencies.

## Job Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    PARALLEL EXECUTION                        │
│  ┌──────────┐    ┌──────────┐    ┌──────────────────┐      │
│  │   LINT   │    │   TEST   │    │  CodeQL Scan     │      │
│  │  (Ruff)  │    │ (Pytest) │    │  (SAST)          │      │
│  └─────┬────┘    └─────┬────┘    └─────────┬────────┘      │
└────────┼───────────────┼──────────────────┼─────────────────┘
         │               │                  │
         └───────┬───────┘                  │
                 │                          │
         ┌───────▼────────┐                 │
         │     BUILD      │                 │
         │    (Docker)    │                 │
         └───────┬────────┘                 │
                 │                          │
         ┌───────▼────────┐                 │
         │     SCAN       │                 │
         │    (Trivy)     │                 │
         └───────┬────────┘                 │
                 │                          │
         ┌───────┴──────────────────────────▼┐
         │              PUSH                  │
         │    (GitHub Container Registry)     │
         │        (Main branch only)          │
         └────────────────────────────────────┘
```

## Jobs Description

### Stage 1: Parallel Quality & Security Checks

These three jobs run **in parallel** to provide fast feedback:

#### 1. Lint (Ruff)
- **Runtime**: ~30 seconds
- **Purpose**: Code quality and style checks
- **Actions**:
  - Checks Python code formatting
  - Validates code style compliance
  - Detects common bugs and anti-patterns

#### 2. Test (Pytest)
- **Runtime**: ~1-2 minutes
- **Purpose**: Functional testing with PostgreSQL
- **Actions**:
  - Runs unit and integration tests
  - Generates code coverage reports
  - Uploads coverage to Codecov
- **Services**: PostgreSQL 15

#### 3. CodeQL (SAST)
- **Runtime**: ~2-3 minutes
- **Purpose**: Static application security testing
- **Actions**:
  - Scans for security vulnerabilities
  - Detects code quality issues
  - Runs security and quality queries
  - Uploads results to GitHub Security tab

### Stage 2: Build

**Depends on**: Lint + Test

- **Runtime**: ~1-2 minutes
- **Purpose**: Create Docker image
- **Actions**:
  - Builds optimized Docker image
  - Uses layer caching for speed
  - Saves image as artifact
- **Optimization**: GitHub Actions cache

### Stage 3: Security Scan

**Depends on**: Build

- **Runtime**: ~1-2 minutes
- **Purpose**: Container and dependency security scanning
- **Actions**:
  - Scans Docker image for CVEs
  - Scans filesystem for vulnerabilities
  - Uploads SARIF to GitHub Security
  - Fails on CRITICAL/HIGH/MEDIUM issues
- **Tool**: Trivy

### Stage 4: Push

**Depends on**: Scan + CodeQL

- **Runtime**: ~1 minute
- **Purpose**: Publish verified image
- **Conditions**:
  - Only runs on main branch
  - Only on push events (not PRs)
  - All security checks must pass
- **Actions**:
  - Pushes to GitHub Container Registry
  - Tags: latest, branch, commit SHA
  - Generates SBOM attestation

## Parallel Execution Benefits

### Time Savings

**Sequential execution (old approach)**:
```
Lint (30s) → Test (90s) → CodeQL (150s) → Build (90s) → Scan (90s) → Push (60s)
Total: ~8.5 minutes
```

**Parallel execution (new approach)**:
```
[Lint (30s) + Test (90s) + CodeQL (150s)] → Build (90s) → Scan (90s) → Push (60s)
Total: ~6.5 minutes (24% faster)
```

### Developer Experience

- **Faster feedback**: Issues detected in ~2-3 minutes instead of 5-6 minutes
- **Independent failures**: Can see lint, test, and CodeQL results simultaneously
- **Resource efficiency**: Better utilization of GitHub Actions runners

## Trigger Conditions

The workflow runs on:

```yaml
on:
  push:
    branches: [ main, devsecops-infra-scan ]
    paths:
      - 'devsecops/app/**'
      - '.github/workflows/app-devsecops.yaml'

  pull_request:
    branches: [ main ]
    paths:
      - 'devsecops/app/**'
      - '.github/workflows/app-devsecops.yaml'
```

## Security Features

### Multiple Security Layers

1. **CodeQL**: Static analysis for code-level vulnerabilities
2. **Ruff**: Code quality and common bug detection
3. **Trivy Image Scan**: Container vulnerability scanning
4. **Trivy FS Scan**: Dependency vulnerability scanning
5. **SBOM**: Software bill of materials for transparency

### GitHub Security Integration

All security findings are uploaded to GitHub Security tab:
- CodeQL findings under "Code scanning alerts"
- Trivy findings under "Code scanning alerts - Trivy"
- SARIF format for consistent reporting

## Permissions

Jobs use minimal required permissions:

```yaml
lint: default (read)
test: default (read)
codeql: security-events: write
build: default (read)
scan: security-events: write
push: packages: write, contents: read
```

## Failure Handling

### What happens when a job fails?

- **Lint fails**: Build is blocked
- **Test fails**: Build is blocked
- **CodeQL fails**: Push is blocked (but build continues)
- **Build fails**: Scan and push are blocked
- **Scan fails**: Push is blocked
- **Push fails**: No impact on other jobs

### Recovery

All jobs can be re-run individually from the GitHub Actions UI.

## Best Practices Implemented

✅ Parallel execution for independent jobs
✅ Minimal job dependencies
✅ Security scanning at multiple levels
✅ SARIF upload for vulnerability tracking
✅ Layer caching for faster builds
✅ Path filtering to avoid unnecessary runs
✅ Conditional push only on main branch
✅ SBOM generation for supply chain security
✅ Least-privilege permissions
✅ Service containers for integration testing

## Local Testing

Before pushing, test locally:

```bash
# Lint
cd devsecops/app
ruff check .
ruff format --check .

# Test
docker-compose up -d db
pytest -v --cov=.

# Build
docker build -t task-app:local .

# Scan
trivy image task-app:local
trivy fs .
```

## Monitoring

View workflow results:
- **Actions tab**: Real-time job status
- **Security tab**: CodeQL and Trivy findings
- **Packages**: Published container images
- **Codecov**: Test coverage trends
