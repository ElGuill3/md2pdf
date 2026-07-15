# Turn Markdown into a polished PDF

`md2pdf` converts one Markdown file into a styled, self-contained PDF through
Pandoc 3.8 and Typst 0.15. Choose a balanced, technical, report, or academic
profile without maintaining a document template of your own.

## Quick Install

From a release or source checkout:

```sh
./install.sh
export PATH="${XDG_BIN_HOME:-$HOME/.local/bin}:$PATH"
md2pdf --version
```

The installer writes only to user-controlled paths, never uses `sudo`, and does
not install Pandoc, Typst, curl, or fonts. See [Installation](#installation) for
custom prefixes and uninstall instructions.

## First Conversion

```sh
md2pdf notes.md
```

The result is `notes.pdf` beside the source. The PDF is published atomically, so
a failed conversion does not replace an existing output.

Select a profile or output path when needed:

```sh
md2pdf --profile technical --output build/notes.pdf notes.md
```

## CLI

| Option | Outcome |
|---|---|
| `-o FILE`, `--output FILE` | Writes the PDF to `FILE`. |
| `--profile NAME` | Selects `general`, `technical`, `report`, or `academic`. |
| `--version` | Prints `md2pdf 0.1.0`. |
| `-h`, `--help` | Prints usage and exit codes. |

`md2pdf INPUT OUTPUT` remains available as a positional compatibility form. Do
not combine it with `--output`.

## Add Document Metadata

Put standard metadata and `md2pdf` layout controls in YAML front matter:

```yaml
---
title: System Design
subtitle: Public API and operating model
author:
  - name: Ada Example
    affiliation: Systems Laboratory
    email: ada@example.com
date: 2026-07-14
lang: en-US
md2pdf:
  profile: technical
  toc:
    enabled: true
    depth: 3
  page:
    paper: a4
    margins: 2cm
  footer:
    text: Internal draft
    numbering: true
---
```

Author email addresses are retained intentionally in PDF keywords as
`author-email:<address>`. Unknown keys inside `md2pdf` are rejected rather than
silently ignored.

### Profiles

| Profile | Best for | Default character |
|---|---|---|
| `general` | Mixed prose, figures, code, and tables | Balanced serif body, cover, contents, unnumbered sections |
| `technical` | Specifications and engineering notes | Compact sans body, dense tables, numbered sections |
| `report` | Formal organizational reports | Strong cover, generous margins, numbered hierarchy |
| `academic` | Papers, citations, equations, and notes | Restrained serif rhythm, numbered sections and equations |

CLI profile selection wins over YAML. Explicit YAML layout values then override
the selected profile defaults. The full precedence and accepted schema are in
[Configuration](docs/configuration.md).

## Citations

Use Pandoc citations with source-relative bibliography and CSL paths:

```yaml
---
bibliography: references/library.bib
csl: references/style.csl
---
```

```markdown
The runtime is isolated from the source tree [@lamport1994].
```

Bibliographies must be `.bib` files and styles must be `.csl` files. Missing,
invalid, escaping, symlinked, or unresolved citation resources stop conversion.
English documents receive `References`; BCP-47 tags `es`, `ES`, and `es-*` use
`Referencias`.

## Images And Resources

Local images resolve relative to the Markdown file. Absolute paths, traversal
outside the source directory, and symlink traversal are rejected. Source files
are never modified during conversion.

HTTPS images are best effort. They use HTTPS-only redirects, bounded timeouts,
a 5 MiB transfer policy, MIME and signature validation, and cached outcomes for
repeated URLs. A failed remote image becomes a visible linked placeholder; it
does not fail the whole document. HTTP and `file:` URLs are never fetched.

This is not a complete network sandbox. See [Security And Trust](#security-and-trust)
before converting untrusted documents.

## Supported Markdown

The supported path is Pandoc Markdown with YAML metadata. Headings, emphasis,
links, local and remote images, lists, block quotes, fenced code, tables,
footnotes, math, citations, and GitHub-style `NOTE`, `TIP`, `IMPORTANT`,
`WARNING`, and `CAUTION` quote alerts are covered by the real-tool suite.

Raw HTML, raw TeX, raw Typst, and raw attributes are disabled or rendered inert.
The converter is not a browser and does not promise complete CommonMark/GFM
parity. Detailed boundaries are in [Compatibility](docs/compatibility.md).

## Error Behavior

| Exit | Meaning |
|---:|---|
| `0` | Success, help, or version output |
| `2` | Invalid CLI usage |
| `3` | Invalid input or output path |
| `4` | Invalid metadata, runtime data, citation, or local resource |
| `5` | Missing Pandoc or Typst |
| `6` | Pandoc or Typst conversion failure |
| `7` | Atomic PDF publication failure |

Pandoc and Typst diagnostics are preserved on failure. Non-empty Typst warnings,
including missing-glyph warnings, remain visible even when compilation succeeds.
No partial PDF is published.

## Installation

The default layout is:

| Content | Path |
|---|---|
| Launcher | `${XDG_BIN_HOME:-$HOME/.local/bin}/md2pdf` |
| Runtime | `${XDG_DATA_HOME:-$HOME/.local/share}/md2pdf` |
| Uninstaller | `${XDG_DATA_HOME:-$HOME/.local/share}/md2pdf/uninstall.sh` |

Preview or choose a self-contained prefix:

```sh
./install.sh --dry-run
./install.sh --prefix "$HOME/.local"
```

Uninstall with the same environment or prefix:

```sh
"${XDG_DATA_HOME:-$HOME/.local/share}/md2pdf/uninstall.sh"
# or
"$HOME/.local/share/md2pdf/uninstall.sh" --prefix "$HOME/.local"
```

Reinstallation is idempotent. The uninstaller validates the managed marker and
launcher, removes only known `md2pdf` files, and leaves unrelated files intact.

## Troubleshooting

| Symptom | Check |
|---|---|
| `md2pdf: command not found` | Add the reported binary directory to `PATH`. |
| `required dependency not found` | Install Pandoc 3.8+ and Typst 0.15+ separately. |
| Preferred font warning | Install the named family or accept the documented fallback. |
| Missing glyph warning | Install a font covering that script; inspect with `typst fonts`. |
| Remote image placeholder | Check HTTPS, response MIME, image signature, size, and reachability. |
| Citation failure | Keep valid `.bib`/`.csl` files beneath the source directory and resolve every key. |

More platform and font details are in [Compatibility](docs/compatibility.md).

## Development

The test suite performs real PDF conversions and needs Pandoc 3.8, Typst 0.15,
and Poppler tools (`pdfinfo`, `pdftotext`, `pdftoppm`, and `pdffonts`):

```sh
./tests/run.sh
sh -n md2pdf install.sh uninstall.sh tests/run.sh
git diff --check
```

Tests use mock remote transfers and temporary HOME/XDG/prefix directories; they
do not install `md2pdf` into the real user account. Contribution expectations are
in [CONTRIBUTING.md](CONTRIBUTING.md).

## Security And Trust

The Markdown input, metadata, local resources, and citation files should be
treated as document content, not executable Typst. Generated Typst compiles in a
temporary root, local resources are staged from a confined source tree, raw Typst
is blocked, and completed PDFs are atomically published.

Remote fetching blocks obvious localhost names and loopback, link-local, and
private IP literals. DNS remains a trust boundary: a hostname can resolve or
rebind to a private address, and redirect destinations are not pre-resolved and
IP-filtered before curl connects. Convert only trusted documents when network
access is available, or enforce network isolation outside `md2pdf`.

## Compatibility And Limits

`md2pdf 0.1.0` targets current Linux and macOS releases with POSIX `sh`. Windows
is not supported. Fonts are not bundled, so identical bytes and line breaks
require matching font installations. Preferred families and deterministic
fallback order are documented in [Compatibility](docs/compatibility.md), and a
missing preferred family emits a visible warning.

Current limits include external tool dependencies, no complete bidi guarantee,
no perfect SSRF isolation, no browser layout engine, and no bundled fonts.

## License

[MIT](LICENSE), copyright md2pdf contributors.
