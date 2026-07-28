#!/bin/sh

set -u
LC_ALL=C
export LC_ALL

ROOT=$(CDPATH= cd -P "$(dirname "$0")/.." && pwd -P) || exit 1
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/md2pdf-skill-tests.XXXXXXXX") || exit 1
trap 'rm -rf "$TMP_ROOT"' 0 HUP INT TERM

fail() {
  printf 'not ok - %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'ok - %s\n' "$1"
}

fake_bin=$TMP_ROOT/bin
test_home=$TMP_ROOT/home
codex_home=$test_home/.codex
xdg_config_home=$test_home/.config
claude_config_dir=$test_home/.claude
gemini_cli_home=$test_home/.gemini
mkdir -p "$fake_bin" "$test_home"
for agent in codex opencode claude gemini; do
  printf '#!/bin/sh\nexit 0\n' > "$fake_bin/$agent"
  chmod 755 "$fake_bin/$agent"
done

for agent_root in "$codex_home" "$xdg_config_home" "$claude_config_dir" "$gemini_cli_home"; do
  case $agent_root in
    "$TMP_ROOT"/*) ;;
    *) fail "agent root is confined to the temporary root: $agent_root" ;;
  esac
done

run_all_detected() {
  env HOME="$test_home" PATH="$fake_bin:/usr/bin:/bin" \
    CODEX_HOME="$codex_home" XDG_CONFIG_HOME="$xdg_config_home" \
    CLAUDE_CONFIG_DIR="$claude_config_dir" GEMINI_CLI_HOME="$gemini_cli_home" \
    "$ROOT/install-skill.sh" --all-detected
}

run_all_detected >/dev/null || fail "all-detected installation succeeds"
pass "all-detected installation succeeds"

canonical_skill=$ROOT/skills/md2pdf
payload_list=$TMP_ROOT/skill-payload-files
find "$canonical_skill" -type f -print > "$payload_list" || fail "canonical payload can be enumerated"
[ -s "$payload_list" ] || fail "canonical payload is not empty"

for destination in \
  "$codex_home/skills/md2pdf" \
  "$xdg_config_home/opencode/skills/md2pdf" \
  "$claude_config_dir/skills/md2pdf" \
  "$gemini_cli_home/skills/md2pdf"
do
  [ -L "$destination" ] || fail "destination is a symlink: $destination"
  [ "$(readlink "$destination")" = "$canonical_skill" ] || fail "destination targets canonical skill: $destination"
  while IFS= read -r canonical_file; do
    relative_file=${canonical_file#"$canonical_skill/"}
    cmp "$canonical_file" "$destination/$relative_file" >/dev/null 2>&1 ||
      fail "payload bytes match for $relative_file: $destination"
  done < "$payload_list"
done
pass "all four destinations match every canonical skill payload file"

run_all_detected >/dev/null || fail "reinstallation is idempotent"
pass "reinstallation is idempotent"

collision_home=$TMP_ROOT/collision-home
mkdir -p "$collision_home/.codex/skills/md2pdf"
printf 'keep\n' > "$collision_home/.codex/skills/md2pdf/sentinel"
if "$ROOT/install-skill.sh" --home "$collision_home" --agent codex >/dev/null 2>&1; then
  fail "unmanaged collision is rejected"
fi
[ -f "$collision_home/.codex/skills/md2pdf/sentinel" ] || fail "collision content is preserved"
pass "unmanaged collision is rejected and preserved"

"$ROOT/install-skill.sh" --home "$test_home" --agent codex --uninstall >/dev/null || fail "managed uninstall succeeds"
[ ! -e "$test_home/.codex/skills/md2pdf" ] || fail "managed uninstall removes only the symlink"
pass "managed uninstall removes the selected symlink"

skill=$ROOT/skills/md2pdf/SKILL.md
for heading in '## Activation Contract' '## Hard Rules' '## Decision Gates' '## Execution Steps' '## Output Contract' '## References'; do
  grep -F "$heading" "$skill" >/dev/null 2>&1 || fail "skill contains $heading"
done
grep -E '^description: "Trigger: .+"$' "$skill" >/dev/null 2>&1 || fail "skill description is a single trigger-first line"
grep -F 'CLI as the final validation and rendering authority' "$skill" >/dev/null 2>&1 || fail "skill preserves the CLI authority boundary"
skill_words=$(wc -w < "$skill")
[ "$skill_words" -ge 180 ] && [ "$skill_words" -le 450 ] || fail "skill stays within the 180-450 word budget"
pass "skill contract and required structure are present"

grep -F 'description: "Trigger: create, draft, or write Markdown from scratch;' "$skill" >/dev/null 2>&1 || fail "skill description triggers creation requests"
grep -F 'creating, drafting, or writing Markdown from scratch' "$skill" >/dev/null 2>&1 || fail "activation contract includes creation from scratch"
grep -F '| Create a new document | Creation mode:' "$skill" >/dev/null 2>&1 || fail "skill contains the creation branch"
grep -F '| Change an existing document | Adaptation mode:' "$skill" >/dev/null 2>&1 || fail "skill contains the adaptation branch"
grep -F 'confirm purpose, audience, scope, output, and materially required facts' "$skill" >/dev/null 2>&1 || fail "creation workflow establishes required context"
pass "skill explicitly supports creation and adaptation modes"

printf '7 tests passed; 0 tests failed; 7 total\n'
