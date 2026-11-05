#!/bin/sh

# Static checks for shell sources, executable modes, and whitespace errors.
# Requires ShellCheck (override the command with SHELLCHECK) and a Git checkout.

set -u
LC_ALL=C
export LC_ALL

ROOT=$(CDPATH= cd -P "$(dirname "$0")/.." && pwd -P)
cd "$ROOT" || exit 1
SHELLCHECK=${SHELLCHECK:-shellcheck}

EXECUTABLES='md2pdf install.sh uninstall.sh install-skill.sh tests/run.sh
tests/skill-installer.sh tests/lint.sh'
SOURCED_FIXTURES='tests/fixtures/bsd-stat tests/fixtures/mock-curl
tests/fixtures/typst-proxy'

passed=0
failed=0

pass() {
  passed=$((passed + 1))
  printf 'ok - %s\n' "$1"
}

fail() {
  failed=$((failed + 1))
  printf 'not ok - %s\n' "$1" >&2
}

for script in $EXECUTABLES $SOURCED_FIXTURES; do
  if sh -n "$script"; then
    pass "$script has valid sh syntax"
  else
    fail "$script has valid sh syntax"
  fi
done

for script in $EXECUTABLES; do
  if [ -x "$script" ]; then
    pass "$script is executable"
  else
    fail "$script is executable"
  fi
done

for script in $SOURCED_FIXTURES; do
  if [ ! -x "$script" ]; then
    pass "$script is not executable"
  else
    fail "$script is not executable"
  fi
done

if command -v "$SHELLCHECK" > /dev/null 2>&1; then
  # shellcheck disable=SC2086 # The script lists are intentionally split.
  if "$SHELLCHECK" $EXECUTABLES $SOURCED_FIXTURES; then
    pass "shell scripts pass ShellCheck"
  else
    fail "shell scripts pass ShellCheck"
  fi
else
  printf '  %s is required; install ShellCheck or set SHELLCHECK\n' \
    "$SHELLCHECK" >&2
  fail "shell scripts pass ShellCheck"
fi

if empty_tree=$(git hash-object -t tree /dev/null 2> /dev/null); then
  if git diff --check "$empty_tree" --; then
    pass "tracked files have no whitespace errors"
  else
    fail "tracked files have no whitespace errors"
  fi
else
  printf '  the whitespace check requires a Git checkout\n' >&2
  fail "tracked files have no whitespace errors"
fi

total=$((passed + failed))
printf '%s checks passed; %s checks failed; %s total\n' "$passed" "$failed" "$total"
[ "$failed" -eq 0 ]
