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

portable_mode() {
  if mode_result=$(stat -c '%a' "$1" 2>/dev/null); then
    printf '%s\n' "$mode_result"
    return 0
  fi
  stat -f '%Lp' "$1" 2>/dev/null
}

for dependency in pandoc typst pdfinfo pdftotext pdftoppm pdffonts; do
  if ! command -v "$dependency" >/dev/null 2>&1; then
    printf 'missing test dependency: %s\n' "$dependency" >&2
    exit 99
  fi
done

if [ "${MD2PDF_TEST_NON_GIT_CHILD:-0}" = 1 ]; then
  run_status "non-Git copy launcher passes POSIX shell syntax" 0 sh -n "$CLI"
  if command -v git >/dev/null 2>&1 && \
     git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    last_stderr=
    fail "non-Git copy does not require a worktree"
  else
    pass "non-Git copy does not require a worktree"
  fi
  run_status "non-Git source copy performs a real asset conversion" 0 \
    "$CLI" "$SOURCE/local-svg.md" "$OUTPUT/non-git-local-svg.pdf"
  if [ -s "$OUTPUT/non-git-local-svg.pdf" ]; then
    pass "non-Git source copy resolves bundled runtime and local assets"
  else
    fail "non-Git source copy resolves bundled runtime and local assets"
  fi
  total=$((passed + failed))
  printf '%s tests passed; %s tests failed; %s total\n' "$passed" "$failed" "$total"
  [ "$failed" -eq 0 ]
  exit
fi

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
run_status "unsupported page value is rejected" 4 \
  "$CLI" "$SOURCE/invalid-page-value.md" "$OUTPUT/invalid-page.pdf"
assert_contains "unsupported page value diagnostic is clear" \
  "md2pdf: md2pdf.page.paper has unsupported value 'tabloid'" "$last_stderr"
run_status "unknown structure key is rejected" 4 \
  "$CLI" "$SOURCE/invalid-header-key.md" "$OUTPUT/invalid-header.pdf"
assert_contains "unknown structure key diagnostic is clear" \
  "md2pdf: md2pdf.header contains unknown key 'color'" "$last_stderr"

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

ln "$SOURCE/simple.md" "$OUTPUT/simple-hardlink.pdf"
run_status "hard-linked output is rejected as the input file" 3 \
  "$CLI" "$SOURCE/simple.md" "$OUTPUT/simple-hardlink.pdf"
assert_contains "hard-link diagnostic is stable" \
  "md2pdf: input and output must be different files" "$last_stderr"
rm -f "$OUTPUT/simple-hardlink.pdf"

ln -s "$SOURCE/simple.md" "$OUTPUT/simple-symlink.pdf"
run_status "symlinked output is rejected as the input file" 3 \
  "$CLI" "$SOURCE/simple.md" "$OUTPUT/simple-symlink.pdf"
rm -f "$OUTPUT/simple-symlink.pdf"

bsd_bin=$TMP_ROOT/bsd-stat-bin
mkdir -p "$bsd_bin"
cp "$SOURCE/bsd-stat" "$bsd_bin/stat"
chmod +x "$bsd_bin/stat"
ln "$SOURCE/simple.md" "$OUTPUT/bsd-hardlink.pdf"
run_status "BSD stat fallback retains hard-link protection" 3 \
  env PATH="$bsd_bin:$PATH" MD2PDF_REAL_STAT="$(command -v stat)" \
    "$CLI" "$SOURCE/simple.md" "$OUTPUT/bsd-hardlink.pdf"
rm -f "$OUTPUT/bsd-hardlink.pdf"

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

fallback_root=$TMP_ROOT/data-fallback
mkdir -p "$fallback_root/bin/share/md2pdf/filters" "$fallback_root/share"
cp "$CLI" "$fallback_root/bin/md2pdf"
cp "$DATA/filters/runtime.lua" "$fallback_root/bin/share/md2pdf/filters/runtime.lua"
cp -R "$DATA" "$fallback_root/share/md2pdf"
run_status "data lookup skips an incomplete early candidate" 0 \
  "$fallback_root/bin/md2pdf" "$SOURCE/simple.md" "$OUTPUT/data-fallback.pdf"
if [ -s "$OUTPUT/data-fallback.pdf" ]; then
  pass "later complete data installation publishes PDF"
else
  fail "later complete data installation publishes PDF"
fi

run_status "CLI profile overrides YAML profile" 0 \
  "$CLI" --profile technical "$SOURCE/profile-override.md" "$OUTPUT/profile.pdf"
pdfinfo "$OUTPUT/profile.pdf" > "$TMP_ROOT/profile.info"
assert_contains "normalized CLI profile reaches PDF metadata" \
  "profile-technical" "$TMP_ROOT/profile.info"

