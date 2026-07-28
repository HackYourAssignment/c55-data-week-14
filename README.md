# Week 14 Assignment: Infrastructure as Code (Bicep)

Provision a small Azure stack as code. The required work is Bicep: two (or more)
resources, parameters, a module, `what-if`, portal confirmation, a short write-up,
and an AI-assist report.

The full assignment chapter (with all task instructions) lives in your
HackYourFuture Notion curriculum under Week 14.

> **Cohort C55 hand-in repo.** Fork this repository into your own GitHub account, complete the tasks, then open a pull request **back into this repo**. Keep the headings from `.github/PULL_REQUEST_TEMPLATE.md` — the PR body check enforces them.

## Project structure

```text
data-assignment-week-14/
├── .github/
│   ├── PULL_REQUEST_TEMPLATE.md   Required PR description sections
│   └── workflows/
│       ├── grade-assignment.yml   Triggers the auto-grader on every PR
│       └── pr-body-check.yml      Fails PRs that skip the template
├── .devcontainer/
│   └── devcontainer.json          Codespaces (Azure CLI + Bicep)
├── .hyf/
│   ├── test.sh                    The auto-grader (`bash .hyf/test.sh`)
│   └── grader_lib.sh              Shared helpers
├── main.bicep                     Task 1: entry template
├── modules/
│   └── storage.bicep              Task 1: storage account + nested container
├── docs/
│   ├── deploy_succeeded.txt       Task 1: az deployment group create output
│   ├── what_if.txt                Task 1: az deployment group what-if output
│   └── portal_confirm.md          Task 1: portal confirmation notes
├── WRITEUP.md                     Task 2: half-page teammate write-up
├── AI_ASSIST.md                   Task 4: LLM prompt + your review
└── README.md                      This file
```

## Where to start

| Step | File | Task |
|---|---|---|
| 1 | `main.bicep` + `modules/storage.bicep` | Author and modularize (Task 1) |
| 2 | Azure CLI against `$CLASS_RG` | Deploy + `what-if` + save outputs under `docs/` |
| 3 | Azure portal | Confirm resources; fill `docs/portal_confirm.md` |
| 4 | `WRITEUP.md` | Half-page write-up (Task 2) |
| 5 | `AI_ASSIST.md` | One critically reviewed LLM use (Task 4) |

## Open in Codespaces

Codespaces ships the Azure CLI. Sign in with your HackYourFuture Azure account
targeting the HYF tenant:

```bash
az login --use-device-code --tenant 07a14c4e-d88c-42f7-83b3-13af7e57ff3d
export CLASS_RG=rg-hyf-students   # replace if your teacher gave a different name
az bicep version || az bicep install
```

## Local check before you open a PR

```bash
bash .hyf/test.sh
```

The grader is static only (it cannot reach your Azure subscription). Teachers still
review the live deploy and the evidence files under `docs/`.

When you open the PR into your cohort repo, keep the headings from
`.github/PULL_REQUEST_TEMPLATE.md`. A `pr-body-check` workflow fails the PR if those
sections are missing (common when an AI tool opens the PR with a custom body).

## Secrets

Never commit keys, connection strings, or passwords. Use `@secure()` parameters
or Key Vault references. A leaked secret is an automatic fail.
