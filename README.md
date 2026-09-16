# Serverless Task API (Lambda, API Gateway, DynamoDB)

A fully serverless REST API — Lambda functions behind an HTTP API Gateway, backed by DynamoDB — with no servers, containers, or always-on infrastructure of any kind. Built as a deliberate contrast to the EC2/ASG-based and Kubernetes-based architectures in the companion projects, to demonstrate a genuinely different compute and cost model.

> **Companion projects:** [aws-multi-tier-architecture-terraform](https://github.com/yoder-cloudsec/aws-multi-tier-architecture-terraform) and [k8s-multitier](https://github.com/yoder-cloudsec/k8s-multitier) — those projects are always-on, server-based architectures; this one is event-driven and pay-per-use, with zero idle cost.

## Architecture Overview

```
        Client
          │
          ▼
   ┌─────────────────────┐
   │  API Gateway (HTTP) │
   └──────────┬──────────┘
              │
   ┌──────────┼──────────────────────────┬───────────────────┐
   │          │                          │                   │
   ▼          ▼                          ▼                   ▼
POST /tasks  GET /tasks/{id}      GET /tasks            DELETE /tasks/{id}
   │          │                          │                   │
   ▼          ▼                          ▼                   ▼
create_task  get_task              list_tasks            delete_task
 (Lambda)    (Lambda)               (Lambda)               (Lambda)
   │          │                          │                   │
   └──────────┴──────────────────────────┴───────────────────┘
                          │
                          ▼
                 DynamoDB (tasks-table)
                 PAY_PER_REQUEST billing
```

## What This Project Demonstrates

- **A full CRUD REST API with zero servers** — four Lambda functions (create, get, list, delete) behind an HTTP API Gateway, each scoped to only the DynamoDB permissions it actually needs
- **Infrastructure-as-code packaging of real application code** — Terraform's `archive_file` data source zips Python source automatically at `plan`/`apply` time, with `source_code_hash` ensuring code changes are detected and redeployed, not just infrastructure changes
- **A genuinely different cost model than every other project in this portfolio** — DynamoDB configured with `PAY_PER_REQUEST` billing (not provisioned capacity) specifically to eliminate any idle, hourly-billed component; combined with Lambda and HTTP API Gateway's inherently pay-per-invocation pricing, this architecture has effectively zero cost while idle — no NAT Gateway, no running instance, no reserved throughput ticking regardless of use
- **Real, end-to-end verified request handling** — every endpoint tested via actual HTTP requests (not just Lambda console simulation), including a genuine, non-obvious bug found and fixed via CloudWatch Logs rather than guesswork

## Tech Stack

| Component | Service |
|---|---|
| Compute | AWS Lambda (Python 3.12) |
| API | API Gateway (HTTP API) |
| Data | DynamoDB (on-demand / `PAY_PER_REQUEST`) |
| IAM | Scoped execution role, resource-level DynamoDB permissions |
| Packaging | Terraform `archive_file` data source |

## Key Design Decisions

**Why DynamoDB `PAY_PER_REQUEST` instead of provisioned capacity?**
Provisioned capacity bills hourly for reserved read/write throughput regardless of actual usage, the same "always billing" model as an EC2 instance or NAT Gateway. On-demand billing was chosen specifically to make this architecture's idle cost genuinely zero, not just low, which matters for a project that isn't torn down and rebuilt on the same tight cadence as the always-on projects in this portfolio.

**Why HTTP API instead of REST API (API Gateway)?**
HTTP API is AWS's newer, simpler, and cheaper API Gateway offering, appropriate for a straightforward Lambda-backed proxy integration like this one. REST API offers more configuration surface (request validation, API keys, usage plans) that this project doesn't need.

**Why a shared IAM execution role across all four functions, rather than one role per function?**
All four functions need identical permissions: read/write access to the same single DynamoDB table, nothing else. A shared role avoids duplicating an identical trust and permissions policy four times. If the functions' permission needs diverged later, splitting them would be straightforward.

**Why `Scan` for the list-tasks endpoint, despite its known inefficiency?**
`Scan` reads every item in the table and is a legitimate anti-pattern at real scale. It was used here deliberately for simplicity, with the limitation explicitly acknowledged — a production version would need a query-optimized access pattern (e.g., a secondary index) rather than scanning the full table on every request.

## Debugging Notes (Real Issues Hit During This Build)

**API Gateway base64-encodes the request body under certain conditions.** The first real HTTP request through the API returned a generic `Internal Server Error`. CloudWatch Logs showed a `JSONDecodeError` on an empty-looking string. Adding a debug line to print the raw incoming event revealed the actual cause: the test request was sent via `curl -d`, which defaults to a `Content-Type` of `application/x-www-form-urlencoded` rather than `application/json`. Because of this, API Gateway's HTTP API marked the request `isBase64Encoded: true` and base64-encoded the body defensively. The fix was two-fold: making the Lambda function defensively check `isBase64Encoded` and decode accordingly (so it correctly handles either case), and correcting the test requests to send an explicit `Content-Type: application/json` header, matching how a real client would behave.

## What I'd Add for Production Use

- [ ] Explicit CloudWatch Logs retention policies per function (log groups default to indefinite retention otherwise)
- [ ] Replace the `list-tasks` `Scan` with a query-optimized access pattern as the dataset grows
- [ ] Add an `UPDATE /tasks/{id}` endpoint to complete full CRUD (currently create/read/delete only)
- [ ] Request validation at the API Gateway layer, rather than relying solely on Lambda-side error handling
- [ ] Move from a single shared IAM role toward per-function least-privilege roles if the functions' responsibilities diverge further

## Author's Note

This project was built specifically to demonstrate a different compute and cost model than the rest of this portfolio — no servers, no idle billing, and a fundamentally different failure mode (a function either runs correctly on invocation or it doesn't; there's no "is it still running" question at all). The base64/content-type issue in particular was left in this write-up in full because it's a genuinely realistic problem, not a contrived one and finding it through CloudWatch Logs rather than trial-and-error guessing is the actual skill being demonstrated.
