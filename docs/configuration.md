# Configure one source for the right PDF

Use YAML front matter to select a profile, describe the document, and override
only the layout decisions that need to differ. Invalid types and unknown
`md2pdf` keys fail early with a path-specific diagnostic.

## Precedence

Configuration is applied in this order, from lowest to highest priority:

1. General defaults.
2. The selected profile defaults.
3. Standard top-level structure keys such as `toc` and `number-sections`.
4. Explicit values inside `md2pdf`.

Profile selection itself is `--profile`, then `md2pdf.profile`, then the legacy
top-level `profile` alias, then `general`. Do not set both YAML profile forms.

## Document Metadata

| Key | Type | Effect |
|---|---|---|
| `title` | String | PDF title and cover title; default `Document` |
| `subtitle` | String | Optional cover subtitle |
| `author` or `authors` | Author or list | Author names, affiliations, and email metadata |
| `date` | String | Optional cover and report furniture date |
| `lang` | BCP-47-like tag | Hyphenation language and English/Spanish labels |

An author can be a string or a mapping:

```yaml
author:
  - name: Ada Example
    affiliation:
      - Systems Laboratory
      - Documentation Group
    email: ada@example.com
  - Grace Example
```

`affiliation` accepts a string or list of strings. `email` is a string and is
written to PDF keywords as `author-email:<address>`; it is not silently dropped.

## Layout Schema

```yaml
md2pdf:
  profile: report
  cover: true
  toc:
    enabled: true
    depth: 3
  section-numbering: true
  page:
    paper: letter
    orientation: portrait
    margins:
      top: 1in
      bottom: 1in
      left: 0.9in
      right: 0.9in
  header:
    enabled: true
    text: Quarterly Review
  footer:
    enabled: true
    text: Public
    numbering: true
```

| `md2pdf` key | Accepted value |
|---|---|
| `profile` | `general`, `technical`, `report`, or `academic` |
| `cover` | Boolean |
| `toc` | Boolean, or `{enabled: boolean, depth: 1..6}` |
| `toc-depth` | Integer `1..6`; compatibility alias |
| `section-numbering` | Boolean |
| `number-sections` | Boolean; compatibility alias |
| `page.paper` | `a3`, `a4`, `a5`, `letter`, or `legal` |
| `page.orientation` | `portrait` or `landscape` |
| `page.margins` | One length or a side mapping |
| `header` | Boolean, or `{enabled: boolean, text: string}` |
| `footer` | Boolean, or `{enabled: boolean, text: string, numbering: boolean}` |

Lengths are non-negative numbers followed by `pt`, `mm`, `cm`, or `in`.

Top-level `toc`, `toc-depth`, and `number-sections` remain accepted for Pandoc
compatibility. Prefer the namespaced schema for new documents.

## Profile Defaults

| Profile | Cover | Contents | Section numbers | Distinguishing defaults |
|---|---:|---:|---:|---|
| `general` | Yes | Depth 3 | No | A4, balanced margins |
| `technical` | Yes | Depth 4 | Yes | Compact margins and sans body |
| `report` | Yes | Depth 3 | Yes | Wider formal margins |
| `academic` | Yes | No | Yes | Restrained margins and numbered equations |

Any explicit layout value is applied after these defaults.

## Citations

```yaml
bibliography:
  - references/core.bib
  - references/supplement.bib
csl: references/numeric.csl
```

`bibliography` accepts one source-relative `.bib` path or a list. `csl` accepts
one source-relative `.csl` path. Inline Pandoc `references` records are also
recognized. Every citation key must resolve before citeproc runs.

The paths must stay beneath the Markdown source directory and must not traverse
symlinks. Network bibliography and CSL URLs are not accepted.

## Resource Rules

Local image paths are URL-decoded, resolved from the Markdown directory, checked
for traversal and symlinks, and copied into a temporary stage. Query strings and
fragments are not accepted on local paths.

Remote images must use HTTPS. Each distinct URL is attempted at most once per
conversion. Redirects remain HTTPS-only and are capped at five. Connect and total
timeouts are 5 and 20 seconds. Payloads are limited to 5 MiB with curl's transfer
limit, a process file-size limit where available, and a final byte check.
Accepted response types are PNG, JPEG, GIF, SVG, and WebP with matching payload
signatures.

See [Compatibility](compatibility.md) for the network trust boundary and font
policy.