for profile in general technical report academic; do
  profile_pdf=$OUTPUT/profile-$profile.pdf
  profile_text=$TMP_ROOT/profile-$profile.txt
  profile_info=$TMP_ROOT/profile-$profile.info
  run_status "$profile profile reference conversion succeeds" 0 \
    "$CLI" --profile "$profile" "$SOURCE/profile-reference.md" "$profile_pdf"
  pdfinfo "$profile_pdf" > "$profile_info"
  pdftotext "$profile_pdf" "$profile_text"
  assert_contains "$profile identity reaches PDF metadata" \
    "profile-$profile" "$profile_info"
  profile_pages=$(awk '/^Pages:/ { print $2 }' "$profile_info")
  if [ "$profile_pages" -ge 2 ]; then
    pass "$profile profile has representative front and body pages"
  else
    fail "$profile profile has representative front and body pages"
  fi
  profile_bytes=$(wc -c < "$profile_pdf")
  if [ "$profile_bytes" -gt 30000 ]; then
    pass "$profile profile PDF has substantive rendered size"
  else
    fail "$profile profile PDF has substantive rendered size"
  fi
  run_status "$profile cover page rasterizes" 0 \
    pdftoppm -f 1 -singlefile -png -r 72 "$profile_pdf" "$TMP_ROOT/profile-$profile-cover"
  case $profile in
    academic) profile_body_page=1 ;;
    *) profile_body_page=3 ;;
  esac
  run_status "$profile body page rasterizes" 0 \
    pdftoppm -f "$profile_body_page" -singlefile -png -r 72 \
      "$profile_pdf" "$TMP_ROOT/profile-$profile-body"
  case $profile in
    general)
      assert_contains "General keeps balanced cover identity" "Profile Reference" "$profile_text"
      ;;
    technical)
      assert_contains "Technical has distinct running furniture" "TECHNICAL · Profile Reference" "$profile_text"
      assert_contains "Technical numbers sections by default" "1. Architecture" "$profile_text"
      ;;
    report)
      assert_contains "Report has formal running furniture" "REPORT · Profile Reference" "$profile_text"
      assert_contains "Report numbers sections by default" "1. Architecture" "$profile_text"
      ;;
    academic)
      assert_contains "Academic has restrained title label" "ACADEMIC" "$profile_text"
      assert_contains "Academic numbers equations by default" "(1)" "$profile_text"
      ;;
  esac
done

for profile_pair in \
  'general technical' \
  'general report' \
  'general academic' \
  'technical report' \
  'technical academic' \
  'report academic'
do
  set -- $profile_pair
  left_profile=$1
  right_profile=$2
  for page_kind in cover body; do
    if cmp "$TMP_ROOT/profile-$left_profile-$page_kind.png" \
        "$TMP_ROOT/profile-$right_profile-$page_kind.png" >/dev/null 2>&1; then
      fail "$left_profile and $right_profile $page_kind pages are visually distinct"
    else
      pass "$left_profile and $right_profile $page_kind pages are visually distinct"
    fi
  done
done

for profile in general technical report academic; do
  run_status "$profile honors YAML structure overrides after CLI profile selection" 0 \
    "$CLI" --profile "$profile" "$SOURCE/structure-overrides.md" \
      "$OUTPUT/structure-$profile.pdf"
  pdfinfo "$OUTPUT/structure-$profile.pdf" > "$TMP_ROOT/structure-$profile.info"
  pdftotext "$OUTPUT/structure-$profile.pdf" "$TMP_ROOT/structure-$profile.txt"
  pdftotext -bbox "$OUTPUT/structure-$profile.pdf" "$TMP_ROOT/structure-$profile.html"
  structure_pages=$(awk '/^Pages:/ { print $2 }' "$TMP_ROOT/structure-$profile.info")
  if [ "$structure_pages" -eq 1 ]; then
    pass "$profile honors cover and TOC disable overrides"
  else
    fail "$profile honors cover and TOC disable overrides"
  fi
  if awk '/^Page size:/ { exit !($3 > $5) }' "$TMP_ROOT/structure-$profile.info"; then
    pass "$profile honors landscape paper override"
  else
    fail "$profile honors landscape paper override"
  fi
  assert_not_contains "$profile keeps TOC disabled" "Contents" "$TMP_ROOT/structure-$profile.txt"
  assert_not_contains "$profile keeps section numbering disabled" \
    "1. Override heading" "$TMP_ROOT/structure-$profile.txt"
  assert_not_contains "$profile keeps default profile header disabled" \
    " · Structure Overrides" "$TMP_ROOT/structure-$profile.txt"
  if awk -F'"' '/>Override</ { found=1; ok=($2 >= 70 && $2 <= 100); exit } END { exit !(found && ok) }' \
      "$TMP_ROOT/structure-$profile.html"; then
    pass "$profile honors one-inch margin override"
  else
    fail "$profile honors one-inch margin override"
  fi

  run_status "$profile honors YAML TOC depth override" 0 \
    "$CLI" --profile "$profile" "$SOURCE/toc-depth-override.md" \
      "$OUTPUT/toc-depth-$profile.pdf"
  pdftotext -f 1 -l 1 "$OUTPUT/toc-depth-$profile.pdf" "$TMP_ROOT/toc-depth-$profile.txt"
  assert_contains "$profile TOC includes level-one heading" \
    "Top-level entry" "$TMP_ROOT/toc-depth-$profile.txt"
  assert_not_contains "$profile TOC excludes level-two heading at depth one" \
    "Nested entry" "$TMP_ROOT/toc-depth-$profile.txt"
