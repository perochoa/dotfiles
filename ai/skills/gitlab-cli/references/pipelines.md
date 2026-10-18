# Pipeline Review and Remediation

## Checking Pipeline Status

```bash
# Status of latest pipeline on current branch
glab ci status

# Get full pipeline details as JSON
glab ci get
glab ci get --pipeline-id=12345
glab ci get --output=json

# List all pipelines
glab ci list
glab ci list --ref=<branch-name>      # for a specific non-main branch

# Filter by status
glab ci list --status=failed
glab ci list --status=running
glab ci list --status=success
glab ci list --status=canceled
glab ci list --status=pending

# Paginate results
glab ci list --per-page=20 --page=1
```

## Viewing Pipeline Jobs

```bash
# Interactive TUI view of pipeline jobs on current branch
glab ci view

# View pipeline for a specific branch or tag
glab ci view main
glab ci view v2.0.0

# View pipeline by ID
glab ci view -p 12345
```

The interactive view lets you navigate jobs with arrow keys and press `t` to tail logs.

## Getting Job Logs

```bash
# Stream a job's log by job ID (follows until completion)
glab ci trace 98765

# Stream by job name (uses latest pipeline on current branch)
glab ci trace "build:docker"

# Stream job on a specific branch (use sparingly; prefer working off current branch)
glab ci trace --branch=feature/my-branch "test:unit"

# Non-interactive log (pipe-friendly)
glab ci trace 98765 | grep -i error
glab ci trace 98765 | tail -100
```

## Identifying Failures

```bash
# 1. Find the failed pipeline
glab ci list --status=failed | head -5

# 2. Get pipeline details to find which jobs failed
glab ci get --pipeline-id=12345 --output=json | jq '.id, .status, .ref'

# 3. View the pipeline to see job statuses
glab ci view -p 12345

# 4. Get all jobs for a pipeline via API (with their status)
glab api /projects/:id/pipelines/12345/jobs | jq '.[] | {id: .id, name: .name, status: .status, stage: .stage}'

# 5. Get only failed jobs
glab api /projects/:id/pipelines/12345/jobs | jq '[.[] | select(.status == "failed") | {id: .id, name: .name, stage: .stage}]'

# 6. Tail the log of a failed job
glab ci trace <job-id>
```

## Retrying and Triggering Pipelines

```bash
# Retry a specific failed job
glab ci retry <job-id>

# Retry a job on a specific project
glab ci retry <job-id> -R owner/repo

# Trigger a manual job
glab ci trigger <job-id>

# Run a new pipeline on the current branch
glab ci run

# Run with variables (current branch)
glab ci run --variables KEY:value --variables DEBUG:true

# Run with variables from JSON file (current branch)
glab ci run --variables-from vars.json

# Lint your .gitlab-ci.yml before running
glab ci lint
glab ci lint .gitlab-ci.yml
```

## Downloading Artifacts

> **Note:** `glab ci artifact` is deprecated. Use `glab job artifact` instead.

```bash
# Download artifacts from the latest pipeline on the current branch
glab job artifact HEAD "job-name"

# Download to a specific directory
glab job artifact HEAD "test:coverage" --path=./coverage-output
```

## Test Reports

```bash
# Get the test report for a pipeline (JUnit XML summary)
glab api /projects/:id/pipelines/12345/test_report

# Pretty print test summary
glab api /projects/:id/pipelines/12345/test_report | jq '{total: .total_count, failed: .failed_count, error: .error_count, skipped: .skipped_count}'

# Get individual test case failures
glab api /projects/:id/pipelines/12345/test_report | jq '.test_suites[].test_cases[] | select(.status == "failed") | {name: .name, classname: .classname, failure_message: .recent_failures[0].failure_message}'

# Get test report summary (lighter endpoint)
glab api /projects/:id/pipelines/12345/test_report_summary
```

## Pipeline Remediation Workflow

### Diagnosing a Failed Pipeline

```bash
# 1. Check current branch pipeline status
glab ci status

# 2. Get the failing pipeline ID
PIPELINE_ID=$(glab ci list --status=failed --output=json | jq -r '.[0].id')
echo "Failed pipeline: $PIPELINE_ID"

# 3. Find which jobs failed
glab api /projects/:id/pipelines/$PIPELINE_ID/jobs | \
  jq '[.[] | select(.status == "failed") | {id: .id, name: .name, stage: .stage}]'

# 4. Read the failing job's log
glab ci trace <failed-job-id>

# 5. Identify the root cause from the log output
# Common patterns to grep for:
glab ci trace <job-id> | grep -E "(ERROR|FAILED|error:|Error:)" | head -20
glab ci trace <job-id> | grep -A5 "FAILED"
```

### Retrying After a Fix

```bash
# After fixing the issue and pushing:
git add . && git commit -m "fix: resolve pipeline failure" && git push

# Trigger a new pipeline
glab ci run

# Monitor it
glab ci status
```

### Retry Without Code Change (Flaky Tests)

```bash
# Find the failed job ID
FAILED_JOB=$(glab api /projects/:id/pipelines/$PIPELINE_ID/jobs | jq -r '[.[] | select(.status == "failed")][0].id')

# Retry just that job
glab ci retry $FAILED_JOB

# Or retry the whole pipeline via API
glab api /projects/:id/pipelines/$PIPELINE_ID/retry --method POST
```

## Pipeline Schedules

```bash
# List scheduled pipelines
glab schedule list

# Run a scheduled pipeline
glab schedule run <schedule-id>
```
