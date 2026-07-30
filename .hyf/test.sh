#!/usr/bin/env bash
# Week 14 autograder: static analysis only. Live Azure deploys cannot run from
# GitHub Actions without class credentials. The grader checks Bicep shape,
# evidence files, write-up / AI report length, and blocks leaked secrets.
#
# Starter is Chapter 4–complete (storage module + nested `raw` container).
# Level 2 grades EXTENSIONS on that starter: environment tags + second container.
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

# ── Level 2 (35 pts): Ch4 baseline kept + extensions ────────────────────────
# Baseline (20): @secure, module, storageAccounts, ≥1 nested container.
# Extensions (15→20 listed): environment param (5) + tags wiring (5) + curated (10).
# Point math: 20+5+5+10=40 raw; curated is the 10-pt extension and L2 caps at 35
# by awarding baseline container as required-fail without double-counting past 35:
#   awarded = @secure5 + module5 + storage5 + container5 + env5 + tags5 + curated10
#   then min(l2, 35). Fresh starter scores 20/35 (baseline only).
l2=0
main="$REPO_ROOT/main.bicep"
mod="$REPO_ROOT/modules/storage.bicep"

bicep_sources=()
if [[ -f "$main" ]]; then
  bicep_sources+=("$main")
fi
if compgen -G "$REPO_ROOT/modules/*.bicep" > /dev/null; then
  # shellcheck disable=SC2206
  bicep_sources+=("$REPO_ROOT"/modules/*.bicep)
fi

if [[ -f "$main" ]]; then
  # --- Baseline (keep from Ch4 starter) ---
  if grep -qE '^@secure\(\)' "$main"; then
    l2=$((l2 + 5)); pass "main.bicep has an @secure() parameter"
  else
    fail "main.bicep is missing @secure() (required even with a dummy value)"
  fi
  if grep -qE '^module[[:space:]]+' "$main"; then
    l2=$((l2 + 5)); pass "main.bicep calls a module"
  else
    fail "main.bicep has no module call — keep the modules/storage.bicep call from the starter"
  fi
fi

if [[ "${#bicep_sources[@]}" -gt 0 ]]; then
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

  # --- Extensions (Task 1–2) ---
  if grep -qiE '^param[[:space:]]+environment[[:space:]]' "$main" 2>/dev/null; then
    l2=$((l2 + 5)); pass "main.bicep declares param environment"
  else
    fail "main.bicep missing param environment (Task 1)"
  fi

  # Tags wiring: param environment + a real `tags:` assignment (not comment-only)
  if grep -qiE '^param[[:space:]]+environment[[:space:]]' "$main" 2>/dev/null \
    && grep -qhE '^[[:space:]]*tags:' "${bicep_sources[@]}" 2>/dev/null; then
    l2=$((l2 + 5)); pass "environment tag wiring present (param environment + tags:)"
  else
    fail "missing Environment tag wiring — pass tags from main into the module (Task 1)"
  fi

  container_count=$(grep -hE "blobServices/containers@|/containers@" "${bicep_sources[@]}" 2>/dev/null | wc -l | tr -d ' ')
  has_curated=false
  if grep -qhE "['\"]curated['\"]" "${bicep_sources[@]}" 2>/dev/null; then
    has_curated=true
  fi
  if [[ "$container_count" -ge 2 ]] || [[ "$has_curated" == true ]]; then
    l2=$((l2 + 10)); pass "second nested container (curated) present"
  else
    fail "need a second nested container named curated (keep raw; Task 2)"
  fi

  if [[ "$container_count" -lt 2 ]]; then
    warn "only $container_count nested container resource(s) — Task 2 expects raw + curated (count >= 2)"
  fi
fi

# Raw check sum can be 40; L2 bucket is 35.
if [[ "$l2" -gt 35 ]]; then
  l2=35
fi

score=$((score + l2))
pass "Level 2: Bicep baseline + extensions ($l2/35 pts)"

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