done

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
pdfinfo "$OUTPUT/complex.pdf" > "$TMP_ROOT/complex.info"
assert_contains "author email is retained in intentional PDF metadata" \
  "author-email:ada@example.test" "$TMP_ROOT/complex.info"

run_status "quoted and backslashed metadata succeeds" 0 \
  "$CLI" "$SOURCE/metadata-special.md" "$OUTPUT/metadata-special.pdf"
pdftotext "$OUTPUT/metadata-special.pdf" "$TMP_ROOT/metadata-special.txt"
assert_contains "quoted title content is preserved" "Quoted" "$TMP_ROOT/metadata-special.txt"
assert_contains "quoted title backslash is preserved" '\ Path' "$TMP_ROOT/metadata-special.txt"
assert_contains "multiline subtitle first line survives" \
  "First subtitle line" "$TMP_ROOT/metadata-special.txt"
assert_contains "multiline subtitle second line survives" \
  "Second subtitle line" "$TMP_ROOT/metadata-special.txt"

run_status "academic citation and bibliography conversion succeeds" 0 \
  "$CLI" "$SOURCE/academic-citation.md" "$OUTPUT/academic-citation.pdf"
pdftotext "$OUTPUT/academic-citation.pdf" "$TMP_ROOT/academic-citation.txt"
assert_contains "custom CSL formats first citation" "[1]" "$TMP_ROOT/academic-citation.txt"
assert_contains "bibliography receives English localized heading" \
  "References" "$TMP_ROOT/academic-citation.txt"
assert_contains "first bibliography record is rendered" \
  "Lamport, Leslie" "$TMP_ROOT/academic-citation.txt"
assert_contains "second bibliography record is rendered" \
  "Pandoc user’s guide" "$TMP_ROOT/academic-citation.txt"
assert_contains "academic display equation is numbered" "(1)" "$TMP_ROOT/academic-citation.txt"

run_status "missing bibliography fails critically" 4 \
  "$CLI" "$SOURCE/missing-bibliography.md" "$OUTPUT/missing-bibliography.pdf"
assert_contains "missing bibliography diagnostic is clear" \
  "md2pdf: bibliography is missing or unreadable: assets/does-not-exist.bib" "$last_stderr"
assert_absent "missing bibliography publishes no PDF" "$OUTPUT/missing-bibliography.pdf"

run_status "invalid bibliography fails critically" 4 \
  "$CLI" "$SOURCE/invalid-bibliography.md" "$OUTPUT/invalid-bibliography.pdf"
assert_contains "invalid bibliography diagnostic is clear" \
  "md2pdf: bibliography is invalid: assets/invalid.bib" "$last_stderr"
assert_absent "invalid bibliography publishes no PDF" "$OUTPUT/invalid-bibliography.pdf"

run_status "unresolved citation fails critically" 4 \
  "$CLI" "$SOURCE/unresolved-citation.md" "$OUTPUT/unresolved-citation.pdf"
assert_contains "unresolved citation diagnostic names the key" \
  "md2pdf: unresolved citation: @missing-key" "$last_stderr"
assert_absent "unresolved citation publishes no PDF" "$OUTPUT/unresolved-citation.pdf"

cp "$SOURCE/assets/references.bib" "$TMP_ROOT/outside.bib"
printf '%s\n' \
  '---' \
  'title: Escaping Bibliography' \
  'bibliography: ../outside.bib' \
  'md2pdf:' \
  '  cover: false' \
  '  toc: false' \
  '---' \
  'Escaping citation [@lamport1994].' > "$SOURCE/escaping-bibliography.md"
run_status "escaping bibliography path is rejected" 4 \
  "$CLI" "$SOURCE/escaping-bibliography.md" "$OUTPUT/escaping-bibliography.pdf"
assert_contains "escaping bibliography diagnostic is clear" \
  "md2pdf: bibliography path escapes the source directory: ../outside.bib" "$last_stderr"

ln -s "$TMP_ROOT/outside.bib" "$SOURCE/assets/linked.bib"
printf '%s\n' \
  '---' \
  'title: Linked Bibliography' \
  'bibliography: assets/linked.bib' \
  'md2pdf:' \
  '  cover: false' \
  '  toc: false' \
  '---' \
  'Linked citation [@lamport1994].' > "$SOURCE/linked-bibliography.md"
run_status "symlinked bibliography path is rejected" 4 \
  "$CLI" "$SOURCE/linked-bibliography.md" "$OUTPUT/linked-bibliography.pdf"
assert_contains "symlinked bibliography diagnostic is clear" \
  "md2pdf: bibliography path traverses a symbolic link: assets/linked.bib" "$last_stderr"

printf '%s\n' \
  '---' \
  'title: Typed Bibliography' \
  'bibliography:' \
  '  path: assets/references.bib' \
  'md2pdf:' \
  '  cover: false' \
  '  toc: false' \
  '---' \
  'Wrong type.' > "$SOURCE/typed-bibliography.md"
