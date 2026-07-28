# md2pdf Format Contract

- Input is Pandoc Markdown with YAML front matter.
- Profiles are `general`, `technical`, `report`, and `academic`.
- Standard metadata includes `title`, `subtitle`, `author` or `authors`, `date`, and `lang`. Never invent these values.
- Supported `md2pdf` keys are `profile`, `cover`, `toc`, `toc-depth`, `section-numbering`, `number-sections`, `page`, `header`, and `footer`; unknown keys fail.
- `toc` accepts a boolean or `{enabled, depth}` with depth `1..6`. `page` accepts `paper` (`a3`, `a4`, `a5`, `letter`, `legal`), `orientation` (`portrait`, `landscape`), and `margins`. `header` accepts a boolean or `{enabled, text}`; `footer` also accepts `numbering`.
- Resolve local images, `.bib` files, and `.csl` files relative to the Markdown source. Do not use absolute paths, traversal, or symlinks.
- HTTPS images are best effort and can become visible placeholders.
- Raw HTML, TeX, Typst, and attributes are unsupported or inert.
- Render with the CLI and preserve its diagnostics. Inspect rendered pages before making visual-quality claims.
