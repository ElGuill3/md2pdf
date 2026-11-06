#!/bin/sh

# Documentation checks: relative links and anchors resolve, every option in
# `md2pdf --help` is documented in README.md, and version surfaces agree.
# Usage: tests/docs.sh [ROOT]   (ROOT defaults to this checkout)

set -u
LC_ALL=C
export LC_ALL

if [ "$#" -gt 0 ]; then
  ROOT=$(CDPATH= cd -P "$1" && pwd -P) || exit 1
else
  ROOT=$(CDPATH= cd -P "$(dirname "$0")/.." && pwd -P) || exit 1
fi
cd "$ROOT" || exit 1

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

# Print the GitHub anchor of every heading in a Markdown file, one per line.
anchors() {
  awk '
    /^[ ]*(```|~~~)/ { fence = !fence; next }
    fence || !/^#+[ \t]/ { next }
    {
      text = $0
      sub(/^#+[ \t]+/, "", text)
      sub(/[ \t]+#*[ \t]*$/, "", text)
      gsub(/\]\([^)]*\)/, "", text)
      slug = ""
      for (i = 1; i <= length(text); i++) {
        c = substr(text, i, 1)
        if (c ~ /[A-Z]/) slug = slug tolower(c)
        else if (c ~ /[a-z0-9_-]/) slug = slug c
        else if (c == " ") slug = slug "-"
        else if (c > "~") slug = slug c
      }
      if (slug in seen) {
        seen[slug]++
        print slug "-" seen[slug]
      } else {
        seen[slug] = 0
        print slug
      }
    }
  ' "$1"
}

# Print "line<TAB>target" for each relative inline link outside code.
relative_links() {
  awk '
    /^[ ]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    {
      line = $0
      gsub(/`[^`]*`/, "", line)
      while (match(line, /\]\([^) \t]+/)) {
        target = substr(line, RSTART + 2, RLENGTH - 2)
        line = substr(line, RSTART + RLENGTH)
        if (target ~ /^[a-zA-Z][a-zA-Z0-9+.-]*:/) continue
        printf "%d\t%s\n", NR, target
      }
    }
  ' "$1"
}

markdown_files=$(
  {
    for file in README.md CONTRIBUTING.md CHANGELOG.md; do
      [ -f "$file" ] && printf '%s\n' "$file"
    done
    for dir in docs skills; do
      [ -d "$dir" ] && find "$dir" -type f -name '*.md'
    done
  } | sort
)

tab=$(printf '\t')
link_errors=$(
  for file in $markdown_files; do
    dir=$(dirname "$file")
    relative_links "$file" | while IFS=$tab read -r line target; do
      path=${target%%#*}
      anchor=
      case $target in
        # The leading parenthesis keeps bash 3.2 (macOS sh) from ending the
        # command substitution at the pattern's closing parenthesis.
        (*'#'*) anchor=${target#*#} ;;
      esac
      if [ -z "$path" ]; then
        resolved=$file
      else
        resolved=$dir/$path
      fi
      if [ ! -e "$resolved" ]; then
        printf '  %s:%s: missing link target %s\n' "$file" "$line" "$target"
      elif [ -n "$anchor" ] && [ -f "$resolved" ] &&
        ! anchors "$resolved" | grep -Fqx -- "$anchor"; then
        printf '  %s:%s: missing anchor %s\n' "$file" "$line" "$target"
      fi
    done
  done
)
if [ -n "$link_errors" ]; then
  printf '%s\n' "$link_errors" >&2
  fail "relative links and anchors resolve"
else
  pass "relative links and anchors resolve"
fi

help_output=$("$ROOT/md2pdf" --help 2>&1)
help_status=$?
options=$(printf '%s\n' "$help_output" | awk '
  /^Options:/ { in_options = 1; next }
  in_options && /^[ \t]*$/ { exit }
  in_options {
    for (i = 1; i <= NF && $i ~ /^-/; i++) {
      option = $i
      sub(/,$/, "", option)
      print option
      if ($i !~ /,$/) break
    }
  }
')
undocumented=
for option in $options; do
  if ! grep -q "\`${option}[\` ]" README.md; then
    undocumented="$undocumented $option"
  fi
done
if [ "$help_status" -ne 0 ]; then
  printf '  md2pdf --help exited with %s\n' "$help_status" >&2
  fail "help options are documented in README.md"
elif [ -z "$options" ]; then
  printf '  md2pdf --help lists no options\n' >&2
  fail "help options are documented in README.md"
elif [ -n "$undocumented" ]; then
  printf '  README.md does not document:%s\n' "$undocumented" >&2
  fail "help options are documented in README.md"
else
  pass "help options are documented in README.md"
fi

version=$(sed -n 's/^VERSION=\([0-9][0-9.]*\)$/\1/p' md2pdf | head -n 1)
version_errors=
require() {
  if ! grep -Fq -- "$2" "$1" 2> /dev/null; then
    version_errors="$version_errors
  $1 does not contain $2"
  fi
}
if [ -z "$version" ]; then
  printf '  md2pdf does not define VERSION\n' >&2
  fail "version surfaces agree"
else
  require md2pdf "INSTALL_SIGNATURE='md2pdf-public-launcher-$version'"
  require install.sh "VERSION=$version"
  require uninstall.sh "VERSION=$version"
  require uninstall.sh "INSTALL_SIGNATURE='md2pdf-public-launcher-$version'"
  require share/md2pdf/filters/runtime.lua "md2pdf/$version"
  require CHANGELOG.md "## [$version]"
  stale=$(grep -n -E 'md2pdf [0-9]+\.[0-9]+\.[0-9]+' README.md docs/*.md \
    2> /dev/null | grep -v -F -- "md2pdf $version")
  if [ -n "$stale" ]; then
    version_errors="$version_errors
$(printf '%s\n' "$stale" | sed 's/^/  stale version: /')"
  fi
  if [ -n "$version_errors" ]; then
    printf '%s\n' "${version_errors#?}" >&2
    fail "version surfaces agree with md2pdf $version"
  else
    pass "version surfaces agree with md2pdf $version"
  fi
fi

total=$((passed + failed))
printf '%s checks passed; %s checks failed; %s total\n' "$passed" "$failed" "$total"
[ "$failed" -eq 0 ]