run_status "bibliography mapping type is rejected" 4 \
  "$CLI" "$SOURCE/typed-bibliography.md" "$OUTPUT/typed-bibliography.pdf"
assert_contains "bibliography type diagnostic is clear" \
  "md2pdf: bibliography must be a string or list of strings" "$last_stderr"

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

run_status "new PDF honors caller umask" 0 \
  sh -c 'umask 027; exec "$1" "$2" "$3"' sh \
    "$CLI" "$SOURCE/simple.md" "$OUTPUT/umask.pdf"
umask_mode=$(portable_mode "$OUTPUT/umask.pdf")
if [ "$umask_mode" = 640 ]; then
  pass "new PDF mode reflects 0666 masked by 027"
else
  printf '  expected mode 640, received %s\n' "$umask_mode" >&2
  fail "new PDF mode reflects 0666 masked by 027"
fi

printf 'existing target\n' > "$OUTPUT/preserved-mode.pdf"
chmod 600 "$OUTPUT/preserved-mode.pdf"
run_status "existing PDF mode is preserved across atomic replacement" 0 \
  sh -c 'umask 022; exec "$1" "$2" "$3"' sh \
    "$CLI" "$SOURCE/simple.md" "$OUTPUT/preserved-mode.pdf"
preserved_mode=$(portable_mode "$OUTPUT/preserved-mode.pdf")
if [ "$preserved_mode" = 600 ]; then
  pass "atomic replacement preserves target mode"
else
  printf '  expected mode 600, received %s\n' "$preserved_mode" >&2
  fail "atomic replacement preserves target mode"
fi
remote_bin=$TMP_ROOT/remote-bin
mkdir -p "$remote_bin"
cp "$SOURCE/mock-curl" "$remote_bin/curl"
chmod +x "$remote_bin/curl"

remote_failure_log=$TMP_ROOT/remote-failure.log
run_status "HTTPS fetch failure degrades to a placeholder without live network access" 0 \
  env PATH="$remote_bin:$PATH" MD2PDF_CURL_LOG="$remote_failure_log" \
    "$CLI" "$SOURCE/remote-asset.md" "$OUTPUT/remote.pdf"
assert_contains "HTTPS fetch warning is clear" \
  "remote image unavailable; using linked placeholder" "$last_stderr"
pdftotext "$OUTPUT/remote.pdf" "$TMP_ROOT/remote.txt"
assert_contains "HTTPS failure placeholder is visible" \
  "Remote image unavailable: Remote resource" "$TMP_ROOT/remote.txt"
remote_failure_calls=$(wc -l < "$remote_failure_log")
if [ "$remote_failure_calls" -eq 1 ]; then
  pass "repeated HTTPS failure does not repeat curl"
else
  printf '  expected 1 curl call, received %s\n' "$remote_failure_calls" >&2
  fail "repeated HTTPS failure does not repeat curl"
fi

run_status "HTTP image is blocked without aborting conversion" 0 \
  "$CLI" "$SOURCE/remote-http.md" "$OUTPUT/remote-http.pdf"
assert_contains "HTTP policy warning names HTTPS requirement" \
  "only HTTPS remote images are permitted (received http)" "$last_stderr"
pdftotext "$OUTPUT/remote-http.pdf" "$TMP_ROOT/remote-http.txt"
assert_contains "HTTP placeholder is visible" \
  "Remote image unavailable: HTTP resource" "$TMP_ROOT/remote-http.txt"

run_status "file URI image is blocked without local access" 0 \
  "$CLI" "$SOURCE/remote-file-uri.md" "$OUTPUT/remote-file-uri.pdf"
assert_contains "file URI policy warning is clear" \
  "only HTTPS remote images are permitted (received file)" "$last_stderr"
pdftotext "$OUTPUT/remote-file-uri.pdf" "$TMP_ROOT/remote-file-uri.txt"
assert_contains "file URI placeholder is visible" \
  "Remote image unavailable: Local URI" "$TMP_ROOT/remote-file-uri.txt"

private_log=$TMP_ROOT/remote-private.log
run_status "private and localhost remote literals degrade without a network attempt" 0 \
  env PATH="$remote_bin:$PATH" MD2PDF_CURL_LOG="$private_log" \
    "$CLI" "$SOURCE/remote-private.md" "$OUTPUT/remote-private.pdf"
private_stderr=$last_stderr
assert_contains "localhost hostname warning is clear" \
  "localhost hostnames are not permitted" "$private_stderr"
assert_contains "private IP warning is clear" \
  "loopback, link-local, and private IP literals are not permitted" "$private_stderr"
if [ ! -s "$private_log" ]; then
  pass "blocked remote hosts never invoke curl"
else
  fail "blocked remote hosts never invoke curl"
fi

remote_mock_log=$TMP_ROOT/remote-mock.log
run_status "bounded HTTPS fetch stages valid images and replaces invalid responses" 0 \
  env PATH="$remote_bin:$PATH" MD2PDF_CURL_LOG="$remote_mock_log" \
    "$CLI" "$SOURCE/remote-mock.md" "$OUTPUT/remote-mock.pdf"
