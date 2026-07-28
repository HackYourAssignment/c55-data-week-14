#!/usr/bin/env bash
# Week 14 autograder: static analysis only. Live Azure deploys cannot run from
# GitHub Actions without class credentials. The grader checks Bicep shape,
# evidence files, write-up / AI report length, and blocks leaked secrets.
#
# Total points: 100. Passing score: 60.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=.hyf/grader_lib.sh
source "$SCRIPT_DIR/grader_lib.sh"

cat > "$SCRIPT_DIR/score.json" <<'INIT'
{"score": 0, "pass": false, "passingScore": 60}
INIT

score=0
PASSING=60

# ── Level 1 (20 pts): required files exist ──────────────────────────────────
l1=0
required_files=(
  "main.bicep"
  "modules/storage.bicep"
  "docs/deploy_succeeded.txt"
  "docs/what_if.txt"
  "docs/portal_confirm.md"
  "WRITEUP.md"
  "AI_ASSIST.md"
  "README.md"
)
missing=0
for f in "${required_files[@]}"; do
  if [[ -f "$REPO_ROOT/$f" ]]; then
    pass "found $f"
  else
    fail "missing $f"
    missing=$((missing + 1))
  fi
done
if [[ "$missing" -eq 0 ]]; then
  l1=20
fi
score=$((score + l1))
pass "Level 1: required files ($l1/20 pts)"

# ── Level 2 (35 pts): Bicep shape ───────────────────────────────────────────
l2=0
main="$REPO_ROOT/main.bicep"
mod="$REPO_ROOT/modules/storage.bicep"

