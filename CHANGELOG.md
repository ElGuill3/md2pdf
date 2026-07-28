# Changelog

All notable changes to this project are documented here.

## [Unreleased]

## [0.2.0] - 2026-07-28

### Added

- Reusable `md2pdf` agent skill with guided workflows for creating Markdown from
  scratch or adapting existing documents before rendering.
- Multi-agent skill installer, user documentation, and deterministic contract
  tests for Codex, OpenCode, Claude Code, and Gemini CLI.

### Changed

- Product identity and remote-image user agent now report `0.2.0` consistently.
- The product installer safely upgrades managed `0.1.0` installations while
  continuing to reject malformed or mismatched ownership evidence.

### Retained From 0.1.0

These user-visible improvements were delivered after the initial `0.1.0`
changelog entry but are already included in the published `v0.1.0` tag:

- Conversion stages are reported on stderr; quiet mode suppresses progress and
  the final success message without hiding warnings or errors.
- Temporary and reported output paths are normalized consistently on macOS.
- Generated PDFs omit automatic profile labels.
- Table layout avoids code overlap, moves path-dense tables to landscape, and
  wraps long code correctly when fallback fonts are used.

## [0.1.0] - 2026-07-14

### Added

- POSIX `md2pdf` CLI with atomic PDF publication and stable exit codes.
- General, Technical, Report, and Academic Typst profiles.
- Typed YAML metadata, English/Spanish labels, citations, semantic alerts, and
  confined local resources.
- Bounded HTTPS images with visible failure placeholders and documented network
  trust boundaries.
- User-local and custom-prefix installation with safe known-file uninstall.
- Linux and macOS CI using Pandoc 3.8, Typst 0.15.0, Poppler, and real PDF tests.