remote_mock_stderr=$last_stderr
assert_contains "remote MIME rejection warning is clear" \
  "unsupported response MIME type 'text/html'" "$remote_mock_stderr"
assert_contains "remote size rejection warning is clear" \
  "payload exceeds 5 MiB" "$remote_mock_stderr"
pdftotext "$OUTPUT/remote-mock.pdf" "$TMP_ROOT/remote-mock.txt"
assert_contains "successfully fetched image keeps its caption" \
  "Fetched image" "$TMP_ROOT/remote-mock.txt"
assert_contains "wrong MIME response becomes a visible placeholder" \
  "Remote image unavailable: Wrong MIME" "$TMP_ROOT/remote-mock.txt"
assert_contains "cached wrong MIME response keeps each placeholder visible" \
  "Remote image unavailable: Repeated wrong MIME" "$TMP_ROOT/remote-mock.txt"
assert_contains "oversized response becomes a visible placeholder" \
  "Remote image unavailable: Oversized image" "$TMP_ROOT/remote-mock.txt"
remote_mock_calls=$(wc -l < "$remote_mock_log")
if [ "$remote_mock_calls" -eq 3 ]; then
  pass "repeated failed remote URL is fetched only once"
else
  printf '  expected 3 curl calls, received %s\n' "$remote_mock_calls" >&2
  fail "repeated failed remote URL is fetched only once"
fi

run_status "raw Typst remains inert" 0 \
  "$CLI" "$SOURCE/raw-typst.md" "$OUTPUT/raw-typst.pdf"
pdftotext "$OUTPUT/raw-typst.pdf" "$TMP_ROOT/raw-typst.txt"
assert_contains "raw Typst source remains literal" \
  '#panic("RAW_TYPST_EXECUTED")' "$TMP_ROOT/raw-typst.txt"

run_status "semantic alert conversion succeeds" 0 \
  "$CLI" "$SOURCE/alerts.md" "$OUTPUT/alerts.pdf"
pdftotext "$OUTPUT/alerts.pdf" "$TMP_ROOT/alerts.txt"
for alert_label in Note Tip Important Warning Caution; do
  assert_contains "$alert_label alert label is rendered" "$alert_label" "$TMP_ROOT/alerts.txt"
done
assert_contains "unknown alert marker remains an ordinary quote" \
  "[!UNKNOWN] Unknown markers remain ordinary quotations." "$TMP_ROOT/alerts.txt"
run_status "alert page rasterizes" 0 \
  pdftoppm -f 1 -singlefile -png -r 96 "$OUTPUT/alerts.pdf" "$TMP_ROOT/alerts"

gfm_stage=$TMP_ROOT/gfm-alert-stage
mkdir -p "$gfm_stage/assets" "$gfm_stage/citations"
run_status "native GFM alert AST is transformed by real Pandoc" 0 \
  env MD2PDF_STAGE_DIR="$gfm_stage" \
    MD2PDF_SOURCE_DIR="$SOURCE" \
    MD2PDF_CLI_PROFILE= \
    MD2PDF_FILTER_ERROR="$gfm_stage/filter-error.txt" \
    pandoc "$SOURCE/alerts.md" --from=gfm --to=typst \
      --lua-filter="$DATA/filters/runtime.lua" \
      --citeproc \
      --lua-filter="$DATA/filters/citations.lua"
assert_contains "GFM NOTE becomes the shared semantic component" \
  '#md2pdf-alert("note")' "$last_stdout"

run_status "Spanish report conversion succeeds" 0 \
  "$CLI" "$SOURCE/spanish.md" "$OUTPUT/spanish.pdf"
pdftotext "$OUTPUT/spanish.pdf" "$TMP_ROOT/spanish.txt"
assert_contains "Spanish TOC label is localized" "Índice" "$TMP_ROOT/spanish.txt"
assert_contains "Spanish report furniture is localized" "INFORME" "$TMP_ROOT/spanish.txt"
assert_contains "Spanish alert label is localized" "Nota" "$TMP_ROOT/spanish.txt"

for language_tag in ES ES-MX; do
  language_fixture=$SOURCE/spanish-$language_tag.md
  awk -v tag="$language_tag" \
    '$1 == "lang:" { print "lang: " tag; next } { print }' \
    "$SOURCE/spanish.md" > "$language_fixture"
  run_status "$language_tag selects Spanish labels case-insensitively" 0 \
    "$CLI" "$language_fixture" "$OUTPUT/spanish-$language_tag.pdf"
  pdftotext "$OUTPUT/spanish-$language_tag.pdf" "$TMP_ROOT/spanish-$language_tag.txt"
  assert_contains "$language_tag localizes the TOC" \
    "Índice" "$TMP_ROOT/spanish-$language_tag.txt"
  assert_contains "$language_tag localizes profile furniture" \
    "INFORME" "$TMP_ROOT/spanish-$language_tag.txt"
  assert_contains "$language_tag localizes alerts" \
    "Nota" "$TMP_ROOT/spanish-$language_tag.txt"
