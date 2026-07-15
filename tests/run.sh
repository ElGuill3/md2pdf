#!/bin/sh

set -u
LC_ALL=C
export LC_ALL

ROOT=$(CDPATH= cd -P "$(dirname "$0")/.." && pwd -P)
CLI=$ROOT/md2pdf
DATA=$ROOT/share/md2pdf
FIXTURES=$ROOT/tests/fixtures
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/md2pdf-tests.XXXXXXXX") || exit 1
SOURCE=$TMP_ROOT/source
OUTPUT=$TMP_ROOT/output
mkdir -p "$SOURCE" "$OUTPUT"
cp -R "$FIXTURES/." "$SOURCE/"
unset MD2PDF_DATA_DIR

passed=0
failed=0
last_stdout=
last_stderr=

cleanup() {
  rm -rf "$TMP_ROOT"
}

signal_exit() {
  signal_status=$1
  trap - 0 HUP INT TERM
  cleanup
  exit "$signal_status"
}

trap cleanup 0
trap 'signal_exit 129' HUP
trap 'signal_exit 130' INT
trap 'signal_exit 143' TERM

pass() {
  passed=$((passed + 1))
  printf 'ok - %s\n' "$1"
}

fail() {
  failed=$((failed + 1))
  printf 'not ok - %s\n' "$1" >&2
  if [ -n "$last_stderr" ] && [ -s "$last_stderr" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      printf '  %s\n' "$line" >&2
    done < "$last_stderr"
  fi
}

run_status() {
  test_name=$1
  expected=$2
  shift 2
  command_id=$((passed + failed + 1))
  last_stdout=$TMP_ROOT/command-$command_id.stdout
  last_stderr=$TMP_ROOT/command-$command_id.stderr
  "$@" > "$last_stdout" 2> "$last_stderr"
  actual=$?
  if [ "$actual" -eq "$expected" ]; then
    pass "$test_name"
    return 0
  fi
  printf '  expected exit %s, received %s\n' "$expected" "$actual" >&2
  fail "$test_name"
  return 1
}

assert_contains() {
  test_name=$1
  needle=$2
  file=$3
  last_stderr=
  if grep -F "$needle" "$file" >/dev/null 2>&1; then
    pass "$test_name"
  else
    printf '  missing text: %s\n' "$needle" >&2
    fail "$test_name"
  fi
}

assert_not_contains() {
  test_name=$1
  needle=$2
  file=$3
  last_stderr=
  if grep -F "$needle" "$file" >/dev/null 2>&1; then
    printf '  unexpected text: %s\n' "$needle" >&2
    fail "$test_name"
  else
    pass "$test_name"
  fi
}

assert_absent() {
  test_name=$1
  file=$2
  last_stderr=
  if [ ! -e "$file" ]; then pass "$test_name"; else fail "$test_name"; fi
}

for dependency in pandoc typst pdfinfo pdftotext pdftoppm; do
  if ! command -v "$dependency" >/dev/null 2>&1; then
    printf 'missing test dependency: %s\n' "$dependency" >&2
    exit 99
  fi
done

run_status "help exits successfully" 0 "$CLI" --help
assert_contains "help documents exit codes" "Exit codes:" "$last_stdout"
run_status "version exits successfully" 0 "$CLI" --version
assert_contains "version is stable" "md2pdf 0.1.0" "$last_stdout"
run_status "unknown option is rejected" 2 "$CLI" --unknown
assert_contains "unknown option diagnostic is stable" "md2pdf: unknown option: --unknown" "$last_stderr"
run_status "invalid profile is rejected" 2 "$CLI" --profile invalid "$SOURCE/simple.md"
run_status "unknown YAML profile is rejected" 4 \
  "$CLI" "$SOURCE/invalid-yaml-profile.md" "$OUTPUT/invalid-profile.pdf"
assert_contains "unknown YAML profile diagnostic is stable" \
  "md2pdf: md2pdf.profile has unknown profile 'unknown'" "$last_stderr"
run_status "invalid metadata type is rejected" 4 \
  "$CLI" "$SOURCE/invalid-metadata.md" "$OUTPUT/invalid-metadata.pdf"
assert_contains "invalid metadata type diagnostic is stable" \
  "md2pdf: toc must be a boolean" "$last_stderr"

run_status "default output invocation succeeds" 0 "$CLI" "$SOURCE/simple.md"
if [ -s "$SOURCE/simple.pdf" ]; then pass "default output is beside input"; else fail "default output is beside input"; fi
rm -f "$SOURCE/simple.pdf"

run_status "legacy positional output succeeds" 0 \
  "$CLI" "$SOURCE/simple.md" "$OUTPUT/legacy.pdf"
if [ -s "$OUTPUT/legacy.pdf" ]; then pass "legacy output is published"; else fail "legacy output is published"; fi
run_status "explicit output succeeds" 0 \
  "$CLI" -o "$OUTPUT/explicit.pdf" "$SOURCE/simple.md"
if [ -s "$OUTPUT/explicit.pdf" ]; then pass "explicit output is published"; else fail "explicit output is published"; fi
run_status "mixed output forms are rejected" 2 \
  "$CLI" -o "$OUTPUT/one.pdf" "$SOURCE/simple.md" "$OUTPUT/two.pdf"
run_status "missing output parent is rejected" 3 \
  "$CLI" "$SOURCE/simple.md" "$OUTPUT/missing/result.pdf"
run_status "identical canonical paths are rejected" 3 \
  "$CLI" "$SOURCE/simple.md" "$SOURCE/../source/simple.md"

dep_bin=$TMP_ROOT/dependency-bin
mkdir -p "$dep_bin"
for utility in dirname basename realpath; do
  utility_path=$(command -v "$utility")
  ln -s "$utility_path" "$dep_bin/$utility"
done
ln -s "$(command -v pandoc)" "$dep_bin/pandoc"
run_status "missing Typst dependency is rejected" 5 \
  env PATH="$dep_bin" MD2PDF_DATA_DIR="$DATA" "$CLI" \
    "$SOURCE/simple.md" "$OUTPUT/no-typst.pdf"
assert_contains "missing dependency diagnostic is stable" \
  "md2pdf: required dependency not found: typst" "$last_stderr"

xdg_home=$TMP_ROOT/xdg-data
detached_bin=$TMP_ROOT/detached-bin
mkdir -p "$xdg_home" "$detached_bin"
cp -R "$DATA" "$xdg_home/md2pdf"
cp "$CLI" "$detached_bin/md2pdf"
run_status "XDG data lookup supports detached launcher" 0 \
  env XDG_DATA_HOME="$xdg_home" "$detached_bin/md2pdf" \
    "$SOURCE/simple.md" "$OUTPUT/xdg.pdf"
if [ -s "$OUTPUT/xdg.pdf" ]; then pass "XDG lookup publishes PDF"; else fail "XDG lookup publishes PDF"; fi

run_status "CLI profile overrides YAML profile" 0 \
  "$CLI" --profile technical "$SOURCE/profile-override.md" "$OUTPUT/profile.pdf"
pdfinfo "$OUTPUT/profile.pdf" > "$TMP_ROOT/profile.info"
assert_contains "normalized CLI profile reaches PDF metadata" \
  "profile-technical" "$TMP_ROOT/profile.info"

run_status "complex typed YAML succeeds" 0 \
  "$CLI" "$SOURCE/complex.md" "$OUTPUT/complex.pdf"
pdftotext "$OUTPUT/complex.pdf" "$TMP_ROOT/complex.txt"
assert_contains "quoted title word survives" "Quoted" "$TMP_ROOT/complex.txt"
assert_contains "title backslash survives" 'with a \ backslash' "$TMP_ROOT/complex.txt"
assert_contains "structured author name survives" "Ada Lovelace" "$TMP_ROOT/complex.txt"
assert_contains "structured affiliation list survives" \
  "Analytical Society; Computing Group" "$TMP_ROOT/complex.txt"
assert_contains "author list survives" "Grace Hopper" "$TMP_ROOT/complex.txt"
assert_not_contains "top-level false TOC is honored" "Contents" "$TMP_ROOT/complex.txt"

run_status "quoted and backslashed metadata succeeds" 0 \
  "$CLI" "$SOURCE/metadata-special.md" "$OUTPUT/metadata-special.pdf"
pdftotext "$OUTPUT/metadata-special.pdf" "$TMP_ROOT/metadata-special.txt"
assert_contains "quoted title content is preserved" "Quoted" "$TMP_ROOT/metadata-special.txt"
assert_contains "quoted title backslash is preserved" '\ Path' "$TMP_ROOT/metadata-special.txt"
assert_contains "multiline subtitle first line survives" \
  "First subtitle line" "$TMP_ROOT/metadata-special.txt"
assert_contains "multiline subtitle second line survives" \
  "Second subtitle line" "$TMP_ROOT/metadata-special.txt"

run_status "local SVG conversion succeeds" 0 \
  "$CLI" "$SOURCE/local-svg.md" "$OUTPUT/local-svg.pdf"
run_status "local SVG page rasterizes" 0 \
  pdftoppm -f 1 -singlefile -png -r 72 "$OUTPUT/local-svg.pdf" "$TMP_ROOT/local-svg"
if [ -s "$TMP_ROOT/local-svg.png" ]; then pass "local SVG is rendered"; else fail "local SVG is rendered"; fi

image_source=$TMP_ROOT/image-policy
outside_assets=$TMP_ROOT/outside-assets
mkdir -p "$image_source/assets/nested" "$outside_assets"
cp "$SOURCE/assets/mark.svg" "$image_source/assets/nested/mark.svg"
special_image='image space;$&.svg'
cp "$SOURCE/assets/mark.svg" "$image_source/assets/nested/$special_image"
printf '%s\n' '<svg xmlns="http://www.w3.org/2000/svg"><text>OUTSIDE-SENTINEL</text></svg>' \
  > "$outside_assets/sentinel.svg"
ln -s "$outside_assets/sentinel.svg" "$image_source/assets/outside-file.svg"
ln -s "$outside_assets" "$image_source/assets/outside-dir"
printf '# Nested\n\n![nested](assets/nested/mark.svg)\n' > "$image_source/nested.md"
printf '# Special\n\n![special](<assets/nested/%s>)\n' "$special_image" > "$image_source/special.md"
printf '# Absolute\n\n![absolute](<%s>)\n' "$outside_assets/sentinel.svg" > "$image_source/absolute.md"
printf '# Traversal\n\n![traversal](../outside-assets/sentinel.svg)\n' > "$image_source/traversal.md"
printf '# File link\n\n![file](assets/outside-file.svg)\n' > "$image_source/file-link.md"
printf '# Directory link\n\n![directory](assets/outside-dir/sentinel.svg)\n' > "$image_source/directory-link.md"

run_status "nested relative image succeeds" 0 "$CLI" "$image_source/nested.md" "$OUTPUT/nested.pdf"
run_status "image filename with spaces and metacharacters succeeds" 0 \
  "$CLI" "$image_source/special.md" "$OUTPUT/special.pdf"
run_status "absolute image path is rejected" 4 "$CLI" "$image_source/absolute.md" "$OUTPUT/absolute.pdf"
assert_contains "absolute image diagnostic is clear" "md2pdf: absolute local image paths are not permitted:" "$last_stderr"
assert_absent "absolute outside sentinel is not published" "$OUTPUT/absolute.pdf"
run_status "outside image traversal is rejected" 4 "$CLI" "$image_source/traversal.md" "$OUTPUT/traversal.pdf"
assert_contains "outside traversal diagnostic is clear" "md2pdf: local image path escapes the source directory:" "$last_stderr"
assert_absent "traversed outside sentinel is not published" "$OUTPUT/traversal.pdf"
run_status "symlink image file is rejected" 4 "$CLI" "$image_source/file-link.md" "$OUTPUT/file-link.pdf"
assert_contains "symlink file diagnostic is clear" "md2pdf: local image path traverses a symbolic link:" "$last_stderr"
assert_absent "symlinked file sentinel is not published" "$OUTPUT/file-link.pdf"
run_status "symlink image directory is rejected" 4 "$CLI" "$image_source/directory-link.md" "$OUTPUT/directory-link.pdf"
assert_contains "symlink directory diagnostic is clear" "md2pdf: local image path traverses a symbolic link:" "$last_stderr"
assert_absent "symlinked directory sentinel is not published" "$OUTPUT/directory-link.pdf"

printf 'existing target\n' > "$OUTPUT/atomic.pdf"
cp "$OUTPUT/atomic.pdf" "$TMP_ROOT/atomic.expected"
run_status "missing local asset aborts" 4 \
  "$CLI" "$SOURCE/missing-asset.md" "$OUTPUT/atomic.pdf"
assert_contains "missing asset diagnostic is stable" \
  "md2pdf: local image is missing or unreadable: assets/does-not-exist.svg" "$last_stderr"
if cmp "$OUTPUT/atomic.pdf" "$TMP_ROOT/atomic.expected" >/dev/null 2>&1; then
  pass "failed conversion preserves existing target"
else
  fail "failed conversion preserves existing target"
fi
run_status "remote asset aborts before publication" 4 \
  "$CLI" "$SOURCE/remote-asset.md" "$OUTPUT/remote.pdf"
if [ ! -e "$OUTPUT/remote.pdf" ]; then pass "remote failure publishes no PDF"; else fail "remote failure publishes no PDF"; fi

run_status "raw Typst remains inert" 0 \
  "$CLI" "$SOURCE/raw-typst.md" "$OUTPUT/raw-typst.pdf"
pdftotext "$OUTPUT/raw-typst.pdf" "$TMP_ROOT/raw-typst.txt"
assert_contains "raw Typst source remains literal" \
  '#panic("RAW_TYPST_EXECUTED")' "$TMP_ROOT/raw-typst.txt"

no_write_source=$TMP_ROOT/no-source-writes
mkdir -p "$no_write_source/assets"
cp "$SOURCE/representative.md" "$no_write_source/document.md"
cp "$SOURCE/assets/mark.svg" "$no_write_source/assets/mark.svg"
ls -A "$no_write_source" > "$TMP_ROOT/source.before"
ls -A "$no_write_source/assets" > "$TMP_ROOT/assets.before"
run_status "representative General profile succeeds" 0 \
  "$CLI" "$no_write_source/document.md" "$OUTPUT/representative.pdf"
ls -A "$no_write_source" > "$TMP_ROOT/source.after"
ls -A "$no_write_source/assets" > "$TMP_ROOT/assets.after"
if cmp "$TMP_ROOT/source.before" "$TMP_ROOT/source.after" >/dev/null 2>&1 && \
   cmp "$TMP_ROOT/assets.before" "$TMP_ROOT/assets.after" >/dev/null 2>&1; then
  pass "conversion writes nothing into source directory"
else
  fail "conversion writes nothing into source directory"
fi
pdftotext "$OUTPUT/representative.pdf" "$TMP_ROOT/representative.txt"
assert_contains "inline code extraction is unchanged" \
  "path/to_value-name" "$TMP_ROOT/representative.txt"
assert_contains "inline code retains surrounding word spacing" \
  "inline code path/to_value-name" "$TMP_ROOT/representative.txt"
run_status "representative pages rasterize" 0 \
  pdftoppm -f 1 -l 3 -png -r 72 "$OUTPUT/representative.pdf" "$TMP_ROOT/representative"

run_status "long table conversion succeeds" 0 \
  "$CLI" "$SOURCE/long-table.md" "$OUTPUT/long-table.pdf"
pdftotext -layout "$OUTPUT/long-table.pdf" "$TMP_ROOT/long-table.txt"
assert_contains "long table retains first row" "ROW-01" "$TMP_ROOT/long-table.txt"
assert_contains "long table retains final row" "ROW-60" "$TMP_ROOT/long-table.txt"
long_pages=$(pdfinfo "$OUTPUT/long-table.pdf" | awk '/^Pages:/ { print $2 }')
if [ "$long_pages" -ge 3 ]; then pass "long table spans multiple body pages"; else fail "long table spans multiple body pages"; fi
run_status "long table boundary pages rasterize" 0 \
  pdftoppm -f 2 -l 3 -png -r 96 "$OUTPUT/long-table.pdf" "$TMP_ROOT/long-table"
pdftotext -f 1 -l 1 "$OUTPUT/long-table.pdf" "$TMP_ROOT/long-page-1.txt"
pdftotext -f 2 -l 2 "$OUTPUT/long-table.pdf" "$TMP_ROOT/long-page-2.txt"
assert_not_contains "cover omits running header" "RUNNING HEADER" "$TMP_ROOT/long-page-1.txt"
assert_not_contains "cover omits running footer" "RUNNING FOOTER" "$TMP_ROOT/long-page-1.txt"
assert_contains "body includes running header" "RUNNING HEADER" "$TMP_ROOT/long-page-2.txt"
assert_contains "body includes running footer" "RUNNING FOOTER" "$TMP_ROOT/long-page-2.txt"

run_status "wide table conversion succeeds" 0 \
  "$CLI" "$SOURCE/wide-table.md" "$OUTPUT/wide-table.pdf"
pdfinfo -f 1 -l 3 "$OUTPUT/wide-table.pdf" > "$TMP_ROOT/wide.info"
if awk '$1 == "Page" && $2 == 1 && $3 == "size:" { if ($4 < $6) found=1 } END { exit !found }' \
  "$TMP_ROOT/wide.info"; then pass "page before wide table is portrait"; else fail "page before wide table is portrait"; fi
if awk '$1 == "Page" && $2 == 2 && $3 == "size:" { if ($4 > $6) found=1 } END { exit !found }' \
  "$TMP_ROOT/wide.info"; then pass "wide table page is landscape"; else fail "wide table page is landscape"; fi
if awk '$1 == "Page" && $2 == 3 && $3 == "size:" { if ($4 < $6) found=1 } END { exit !found }' \
  "$TMP_ROOT/wide.info"; then pass "page after wide table returns to portrait"; else fail "page after wide table returns to portrait"; fi
pdftotext -f 2 -l 2 "$OUTPUT/wide-table.pdf" "$TMP_ROOT/wide-page-2.txt"
pdftotext -f 3 -l 3 "$OUTPUT/wide-table.pdf" "$TMP_ROOT/wide-page-3.txt"
assert_contains "wide table content is on landscape page" "Foxtrot" "$TMP_ROOT/wide-page-2.txt"
assert_contains "post-table content is restored" "PORTRAIT AFTER" "$TMP_ROOT/wide-page-3.txt"
run_status "wide table page rasterizes" 0 \
  pdftoppm -f 2 -singlefile -png -r 96 "$OUTPUT/wide-table.pdf" "$TMP_ROOT/wide-table"

run_status "launcher passes POSIX shell syntax" 0 sh -n "$CLI"
run_status "test runner passes POSIX shell syntax" 0 sh -n "$ROOT/tests/run.sh"
run_status "worktree has no whitespace errors" 0 git -C "$ROOT" diff --check

total=$((passed + failed))
printf '%s tests passed; %s tests failed; %s total\n' "$passed" "$failed" "$total"
[ "$failed" -eq 0 ]
