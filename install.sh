#!/bin/sh

set -u
umask 077

PROGRAM=md2pdf-install
VERSION=0.1.0
PREFIX=
DRY_RUN=false
data_stage=
bin_stage=
data_backup=
bin_backup=
data_published=false
bin_published=false
target_lock=
transaction_marker=.md2pdf-transaction.$$
transaction_token="md2pdf-install $$"

print_help() {
  cat <<'EOF'
Usage: ./install.sh [OPTIONS]

Install md2pdf for the current user without sudo.

Options:
      --prefix DIR  Install to DIR/bin and DIR/share/md2pdf.
      --dry-run     Print the installation plan without changing files.
  -h, --help        Show this help and exit.

Without --prefix, the launcher is installed to
${XDG_BIN_HOME:-$HOME/.local/bin} and runtime data to
${XDG_DATA_HOME:-$HOME/.local/share}/md2pdf.
EOF
}

fail() {
  printf '%s: %s\n' "$PROGRAM" "$*" >&2
  exit 1
}

usage_error() {
  printf '%s: %s\n' "$PROGRAM" "$*" >&2
  printf "Try './install.sh --help' for usage.\n" >&2
  exit 2
}

cleanup() {
  if [ -n "$data_stage" ]; then rm -rf "$data_stage"; fi
  if [ -n "$bin_stage" ]; then rm -rf "$bin_stage"; fi
  if [ -n "$target_lock" ]; then rmdir "$target_lock" || printf '%s: cannot release lock: %s\n' "$PROGRAM" "$target_lock" >&2; fi
}

owns_published_data() {
  owner_file=$data_dir/$transaction_marker
  [ -f "$owner_file" ] && [ ! -L "$owner_file" ] || return 1
  IFS= read -r owner_token < "$owner_file" || return 1
  [ "$owner_token" = "$transaction_token" ]
}

rollback_transaction() {
  rollback_failed=false
  if [ "$bin_published" = true ] && ! rm -f "$bin_file"; then
    printf '%s: cannot remove the published launcher: %s\n' "$PROGRAM" "$bin_file" >&2
    rollback_failed=true
  fi
  if [ -n "$bin_backup" ] && [ ! -e "$bin_file" ] && [ ! -L "$bin_file" ] &&
     mv "$bin_backup" "$bin_file"; then
    bin_backup=
  elif [ -n "$bin_backup" ]; then
    printf '%s: cannot restore the previous launcher; backup remains at %s\n' "$PROGRAM" "$bin_backup" >&2
    rollback_failed=true
  fi
  if [ "$data_published" = true ]; then
    if owns_published_data; then
      if ! rm -rf "$data_dir"; then
        printf '%s: cannot remove the published runtime: %s\n' "$PROGRAM" "$data_dir" >&2
        rollback_failed=true
      fi
    else
      printf '%s: refusing to remove an unowned runtime destination: %s\n' "$PROGRAM" "$data_dir" >&2
      rollback_failed=true
    fi
  fi
  if [ -n "$data_backup" ] && [ ! -e "$data_dir" ] && [ ! -L "$data_dir" ] &&
     mv "$data_backup" "$data_dir"; then
    data_backup=
  elif [ -n "$data_backup" ]; then
    printf '%s: cannot restore the previous runtime; backup remains at %s\n' "$PROGRAM" "$data_backup" >&2
    rollback_failed=true
  fi
  data_published=false
  bin_published=false
  [ "$rollback_failed" = false ]
}