done

run_status "multilingual glyph fallback conversion succeeds" 0 \
  "$CLI" "$SOURCE/multilingual.md" "$OUTPUT/multilingual.pdf"
pdftotext "$OUTPUT/multilingual.pdf" "$TMP_ROOT/multilingual.txt"
pdffonts "$OUTPUT/multilingual.pdf" > "$TMP_ROOT/multilingual.fonts"
assert_contains "Greek glyphs survive extraction" "Ελληνικά" "$TMP_ROOT/multilingual.txt"
assert_contains "CJK glyphs survive extraction" "中文排版测试" "$TMP_ROOT/multilingual.txt"
assert_contains "Arabic fallback font is embedded" "NotoNaskhArabic" "$TMP_ROOT/multilingual.fonts"
assert_contains "CJK fallback font is embedded" "NotoSerifCJK" "$TMP_ROOT/multilingual.fonts"
assert_contains "Hebrew glyphs survive extraction" "עברית" "$TMP_ROOT/multilingual.txt"

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

typst_proxy_bin=$TMP_ROOT/typst-proxy-bin
mkdir -p "$typst_proxy_bin"
cp "$SOURCE/typst-proxy" "$typst_proxy_bin/typst"
chmod +x "$typst_proxy_bin/typst"
real_typst=$(command -v typst)

run_status "successful Typst warnings remain visible" 0 \
  env PATH="$typst_proxy_bin:$PATH" MD2PDF_REAL_TYPST="$real_typst" \
    MD2PDF_TYPST_MODE=warning \
    "$CLI" "$SOURCE/simple.md" "$OUTPUT/typst-warning.pdf"
assert_contains "successful Typst diagnostic is preserved" \
  "warning: representative missing-glyph diagnostic" "$last_stderr"

run_status "missing preferred font uses fallback with a visible warning" 0 \
  env PATH="$typst_proxy_bin:$PATH" MD2PDF_REAL_TYPST="$real_typst" \
    MD2PDF_TYPST_MODE=missing-font \
    "$CLI" "$SOURCE/simple.md" "$OUTPUT/missing-preferred-font.pdf"
assert_contains "missing preferred font diagnostic names the family" \
  "preferred body font is unavailable: Libertinus Serif" "$last_stderr"

printf 'existing target\n' > "$OUTPUT/typst-failure.pdf"
cp "$OUTPUT/typst-failure.pdf" "$TMP_ROOT/typst-failure.expected"
run_status "Typst failure preserves full diagnostics" 6 \
  env PATH="$typst_proxy_bin:$PATH" MD2PDF_REAL_TYPST="$real_typst" \
    MD2PDF_TYPST_MODE=fail \
    "$CLI" "$SOURCE/simple.md" "$OUTPUT/typst-failure.pdf"
typst_failure_stderr=$last_stderr
assert_contains "Typst failure retains primary diagnostic" \
  "representative Typst compilation failure" "$typst_failure_stderr"
assert_contains "Typst failure retains diagnostic detail" \
  "diagnostic detail is preserved" "$typst_failure_stderr"
if cmp "$OUTPUT/typst-failure.pdf" "$TMP_ROOT/typst-failure.expected" >/dev/null 2>&1; then
  pass "Typst failure preserves the existing PDF"
else
  fail "Typst failure preserves the existing PDF"
fi

install_home=$TMP_ROOT/install-home
install_bin=$TMP_ROOT/install-xdg-bin
install_data=$TMP_ROOT/install-xdg-data
mkdir -p "$install_home" "$install_bin" "$install_data"
run_status "default XDG installation dry-run succeeds" 0 \
  env HOME="$install_home" XDG_BIN_HOME="$install_bin" XDG_DATA_HOME="$install_data" \
    "$ROOT/install.sh" --dry-run
assert_contains "installation dry-run reports version" \
  "Would install md2pdf 0.1.0" "$last_stdout"
assert_absent "installation dry-run creates no launcher" "$install_bin/md2pdf"
assert_absent "installation dry-run creates no runtime" "$install_data/md2pdf"

run_status "default XDG installation succeeds" 0 \
  env HOME="$install_home" XDG_BIN_HOME="$install_bin" XDG_DATA_HOME="$install_data" \
    "$ROOT/install.sh"
installed_cli=$install_bin/md2pdf
installed_data=$install_data/md2pdf
run_status "installed launcher reports version 0.1.0" 0 "$installed_cli" --version
assert_contains "installed launcher version is stable" "md2pdf 0.1.0" "$last_stdout"
if [ -x "$installed_cli" ] && [ -x "$installed_data/uninstall.sh" ]; then
  pass "installation preserves launcher and uninstaller executable modes"
else
  fail "installation preserves launcher and uninstaller executable modes"
fi

install_work=$TMP_ROOT/installed-conversion
mkdir -p "$install_work/assets"
cp "$SOURCE/local-svg.md" "$install_work/document.md"
cp "$SOURCE/assets/mark.svg" "$install_work/assets/mark.svg"
run_status "installed launcher converts from another working directory" 0 \
  env HOME="$install_home" XDG_BIN_HOME="$install_bin" XDG_DATA_HOME="$install_data" \
    sh -c 'cd "$1" && "$2" document.md result.pdf' sh \
      "$install_work" "$installed_cli"