if [[ -f "$main" ]]; then
  if grep -qE '^param[[:space:]]+' "$main"; then
    l2=$((l2 + 5)); pass "main.bicep declares a param"
  else
    fail "main.bicep has no param declaration"
  fi
  if grep -qE '^output[[:space:]]+' "$main"; then
    l2=$((l2 + 5)); pass "main.bicep declares an output"
  else
    fail "main.bicep has no output declaration"
  fi
  if grep -qE '^@secure\(\)' "$main"; then
    l2=$((l2 + 5)); pass "main.bicep has an @secure() parameter"
  else
    fail "main.bicep is missing @secure() (required even with a dummy value)"
  fi
  if grep -qE '^module[[:space:]]+' "$main"; then
    l2=$((l2 + 10)); pass "main.bicep calls a module"
  else
    fail "main.bicep has no module call — move at least one resource into modules/"
  fi
  # Required pair: storage account + nested blob container (parent/child stack).
  bicep_sources=("$main")
  if compgen -G "$REPO_ROOT/modules/*.bicep" > /dev/null; then
    # shellcheck disable=SC2206
    bicep_sources+=("$REPO_ROOT"/modules/*.bicep)
  fi
  if grep -qhE "Microsoft\\.Storage/storageAccounts@" "${bicep_sources[@]}" 2>/dev/null; then
    l2=$((l2 + 5)); pass "declares a storage account resource"
  else
    fail "missing Microsoft.Storage/storageAccounts resource (expected in modules/storage.bicep)"
  fi
  if grep -qhE "blobServices/containers@|/containers@" "${bicep_sources[@]}" 2>/dev/null; then
    l2=$((l2 + 5)); pass "declares a nested blob container resource"
  else
    fail "missing nested blob container (Microsoft.Storage/.../containers) — account alone is not enough"
  fi
fi

# Module file should not still be a pure TODO stub with zero resources when main calls it —
# still award shape points above; warn if module has no resource.
if [[ -f "$mod" ]] && ! grep -qE '^resource[[:space:]]+' "$mod"; then
  warn "modules/storage.bicep has no resource yet — expected once you finish Task 1"
fi

score=$((score + l2))
pass "Level 2: Bicep shape ($l2/35 pts)"

# ── Level 3 (25 pts): deploy evidence ───────────────────────────────────────
l3=0
deploy="$REPO_ROOT/docs/deploy_succeeded.txt"
whatif="$REPO_ROOT/docs/what_if.txt"
portal="$REPO_ROOT/docs/portal_confirm.md"

if [[ -f "$deploy" ]] && grep -qiE 'Succeeded|provisioningState' "$deploy" && ! grep -q 'Paste the az deployment' "$deploy"; then
  l3=$((l3 + 10)); pass "docs/deploy_succeeded.txt looks like real deploy output"
else
  fail "docs/deploy_succeeded.txt still empty or missing Succeeded/provisioningState"
fi

if [[ -f "$whatif" ]]; then
  # Non-placeholder, reasonably long
  lines=$(grep -cvE '^[[:space:]]*(<!--.*-->)?[[:space:]]*$' "$whatif" || true)
  if [[ "$lines" -ge 3 ]] && ! grep -q 'Paste the az deployment group what-if' "$whatif"; then
    l3=$((l3 + 10)); pass "docs/what_if.txt looks populated"
  else
    fail "docs/what_if.txt still looks like the scaffold placeholder"
  fi
fi

if [[ -f "$portal" ]]; then
  chars=$(wc -c < "$portal" | tr -d ' ')
  if [[ "$chars" -ge 120 ]] && ! grep -q 'Two or three sentences' "$portal"; then
    l3=$((l3 + 5)); pass "docs/portal_confirm.md has student notes"
  else
    fail "docs/portal_confirm.md is still the scaffold stub — write 2-3 sentences from the portal"
  fi
fi

score=$((score + l3))
pass "Level 3: deploy evidence ($l3/25 pts)"

# ── Level 4 (20 pts): write-up + AI report ───────────────────────────────────
l4=0
writeup="$REPO_ROOT/WRITEUP.md"
ai="$REPO_ROOT/AI_ASSIST.md"

if [[ -f "$writeup" ]]; then
  chars=$(wc -c < "$writeup" | tr -d ' ')
  if [[ "$chars" -ge 400 ]] && ! grep -q 'Half a page for a teammate' "$writeup"; then
    l4=$((l4 + 10)); pass "WRITEUP.md looks filled in"
  else
    fail "WRITEUP.md is still too short or still the scaffold stub"
  fi
fi

if [[ -f "$ai" ]]; then
  chars=$(wc -c < "$ai" | tr -d ' ')
  if [[ "$chars" -ge 250 ]] && ! grep -q 'The prompt you gave an LLM' "$ai"; then
    l4=$((l4 + 10)); pass "AI_ASSIST.md looks filled in"
  else
    fail "AI_ASSIST.md is still too short or still the scaffold stub"
  fi
fi

score=$((score + l4))
pass "Level 4: write-up + AI report ($l4/20 pts)"

# ── Blockers: leaked secrets ────────────────────────────────────────────────
# Committed env files / parameter files with secrets / common key patterns.
if [[ -f "$REPO_ROOT/.env" ]]; then
  blocker ".env is committed — remove it, rotate any leaked values, and keep secrets out of git"
fi
while IFS= read -r -d '' f; do
  blocker "committed parameters/secrets file: ${f#"$REPO_ROOT"/} — remove it and rotate any leaked values"
done < <(find "$REPO_ROOT" -type f \( -name '*.parameters.json' -o -name '*secrets*' \) ! -path '*/.git/*' -print0 2>/dev/null)

# Grep common secret shapes in committed text (exclude .hyf and .git)
secret_hits=$(grep -RInE 'AccountKey=|SharedAccessSignature=|BEGIN (RSA |OPENSSH )?PRIVATE KEY|client_secret[[:space:]]*=|[[:space:]]password[[:space:]]*=[[:space:]]*['\''\"][^'\''\"]+['\''\"]' \
  --exclude-dir=.git --exclude-dir=.hyf --exclude-dir=.devcontainer \
  "$REPO_ROOT" 2>/dev/null || true)
if [[ -n "$secret_hits" ]]; then
  blocker "possible hardcoded secret pattern in the repo — remove it and rotate the credential"
  echo "$secret_hits" | head -5 >&2
fi

print_results "Week 14 Autograder"
write_score "$score" "$PASSING"
