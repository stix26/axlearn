# CI Pipeline Documentation

This document describes the comprehensive CI (Continuous Integration) pipeline for the AXLearn project.

## Overview

The CI pipeline is defined in `.github/workflows/ci.yml` and runs automatically on:
- Push to `main` and `develop` branches
- Pull requests to `main` and `develop` branches
- Weekly scheduled security checks (Mondays at 2 AM UTC)

## Pipeline Jobs

### 1. Code Quality & Linting
**Job Name**: `code-quality`
**Purpose**: Ensures code follows style guidelines and best practices

**Checks**:
- **Black**: Code formatting validation
- **isort**: Import statement sorting
- **pylint**: Code quality and style checking
- **pytype**: Static type checking
- **pre-commit**: Runs all pre-commit hooks

### 2. Unit Tests
**Job Name**: `unit-tests`
**Purpose**: Runs the test suite in parallel across 5 groups

**Features**:
- Matrix strategy splits tests across 5 parallel jobs (a, b, c, d, e)
- Collects code coverage data
- Generates JUnit XML reports
- Uploads coverage artifacts for later combination

### 3. Security Checks
**Job Name**: `security`
**Purpose**: Identifies security vulnerabilities and issues

**Tools**:
- **Bandit**: Security linting for Python code
- **Safety**: Checks for known vulnerabilities in dependencies
- **pip-audit**: Additional dependency vulnerability scanning
- Uploads security reports as artifacts

### 4. Docker Build & Test
**Job Name**: `docker`
**Purpose**: Validates Docker image builds and functionality

**Actions**:
- Builds all Docker targets (ci, base, bastion, tpu, gpu)
- Tests basic functionality of base and bastion images
- Ensures Docker images can be created successfully

### 5. Integration Tests
**Job Name**: `integration-tests`
**Purpose**: Runs tests that require multiple components

**Features**:
- Excludes tests requiring Google Cloud login, TPU access, or high CPU
- Collects integration test coverage
- Runs after unit tests complete

### 6. Performance Tests
**Job Name**: `performance`
**Purpose**: Runs performance benchmarks and tests

**Actions**:
- Searches for and runs benchmark files
- Executes performance-related tests
- Provides performance validation

### 7. Documentation Build
**Job Name**: `docs`
**Purpose**: Validates documentation can be built

**Actions**:
- Attempts to build Sphinx documentation
- Validates documentation structure
- Ensures docs are buildable

### 8. Package Build & Test
**Job Name**: `package`
**Purpose**: Validates package can be built and installed

**Actions**:
- Builds Python package using `build`
- Tests package installation
- Validates package functionality
- Uploads built packages as artifacts

### 9. Database & SQL Checks
**Job Name**: `database`
**Purpose**: Validates database-related code and configurations

**Checks**:
- Searches for SQL files
- Identifies database configuration files
- Scans for SQL queries in Python code
- Provides database-related validation

### 10. Dependency Management
**Job Name**: `dependencies`
**Purpose**: Validates dependency management and requirements

**Checks**:
- Generates dependency tree
- Identifies unused dependencies
- Checks for outdated packages
- Validates `pyproject.toml` syntax

### 11. Coverage Report
**Job Name**: `coverage`
**Purpose**: Combines and reports on code coverage

**Actions**:
- Downloads coverage artifacts from unit and integration tests
- Combines coverage data
- Generates comprehensive coverage report
- Uploads combined coverage report

### 12. CI Status
**Job Name**: `status`
**Purpose**: Final status check for the entire pipeline

**Features**:
- Runs after all other jobs complete
- Provides overall pipeline status
- Always runs (even if other jobs fail)

## Artifacts

The pipeline generates several artifacts:
- **Security Reports**: JSON and text reports from security tools
- **Coverage Data**: Individual coverage files from test jobs
- **Coverage Report**: Combined coverage report
- **Package Distribution**: Built Python packages
- **Test Results**: JUnit XML test reports

## Configuration

### Environment Variables
- `PYTHON_VERSION`: Set to '3.10'
- `DOCKER_BUILDKIT`: Set to 1 for Docker builds

### Timeouts
- Most jobs have 15-45 minute timeouts
- Security checks: 20 minutes
- Unit tests: 45 minutes
- Integration tests: 40 minutes

## Monitoring

### GitHub Actions
- View pipeline status in the "Actions" tab
- Download artifacts from completed runs
- Review detailed logs for each job

### Notifications
- Pipeline failures will be visible in pull requests
- Security issues are reported as artifacts
- Coverage reports are available for download

## Customization

### Adding New Jobs
1. Add job definition to `.github/workflows/ci.yml`
2. Update the `status` job dependencies
3. Test locally if possible

### Modifying Existing Jobs
1. Edit the specific job in the workflow file
2. Consider impact on other jobs
3. Test changes in a branch first

### Skipping Jobs
Jobs can be skipped by adding `[skip ci]` to commit messages or by modifying the workflow triggers.

## Troubleshooting

### Common Issues
1. **Timeout Errors**: Increase timeout values for resource-intensive jobs
2. **Dependency Conflicts**: Check `pyproject.toml` for version conflicts
3. **Docker Build Failures**: Verify Dockerfile syntax and dependencies
4. **Test Failures**: Check for environment-specific issues

### Debugging
1. Review job logs in GitHub Actions
2. Download and examine artifacts
3. Test locally with similar environment
4. Check for recent dependency updates

## Best Practices

1. **Keep Jobs Focused**: Each job should have a single, clear purpose
2. **Use Caching**: Leverage GitHub Actions caching for dependencies
3. **Fail Fast**: Jobs should fail quickly if there are obvious issues
4. **Provide Artifacts**: Generate useful artifacts for debugging
5. **Document Changes**: Update this document when modifying the pipeline 