run_status "installed conversion with local asset rasterizes" 0 \
  pdftoppm -f 1 -singlefile -png -r 72 \
    "$install_work/result.pdf" "$TMP_ROOT/installed-local-svg"

printf 'bin sentinel\n' > "$install_bin/unrelated-sentinel"
printf 'data sentinel\n' > "$installed_data/unrelated-sentinel"
run_status "reinstallation is idempotent" 0 \
  env HOME="$install_home" XDG_BIN_HOME="$install_bin" XDG_DATA_HOME="$install_data" \
    "$ROOT/install.sh"
if [ -f "$install_bin/unrelated-sentinel" ] && \
   [ -f "$installed_data/unrelated-sentinel" ]; then
  pass "reinstallation preserves unrelated sentinel files"
else
  fail "reinstallation preserves unrelated sentinel files"
fi

secure_prefix=$TMP_ROOT/secure-prefix
run_status "hostile umask installation succeeds" 0 sh -c \
  'umask 000; exec "$1" --prefix "$2"' sh "$ROOT/install.sh" "$secure_prefix"
bad_mode=
for mode_path in "$secure_prefix/bin/md2pdf" $(find "$secure_prefix/share/md2pdf" \( -type d -o -type f \) -print); do
  expected_mode=644
  if [ -d "$mode_path" ] || [ "$mode_path" = "$secure_prefix/bin/md2pdf" ] || [ "$mode_path" = "$secure_prefix/share/md2pdf/uninstall.sh" ]; then expected_mode=755; fi
  [ "$(portable_mode "$mode_path")" = "$expected_mode" ] || bad_mode=$mode_path
done
if [ -z "$bad_mode" ]; then pass "hostile umask publishes exact safe modes"; else fail "hostile umask publishes exact safe modes"; fi

outside_runtime=$TMP_ROOT/outside-runtime; outside_sentinel=$outside_runtime/sentinel; mkdir "$outside_runtime"; printf 'outside sentinel\n' > "$outside_sentinel"; sentinel_checksum=$(cksum < "$outside_sentinel")
runtime_link_prefix=$TMP_ROOT/runtime-link-prefix; mkdir -p "$runtime_link_prefix/share"; ln -s "$outside_runtime" "$runtime_link_prefix/share/md2pdf"
run_status "installer rejects a symlinked runtime directory" 1 "$ROOT/install.sh" --prefix "$runtime_link_prefix"
symlink_prefix=$TMP_ROOT/symlink-prefix
run_status "symlink test installation succeeds" 0 "$ROOT/install.sh" --prefix "$symlink_prefix"
rm "$symlink_prefix/share/md2pdf/filters/runtime.lua" && ln -s "$outside_sentinel" "$symlink_prefix/share/md2pdf/filters/runtime.lua"
run_status "installer rejects a symlinked runtime destination" 1 "$ROOT/install.sh" --prefix "$symlink_prefix"
rm "$symlink_prefix/share/md2pdf/filters/runtime.lua" && cp "$DATA/filters/runtime.lua" "$symlink_prefix/share/md2pdf/filters/runtime.lua"
rm "$symlink_prefix/bin/md2pdf" && ln -s "$outside_sentinel" "$symlink_prefix/bin/md2pdf"
run_status "installer rejects a symlinked launcher target" 1 "$ROOT/install.sh" --prefix "$symlink_prefix"
rm "$symlink_prefix/bin/md2pdf" && cp "$CLI" "$symlink_prefix/bin/md2pdf"
rm "$symlink_prefix/share/md2pdf/uninstall.sh" && ln -s "$outside_sentinel" "$symlink_prefix/share/md2pdf/uninstall.sh"
run_status "installer rejects a symlinked uninstaller target" 1 "$ROOT/install.sh" --prefix "$symlink_prefix"
if [ "$(cksum < "$outside_sentinel")" = "$sentinel_checksum" ]; then pass "rejected installer symlinks preserve outside sentinel content"; else fail "rejected installer symlinks preserve outside sentinel content"; fi

mv_proxy_bin=$TMP_ROOT/install-mv-proxy
mkdir "$mv_proxy_bin"; real_mv=$(command -v mv)
cat > "$mv_proxy_bin/mv" <<'EOF'
#!/bin/sh
case ${MD2PDF_MV_MODE:-}:$1:$2 in
  appear:*/.md2pdf-install.*:*/share/md2pdf)
    mkdir -p "$2" && printf 'concurrent sentinel\n' > "$2/concurrent-sentinel"; exit 1 ;;
  rollback:*/.md2pdf-install.*:*/share/md2pdf|rollback:*/.md2pdf-backup.*:*/share/md2pdf) exit 1 ;;
