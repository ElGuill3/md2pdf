#!/bin/sh

set -u

PROGRAM=md2pdf-uninstall
VERSION=0.1.0
PREFIX=
DRY_RUN=false

print_help() {
  cat <<'EOF'
Usage: ./uninstall.sh [OPTIONS]

Remove files installed by md2pdf install.sh without sudo.

Options:
      --prefix DIR  Remove the installation under DIR.
      --dry-run     Print the removal plan without changing files.
  -h, --help        Show this help and exit.

Use the same --prefix or XDG/HOME environment used during installation.
Unrelated files inside the installation directories are preserved.
EOF
}

fail() {
  printf '%s: %s\n' "$PROGRAM" "$*" >&2
  exit 1
}

usage_error() {
  printf '%s: %s\n' "$PROGRAM" "$*" >&2
  printf "Try './uninstall.sh --help' for usage.\n" >&2
  exit 2
}

normalize_safe_path() {
  candidate=$1
  label=$2
  [ -n "$candidate" ] || fail "$label must not be empty"
  case $candidate in
    /*) ;;
    *) fail "$label must be an absolute path: $candidate" ;;
  esac
  while [ "$candidate" != / ] && [ "${candidate%/}" != "$candidate" ]; do
    candidate=${candidate%/}
  done
  [ "$candidate" != / ] || fail "$label must not be the filesystem root"
  case $candidate in
    *'//'*) fail "$label contains an empty path component: $candidate" ;;
    */./*|*/.) fail "$label contains an unsafe '.' component: $candidate" ;;
    */../*|*/..) fail "$label contains an unsafe '..' component: $candidate" ;;
    *'
'*) fail "$label must not contain a newline" ;;
  esac
  printf '%s\n' "$candidate"
}

marker_matches() {
  marker=$1
  [ -f "$marker" ] && [ ! -L "$marker" ] || return 1
  {
    IFS= read -r marker_version || return 1
    IFS= read -r marker_bin || return 1
    IFS= read -r marker_data || return 1
    if IFS= read -r marker_extra; then return 1; fi
    [ "$marker_version" = "md2pdf-install $VERSION" ] &&
      [ "$marker_bin" = "bin=$bin_file" ] &&
      [ "$marker_data" = "data=$data_dir" ]
  } < "$marker"
}

launcher_matches() {
  launcher=$1
  [ -f "$launcher" ] && [ ! -L "$launcher" ] || return 1
  found_program=false
  found_version=false
  found_signature=false
  while IFS= read -r line || [ -n "$line" ]; do
    case $line in
      'PROGRAM=md2pdf') found_program=true ;;
      'VERSION=0.1.0') found_version=true ;;
      "INSTALL_SIGNATURE='md2pdf-public-launcher-0.1.0'") found_signature=true ;;
    esac
  done < "$launcher"
  [ "$found_program" = true ] && [ "$found_version" = true ] &&
    [ "$found_signature" = true ]
}

while [ "$#" -gt 0 ]; do
  case $1 in
    --prefix)
      [ "$#" -ge 2 ] || usage_error "option '--prefix' requires a directory"
      [ -z "$PREFIX" ] || usage_error "prefix was specified more than once"
      PREFIX=$2
      shift 2
      ;;
    --prefix=*)
      [ -z "$PREFIX" ] || usage_error "prefix was specified more than once"
      PREFIX=${1#*=}
      [ -n "$PREFIX" ] || usage_error "option '--prefix' requires a directory"
      shift
      ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) print_help; exit 0 ;;
    --) shift; [ "$#" -eq 0 ] || usage_error "unexpected argument: $1" ;;
    -*) usage_error "unknown option: $1" ;;
    *) usage_error "unexpected argument: $1" ;;
  esac
done

if [ -n "$PREFIX" ]; then
  prefix=$(normalize_safe_path "$PREFIX" "prefix") || exit $?
  bin_dir=$prefix/bin
  data_dir=$prefix/share/md2pdf
else
  [ -n "${HOME:-}" ] || fail "HOME is required when --prefix is not used"
  bin_dir=$(normalize_safe_path "${XDG_BIN_HOME:-$HOME/.local/bin}" "binary directory") || exit $?
  data_home=$(normalize_safe_path "${XDG_DATA_HOME:-$HOME/.local/share}" "data directory") || exit $?
  data_dir=$data_home/md2pdf
fi
bin_file=$bin_dir/md2pdf
marker=$data_dir/.install-manifest

[ ! -L "$data_dir" ] || fail "runtime destination must not be a symbolic link: $data_dir"
marker_matches "$marker" || fail "no matching managed installation found at: $data_dir"
if [ -e "$bin_file" ] || [ -L "$bin_file" ]; then
  launcher_matches "$bin_file" || fail "refusing to remove an unrecognized launcher: $bin_file"
fi

known_files='filters/runtime.lua
filters/citations.lua
typst/template.typ
typst/document.typ
typst/theme.typ
typst/page.typ
typst/profiles/shared.typ
typst/profiles/general.typ
typst/profiles/technical.typ
typst/profiles/report.typ
typst/profiles/academic.typ
uninstall.sh'

for known_file in $known_files; do
  known_path=$data_dir/$known_file
  [ ! -d "$known_path" ] || fail "refusing to remove a directory at known file path: $known_path"
done

if [ "$DRY_RUN" = true ]; then
  printf 'Would remove md2pdf %s known files\n' "$VERSION"
  printf '  launcher: %s\n' "$bin_file"
  printf '  runtime:  %s\n' "$data_dir"
  printf '%s\n' 'Unrelated files and non-empty directories would remain.'
  exit 0
fi

if [ -e "$bin_file" ]; then rm -f "$bin_file" || fail "cannot remove launcher: $bin_file"; fi
for known_file in $known_files; do
  known_path=$data_dir/$known_file
  if [ -e "$known_path" ] || [ -L "$known_path" ]; then
    rm -f "$known_path" || fail "cannot remove installed file: $known_path"
  fi
done
rm -f "$marker" || fail "cannot remove installation marker"

rmdir "$data_dir/typst/profiles" 2>/dev/null || :
rmdir "$data_dir/typst" 2>/dev/null || :
rmdir "$data_dir/filters" 2>/dev/null || :
rmdir "$data_dir" 2>/dev/null || :

printf 'Removed md2pdf %s known files\n' "$VERSION"
printf '%s\n' 'Unrelated files and non-empty directories were preserved.'
