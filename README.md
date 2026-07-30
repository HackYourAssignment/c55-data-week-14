# Week 14 Assignment: Infrastructure as Code (Bicep)

Extend a Chapter 4–complete Bicep starter (storage account + nested `raw`
container) with an environment tag and a second `curated` container, then
deploy, preview with `what-if`, confirm in the portal, and write it up.

The full assignment chapter (with all task instructions) lives in your
HackYourFuture Notion curriculum under Week 14.

> **Cohort C55 hand-in repo.** Fork this repository into your own GitHub account, complete the tasks, then open a pull request **back into this repo**. Keep the headings from `.github/PULL_REQUEST_TEMPLATE.md` — the PR body check enforces them.

## Project structure

```text
c55-data-week-14/
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
├── main.bicep                     Starter (Ch4 end state) — Task 1–2: extend
├── modules/
│   └── storage.bicep              Starter: storage + nested `raw` — extend
├── docs/
│   ├── deploy_succeeded.txt       Task 3: az deployment group create output
│   ├── what_if.txt                Task 3: az deployment group what-if output
│   ├── portal_confirm.md          Task 3: portal confirmation notes
│   └── optional/                  Task 6: optional CI what-if evidence
├── WRITEUP.md                     Task 4: half-page teammate write-up
├── AI_ASSIST.md                   Task 5: LLM prompt + your review
└── README.md                      This file
```

## Where to start

| Step | File | Task |
|---|---|---|
| 1 | `main.bicep` + `modules/storage.bicep` | Extend with `environment` param + Environment tags |
| 2 | `modules/storage.bicep` | Keep `raw`; add nested container `curated` |
| 3 | Azure CLI + portal → `docs/` | Deploy + `what-if` + portal evidence |
| 4 | `WRITEUP.md` | Half-page write-up |
| 5 | `AI_ASSIST.md` | One critically reviewed LLM use |
| 6 | `.github/workflows/bicep.yml` + `docs/optional/` | Optional CI preview (bonus) |

When you are done, tear down every resource this assignment created (delete the
storage account; nested containers go with it). Teardown is part of the
guidelines, not a separate graded file.

Do **not** replace the starter with a paste from `azure-bicep-reference`
`*-solution` branches — extend what is already here.

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
review the live deploy and the evidence files under `docs/`. On a fresh clone the
starter should clear the Level 2 *baseline* checks; environment tags and `curated`
are the extensions the grader awards next.

When you open the PR into your cohort repo, keep the headings from
`.github/PULL_REQUEST_TEMPLATE.md`. A `pr-body-check` workflow fails the PR if those
sections are missing (common when an AI tool opens the PR with a custom body).

## Secrets

Never commit keys, connection strings, or passwords. Use `@secure()` parameters
or Key Vault references. A leaked secret is an automatic fail.
