# Know what will render consistently

`md2pdf 0.1.0` supports current Linux and macOS systems with POSIX `sh`, Pandoc
3.8, Typst 0.15, and curl for HTTPS images. Poppler is needed only for the test
suite and visual inspection.

## Tool Boundary

| Tool | Supported baseline | Role |
|---|---|---|
| Pandoc | 3.8 | Markdown parsing, citations, Typst generation |
| Typst | 0.15.0 | PDF compilation and diagnostics |
| curl | System version | Bounded HTTPS image retrieval |
| Poppler | Current | Tests: metadata, text, fonts, and raster evidence |

Linux and macOS run the same shell suite in CI. BSD and GNU `stat` forms are both
covered. Windows paths, shells, and packaging are outside the current boundary.

## Markdown Boundary

The CLI reads `markdown+yaml_metadata_block-raw_attribute-raw_html-raw_tex`.
This deliberately supports common Pandoc Markdown while removing executable or
format-specific escape hatches.

Covered by real conversion tests:

- YAML metadata and the four profiles
- Headings through level four, section numbering, and contents depth
- Emphasis, links, lists, terms, quotes, strikeout, and footnotes
- Inline and fenced code
- Pipe and long tables, including wide-table landscape pages
- Local SVG and bounded remote images
- Inline/display math and academic equation numbering
- BibTeX/CSL citations and localized reference headings
- English and Spanish labels plus Greek, CJK, Arabic, and Hebrew glyph fallback
- GitHub-style semantic alert quotes

Not promised:

- Browser HTML/CSS rendering
- Complete CommonMark or GFM equivalence
- Raw Typst, raw TeX, raw HTML, or raw attributes
- Complete right-to-left or bidi layout behavior
- Arbitrary Pandoc readers selected at runtime

## Font Policy

Fonts are resolved in a fixed order, but they are not bundled.

| Use | Preferred | Ordered fallbacks |
|---|---|---|
| General/report/academic body | Libertinus Serif | Noto Serif, Noto Serif CJK SC, Noto Naskh Arabic, Noto Serif Hebrew, Noto Sans Symbols 2 |
| Technical body | Noto Sans | Noto Sans CJK SC, Noto Sans Arabic, Noto Sans Hebrew, Noto Sans Symbols 2 |
| Code | IosevkaTerm NF | Noto Sans Mono, Noto Sans Mono CJK SC, DejaVu Sans Mono |

Run `typst fonts` to inspect the current host. Before every conversion, `md2pdf`
checks the profile's preferred body family and the preferred code family. A
missing preferred family emits a warning and the ordered fallback remains in
effect. Typst missing-glyph warnings are also preserved on successful builds.

The verified Linux development host provides Libertinus Serif, Noto Sans,
IosevkaTerm NF, the listed Noto script fallbacks, and DejaVu Sans Mono. Other
hosts can render successfully with fallbacks, but identical pagination and PDF
bytes require the same font files and tool versions.

## Network Trust Boundary

Remote image handling reduces accidental exposure but is not an SSRF sandbox.
The source URL must use HTTPS; redirects may only remain on HTTPS; obvious
localhost names and private, loopback, and link-local IP literals are rejected;
timeouts, transfer size, MIME, and signatures are bounded.

DNS resolution happens inside curl. A public-looking hostname can resolve to a
private address or change through DNS rebinding. Redirect targets are not
pre-resolved and IP-filtered before connection. For untrusted Markdown, run the
converter in an environment whose network policy blocks private and sensitive
destinations, or disable network access entirely.

## Current Limitations

- Linux and macOS only; no Windows installer or path model.
- Pandoc and Typst are external runtime dependencies.
- curl is required only when a document contains an HTTPS image.
- Fonts are external and can change line breaks, pagination, and glyph coverage.
- Remote image failures produce placeholders rather than failing conversion.
- Tables with more than five columns switch to landscape. Tables with three to
  five columns also switch when inline-code paths are dense enough to require
  the extra width; content width is not otherwise measured.
- Spanish and English labels are built in; other languages use English labels.
- Full bidi behavior and perfect network isolation are not claimed.