esac
exec "$MD2PDF_REAL_MV" "$@"
EOF
chmod 755 "$mv_proxy_bin/mv"
concurrent_prefix=$TMP_ROOT/concurrent-prefix
run_status "concurrent destination appearance fails closed" 1 env PATH="$mv_proxy_bin:$PATH" MD2PDF_REAL_MV="$real_mv" MD2PDF_MV_MODE=appear "$ROOT/install.sh" --prefix "$concurrent_prefix"
if [ -f "$concurrent_prefix/share/md2pdf/concurrent-sentinel" ]; then pass "concurrent destination is not recursively deleted"; else fail "concurrent destination is not recursively deleted"; fi

rollback_prefix=$TMP_ROOT/rollback-prefix
run_status "rollback test installation succeeds" 0 "$ROOT/install.sh" --prefix "$rollback_prefix"
run_status "publication and restoration failure is reported" 1 env PATH="$mv_proxy_bin:$PATH" MD2PDF_REAL_MV="$real_mv" MD2PDF_MV_MODE=rollback "$ROOT/install.sh" --prefix "$rollback_prefix"
assert_contains "restoration failure identifies the preserved backup" "cannot restore the previous runtime; backup remains at" "$last_stderr"
set -- "$rollback_prefix/share"/.md2pdf-backup.*/.install-manifest
if [ ! -e "$rollback_prefix/share/md2pdf" ] && [ -f "$1" ]; then pass "failed rollback leaves the prior installation in a known backup"; else fail "failed rollback leaves the prior installation in a known backup"; fi

run_status "installed uninstaller dry-run succeeds" 0 \
  env HOME="$install_home" XDG_BIN_HOME="$install_bin" XDG_DATA_HOME="$install_data" \
    "$installed_data/uninstall.sh" --dry-run
if [ -x "$installed_cli" ]; then
  pass "uninstall dry-run leaves launcher installed"
else
  fail "uninstall dry-run leaves launcher installed"
fi
run_status "default XDG uninstallation succeeds" 0 \
  env HOME="$install_home" XDG_BIN_HOME="$install_bin" XDG_DATA_HOME="$install_data" \
    "$installed_data/uninstall.sh"
assert_absent "uninstall removes only the installed launcher" "$installed_cli"
assert_absent "uninstall removes a known runtime file" "$installed_data/filters/runtime.lua"
if [ -f "$install_bin/unrelated-sentinel" ] && \
   [ -f "$installed_data/unrelated-sentinel" ]; then
  pass "uninstall preserves unrelated sentinel files"
else
  fail "uninstall preserves unrelated sentinel files"
fi

install_prefix=$TMP_ROOT/custom-prefix
printf 'prefix sentinel\n' > "$TMP_ROOT/prefix-sentinel"
run_status "custom prefix installation succeeds" 0 \
  env HOME="$install_home" "$ROOT/install.sh" --prefix "$install_prefix"
run_status "custom prefix launcher reports version" 0 \
  "$install_prefix/bin/md2pdf" --version
assert_contains "custom prefix uses the public version" "md2pdf 0.1.0" "$last_stdout"
run_status "custom prefix uninstallation succeeds" 0 \
  env HOME="$install_home" "$install_prefix/share/md2pdf/uninstall.sh" \
    --prefix "$install_prefix"
assert_absent "custom prefix launcher is removed" "$install_prefix/bin/md2pdf"
if [ -f "$TMP_ROOT/prefix-sentinel" ]; then
  pass "custom prefix uninstall preserves outside sentinel"
else
  fail "custom prefix uninstall preserves outside sentinel"
fi

run_status "installer rejects the filesystem root as a prefix" 1 \
  "$ROOT/install.sh" --prefix / --dry-run
run_status "uninstaller rejects an empty prefix" 2 \
  "$ROOT/uninstall.sh" --prefix=

run_status "launcher passes POSIX shell syntax" 0 sh -n "$CLI"
run_status "test runner passes POSIX shell syntax" 0 sh -n "$ROOT/tests/run.sh"
run_status "installer passes POSIX shell syntax" 0 sh -n "$ROOT/install.sh"
run_status "uninstaller passes POSIX shell syntax" 0 sh -n "$ROOT/uninstall.sh"
run_status "curl fixture passes POSIX shell syntax" 0 sh -n "$SOURCE/mock-curl"
run_status "Typst proxy fixture passes POSIX shell syntax" 0 sh -n "$SOURCE/typst-proxy"

non_git_root=$TMP_ROOT/non-git-copy
mkdir -p "$non_git_root"
cp "$CLI" "$non_git_root/md2pdf"
cp -R "$ROOT/share" "$non_git_root/share"
cp -R "$ROOT/tests" "$non_git_root/tests"
run_status "test harness runs from a non-Git source copy" 0 \
  env MD2PDF_TEST_NON_GIT_CHILD=1 "$non_git_root/tests/run.sh"

if command -v git >/dev/null 2>&1 && \
   git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  run_status "worktree has no whitespace errors" 0 git -C "$ROOT" diff --check
else
  pass "whitespace check is skipped outside a Git worktree"
fi

total=$((passed + failed))
printf '%s tests passed; %s tests failed; %s total\n' "$passed" "$failed" "$total"
[ "$failed" -eq 0 ]
