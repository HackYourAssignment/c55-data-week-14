## What I built
- Bicep entry template: `main.bicep` (params incl. `environment`, `@secure()`, module call, outputs)
- Storage module: `modules/storage.bicep` (storage account + nested `raw` and `curated` containers, Environment tag)
- Deploy evidence: `docs/deploy_succeeded.txt`, `docs/what_if.txt`, `docs/portal_confirm.md`
- Teammate write-up: `WRITEUP.md`
- AI usage: `AI_ASSIST.md`
- (Optional) extras under `docs/optional/`

## How to review
- Bicep: read `main.bicep` and `modules/storage.bicep` (param / output / `@secure()` / module / both nested containers).
- Evidence: `docs/deploy_succeeded.txt` shows `Succeeded`; `docs/what_if.txt` is real CLI output; `docs/portal_confirm.md` names the account, both containers, and the teardown line.
- Write-ups: `WRITEUP.md` and `AI_ASSIST.md`.

## How to run
From a clean clone, with Azure CLI signed into the HYF tenant:

```bash
az login --use-device-code --tenant 07a14c4e-d88c-42f7-83b3-13af7e57ff3d
export CLASS_RG=rg-hyf-students   # replace if your teacher gave a different name
az bicep version || az bicep install
bash .hyf/test.sh
```

Deploy (example: use your own globally unique storage name and never commit the secure value).
This is the post-Task-1 shape; drop `environment=dev` if you have not added that parameter yet,
because Azure rejects a parameter the template does not declare:

```bash
az deployment group create \
  --resource-group "$CLASS_RG" \
  --template-file main.bicep \
  --parameters storageName=<unique-name> environment=dev dbAdminPassword=not-a-real-secret
```

Prerequisite: you can write into `$CLASS_RG` with the HYF student IaC role.

## What reviewers should see (expected results)
Fill in what your deploy actually produced:
- Storage account name: <e.g. sthyfjane01>
- Blob container names: <e.g. raw and curated>
- `provisioningState` in `docs/deploy_succeeded.txt`: <e.g. Succeeded>
- `bash .hyf/test.sh` score: <e.g. 100 / 100, pass=true>
- Teardown: <e.g. deleted account (and nested container) after evidence captured>

## Known limitations / out of scope
- <e.g. optional Airbyte / AI enrichment not attempted>
- Write "none" if everything in the assignment is done and working.

## Self-check
- [ ] `bash .hyf/test.sh` passes
- [ ] Storage account **and** both nested blob containers (`raw`, `curated`) exist(ed) in `$CLASS_RG`
- [ ] `@secure()` present; no credentials / `.env` / `*.parameters.json` committed
- [ ] `docs/what_if.txt` is real CLI output (not a paraphrase)
- [ ] Resources from this assignment were torn down, and `docs/portal_confirm.md` records it (or documents the blocked delete)