signal_exit() {
  status=$1
  trap - 0 HUP INT TERM
  rollback_transaction || status=1
  cleanup
  exit "$status"
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

print_guidance() {
  action=$1
  printf '%s md2pdf %s\n' "$action" "$VERSION"
  printf '  launcher: %s\n' "$bin_file"
  printf '  runtime:  %s\n' "$data_dir"
  printf 'Ensure %s is on PATH.\n' "$bin_dir"
  printf '%s\n' 'Pandoc 3.8+, Typst 0.15+, curl, and suitable fonts are external dependencies.'
  printf '%s\n' 'This installer does not install dependencies, fonts, or system packages.'
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

script_dir=$(CDPATH= cd -P "$(dirname "$0")" 2>/dev/null && pwd -P) ||
  fail "cannot resolve the source directory"
source_launcher=$script_dir/md2pdf
source_data=$script_dir/share/md2pdf
source_uninstaller=$script_dir/uninstall.sh

runtime_files='filters/runtime.lua
filters/citations.lua
typst/template.typ
typst/document.typ
typst/theme.typ
typst/page.typ
typst/profiles/shared.typ
typst/profiles/general.typ
typst/profiles/technical.typ
typst/profiles/report.typ
typst/profiles/academic.typ'

[ -f "$source_launcher" ] && [ -x "$source_launcher" ] ||
  fail "source launcher is missing or not executable: $source_launcher"
[ -f "$source_uninstaller" ] && [ -x "$source_uninstaller" ] ||
  fail "source uninstaller is missing or not executable: $source_uninstaller"
for runtime_file in $runtime_files; do
  [ -r "$source_data/$runtime_file" ] ||
    fail "source runtime file is missing: $runtime_file"
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

if [ "$DRY_RUN" = true ]; then
  print_guidance "Would install"
  exit 0
fi

data_parent=$(dirname "$data_dir")
mkdir -p "$bin_dir" "$data_parent" || fail "cannot create installation directories"
target_lock_candidate=$data_parent/.md2pdf-install.lock
trap cleanup 0
trap 'signal_exit 129' HUP
trap 'signal_exit 130' INT
trap 'signal_exit 143' TERM
mkdir "$target_lock_candidate" || fail "another installation owns the target lock: $target_lock_candidate"
target_lock=$target_lock_candidate

[ ! -L "$data_dir" ] || fail "runtime destination must not be a symbolic link: $data_dir"
if [ -e "$data_dir" ]; then
  [ -d "$data_dir" ] || fail "runtime destination is not a directory: $data_dir"
  marker_matches "$data_dir/.install-manifest" ||
    fail "refusing to replace an unmanaged runtime directory: $data_dir"
fi
[ ! -L "$bin_file" ] || fail "launcher destination must not be a symbolic link: $bin_file"
if [ -e "$bin_file" ] || [ -L "$bin_file" ]; then
  launcher_matches "$bin_file" ||
    fail "refusing to replace an unmanaged launcher: $bin_file"
  [ -e "$data_dir" ] ||
    fail "refusing to replace a launcher without its managed runtime: $bin_file"
fi
for managed_path in filters typst typst/profiles $runtime_files uninstall.sh; do
  [ ! -L "$data_dir/$managed_path" ] ||
    fail "managed runtime destination must not be a symbolic link: $data_dir/$managed_path"
done
[ ! -e "$data_dir/$transaction_marker" ] && [ ! -L "$data_dir/$transaction_marker" ] ||
  fail "transaction marker path already exists: $data_dir/$transaction_marker"

data_stage_candidate=$data_parent/.md2pdf-install.$$
bin_stage_candidate=$bin_dir/.md2pdf-install.$$
data_backup_candidate=$data_parent/.md2pdf-backup.$$
bin_backup_candidate=$bin_dir/.md2pdf-backup.$$
for transaction_path in "$data_stage_candidate" "$bin_stage_candidate" "$data_backup_candidate" "$bin_backup_candidate"; do
  [ ! -e "$transaction_path" ] && [ ! -L "$transaction_path" ] ||
    fail "transaction path already exists: $transaction_path"
done

mkdir "$data_stage_candidate" || fail "cannot stage runtime data"
data_stage=$data_stage_candidate
mkdir "$bin_stage_candidate" || fail "cannot stage the launcher"
bin_stage=$bin_stage_candidate
if [ -d "$data_dir" ]; then
  cp -Rp "$data_dir/." "$data_stage/" || fail "cannot preserve managed runtime contents"
fi
for runtime_file in $runtime_files; do
  runtime_parent=$(dirname "$runtime_file")
  mkdir -p "$data_stage/$runtime_parent" || fail "cannot prepare staged runtime"
  cp -p "$source_data/$runtime_file" "$data_stage/$runtime_file" ||
    fail "cannot stage runtime file: $runtime_file"
done
cp -p "$source_uninstaller" "$data_stage/uninstall.sh" ||
  fail "cannot stage the uninstaller"
printf '%s\n%s\n%s\n' \
  "md2pdf-install $VERSION" "bin=$bin_file" "data=$data_dir" \
  > "$data_stage/.install-manifest" || fail "cannot write the installation marker"
printf '%s\n' "$transaction_token" > "$data_stage/$transaction_marker" ||
  fail "cannot write the transaction marker"
cp -p "$source_launcher" "$bin_stage/md2pdf" || fail "cannot stage the launcher"
find "$data_stage" -type d -exec chmod 755 {} \; || fail "cannot secure runtime directory modes"
find "$data_stage" -type f -exec chmod 644 {} \; || fail "cannot secure runtime file modes"
chmod 755 "$bin_stage/md2pdf" "$data_stage/uninstall.sh" || fail "cannot secure executable modes"

had_data=false
had_bin=false
if [ -d "$data_dir" ]; then
  if mv "$data_dir" "$data_backup_candidate"; then
    data_backup=$data_backup_candidate
  else
    fail "cannot prepare runtime replacement"
  fi
  had_data=true
fi
if ! mv "$data_stage" "$data_dir"; then
  rollback_transaction || :
  fail "cannot publish runtime data"
fi
if ! owns_published_data; then
  data_stage=
  rollback_transaction || :
  fail "runtime destination changed during publication"
fi
data_published=true
data_stage=

[ ! -L "$bin_file" ] || {
  rollback_transaction || :
  fail "launcher destination became a symbolic link: $bin_file"
}
if [ -e "$bin_file" ]; then
  if mv "$bin_file" "$bin_backup_candidate"; then
    bin_backup=$bin_backup_candidate
  else
    rollback_transaction || :
    fail "cannot prepare launcher replacement"
  fi
  had_bin=true
fi
if ! ln "$bin_stage/md2pdf" "$bin_file"; then
  rollback_transaction || :
  fail "cannot publish the launcher"
fi
bin_published=true
rm -rf "$bin_stage" || {
  rollback_transaction || :
  fail "cannot remove launcher staging data"
}
bin_stage=

rm -f "$data_dir/$transaction_marker" || {
  rollback_transaction || :
  fail "cannot finalize runtime publication"
}
data_published=false
bin_published=false
if [ "$had_data" = true ]; then rm -rf "$data_backup" || fail "cannot remove runtime backup"; data_backup=; fi
if [ "$had_bin" = true ]; then rm -f "$bin_backup" || fail "cannot remove launcher backup"; bin_backup=; fi

print_guidance "Installed"
