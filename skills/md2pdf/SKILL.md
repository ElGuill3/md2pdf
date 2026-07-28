---
name: md2pdf
description: "Trigger: create, draft, or write Markdown from scratch; prepare, adapt, or format for md2pdf; add metadata, images, or citations; render a PDF."
license: Apache-2.0
metadata:
  author: "ElGuill3"
  version: "1.0"
---

## Activation Contract

Use for creating, drafting, or writing Markdown from scratch; adapting existing Markdown for `md2pdf`; adding metadata, images, or citations; choosing a profile; or rendering a PDF.

## Hard Rules

- In adaptation mode, inspect the source and nearby assets, and preserve meaning.
- Never invent titles, authors, dates, affiliations, citation details, or other facts. Ask only for materially missing business facts.
- Preserve the source by default. If edits are requested or necessary, state which file changed; otherwise work on a clearly named copy.
- Use Pandoc Markdown and the documented `md2pdf` schema. Prefer source-relative local assets, useful image alt text, and source-relative `.bib` and `.csl` files.
- Treat the `md2pdf` CLI as the final validation and rendering authority. Do not duplicate or claim its metadata, resource, citation, or path checks.
- Do not claim visual quality without inspection evidence. A successful command proves rendering, not appearance.

## Decision Gates

| Need | Action |
|---|---|
| Create a new document | Creation mode: establish purpose, audience, scope, and required facts; design a useful structure; draft without invented claims. |
| Change an existing document | Adaptation mode: inspect the source and relevant assets; make the smallest useful changes without changing meaning. |
| Mixed or general document | Use `general`. |
| Engineering specification | Use `technical`. |
| Formal organizational document | Use `report`. |
| Paper with citations or equations | Use `academic`. |
| Factual metadata is missing | Ask for that fact or omit the optional field. |
| Visual quality is requested | Render, then inspect rasterized pages or equivalent evidence. |

## Execution Steps

1. Choose creation or adaptation mode from the request.
2. In creation mode, confirm purpose, audience, scope, output, and materially required facts; design a useful structure; then draft clear content without inventing factual claims.
3. In adaptation mode, read the Markdown, front matter, and relevant resources; change only what the request requires.
4. Add only supported metadata and source-relative resources. Use [the frontmatter template](assets/frontmatter.yaml) selectively.
5. Run `md2pdf --profile NAME --output OUTPUT INPUT`; resolve every CLI error instead of bypassing it.
6. Inspect visual output when requested or needed, and distinguish command success from inspection evidence.

## Output Contract

Return the source path, whether it was created, preserved, or edited, selected profile and rationale, output path, exact render result, inspection evidence if any, and unresolved facts or warnings.

## References

- [Format contract](references/format-contract.md)
- [Frontmatter template](assets/frontmatter.yaml)
