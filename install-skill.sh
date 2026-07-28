#!/bin/sh

set -u
umask 077

PROGRAM=md2pdf-skill-install
HOME_OVERRIDE=
AGENTS=
ALL_DETECTED=false
UNINSTALL=false

print_help() {
  cat <<'EOF'
Usage: ./install-skill.sh [OPTIONS]

Install the repository's md2pdf skill for supported user-level agents.

Options:
      --all-detected  Install for every detected supported agent.
      --agent NAME    Install for codex, opencode, claude, or gemini. Repeatable.
      --home DIR      Derive all agent directories from DIR instead of HOME/XDG.
      --uninstall     Remove only symlinks managed by this installer.
  -h, --help          Show this help and exit.
EOF
}

fail() {
  printf '%s: %s\n' "$PROGRAM" "$*" >&2
  exit 1
}

usage_error() {
  printf '%s: %s\n' "$PROGRAM" "$*" >&2
  printf "Try './install-skill.sh --help' for usage.\n" >&2
  exit 2
}

add_agent() {
  case " $AGENTS " in
    *" $1 "*) ;;
    *) AGENTS="$AGENTS $1" ;;
  esac
}

normalize_home() {
  candidate=$1
  [ -n "$candidate" ] || fail "home must not be empty"
  case $candidate in
    /*) ;;
    *) fail "home must be an absolute path: $candidate" ;;
  esac
  while [ "$candidate" != / ] && [ "${candidate%/}" != "$candidate" ]; do
    candidate=${candidate%/}
  done
  [ "$candidate" != / ] || fail "home must not be the filesystem root"
  case $candidate in
    */./*|*/.|*/../*|*/..) fail "home contains an unsafe path component: $candidate" ;;
    *'
'*) fail "home must not contain a newline" ;;
  esac
  printf '%s\n' "$candidate"
}

while [ "$#" -gt 0 ]; do
  case $1 in
    --all-detected) ALL_DETECTED=true; shift ;;
    --agent)
      [ "$#" -ge 2 ] || usage_error "option '--agent' requires a name"
      case $2 in codex|opencode|claude|gemini) add_agent "$2" ;; *) usage_error "unsupported agent: $2" ;; esac
      shift 2
      ;;
    --agent=*)
      agent=${1#*=}
      case $agent in codex|opencode|claude|gemini) add_agent "$agent" ;; *) usage_error "unsupported agent: $agent" ;; esac
      shift
      ;;
    --home)
      [ "$#" -ge 2 ] || usage_error "option '--home' requires a directory"
      [ -z "$HOME_OVERRIDE" ] || usage_error "home was specified more than once"
      HOME_OVERRIDE=$2
      shift 2
      ;;
    --home=*)
      [ -z "$HOME_OVERRIDE" ] || usage_error "home was specified more than once"
      HOME_OVERRIDE=${1#*=}
      [ -n "$HOME_OVERRIDE" ] || usage_error "option '--home' requires a directory"
      shift
      ;;
    --uninstall) UNINSTALL=true; shift ;;
    -h|--help) print_help; exit 0 ;;
    -*) usage_error "unknown option: $1" ;;
    *) usage_error "unexpected argument: $1" ;;
  esac
done

script_dir=$(CDPATH= cd -P "$(dirname "$0")" 2>/dev/null && pwd -P) ||
  fail "cannot resolve the repository directory"
source_skill=$script_dir/skills/md2pdf
[ -f "$source_skill/SKILL.md" ] || fail "canonical skill is missing: $source_skill/SKILL.md"

if [ "$ALL_DETECTED" = true ]; then
  for agent in codex opencode claude gemini; do
    if command -v "$agent" >/dev/null 2>&1; then add_agent "$agent"; fi
  done
fi
[ -n "$AGENTS" ] || usage_error "select --all-detected or at least one --agent"

if [ -n "$HOME_OVERRIDE" ]; then
  install_home=$(normalize_home "$HOME_OVERRIDE") || exit $?
  codex_root=$install_home/.codex
  opencode_root=$install_home/.config/opencode
  claude_root=$install_home/.claude
  gemini_root=$install_home/.gemini
else
  [ -n "${HOME:-}" ] || fail "HOME is required"
  install_home=$(normalize_home "$HOME") || exit $?
  codex_root=${CODEX_HOME:-$install_home/.codex}
  opencode_root=${XDG_CONFIG_HOME:-$install_home/.config}/opencode
  claude_root=${CLAUDE_CONFIG_DIR:-$install_home/.claude}
  gemini_root=${GEMINI_CLI_HOME:-$install_home/.gemini}
fi

for agent in $AGENTS; do
  case $agent in
    codex) destination=$codex_root/skills/md2pdf ;;
    opencode) destination=$opencode_root/skills/md2pdf ;;
    claude) destination=$claude_root/skills/md2pdf ;;
    gemini) destination=$gemini_root/skills/md2pdf ;;
  esac

  if [ "$UNINSTALL" = true ]; then
    if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source_skill" ]; then
      rm "$destination" || fail "cannot remove managed symlink: $destination"
      printf 'Removed %s skill: %s\n' "$agent" "$destination"
    elif [ -e "$destination" ] || [ -L "$destination" ]; then
      fail "refusing to remove an unmanaged destination: $destination"
    else
      printf 'Already absent for %s: %s\n' "$agent" "$destination"
    fi
    continue
  fi

  if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source_skill" ]; then
    printf 'Already installed for %s: %s -> %s\n' "$agent" "$destination" "$source_skill"
    continue
  fi
  [ ! -e "$destination" ] && [ ! -L "$destination" ] ||
    fail "refusing to replace an unmanaged destination: $destination"
  mkdir -p "$(dirname "$destination")" || fail "cannot create skill directory for $agent"
  ln -s "$source_skill" "$destination" || fail "cannot install skill for $agent"
  printf 'Installed %s skill: %s -> %s\n' "$agent" "$destination" "$source_skill"
done
