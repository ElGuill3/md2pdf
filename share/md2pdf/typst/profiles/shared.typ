#let serif-fonts = (
  "Libertinus Serif",
  "Noto Serif",
  "Noto Serif CJK SC",
  "Noto Naskh Arabic",
  "Noto Serif Hebrew",
  "Noto Sans Symbols 2",
)

#let sans-fonts = (
  "Noto Sans",
  "Noto Sans CJK SC",
  "Noto Sans Arabic",
  "Noto Sans Hebrew",
  "Noto Sans Symbols 2",
)

#let mono-fonts = (
  "IosevkaTerm NF",
  "Noto Sans Mono",
  "Noto Sans Mono CJK SC",
  "DejaVu Sans Mono",
)

#let profile(
  name: "general",
  body-fonts: serif-fonts,
  accent: rgb("#1a3c6e"),
  accent-light: rgb("#2563a8"),
  accent-gold: rgb("#c2a24a"),
  text-size: 11pt,
  code-size: 9pt,
  table-size: 8.5pt,
  table-inset: (x: 4pt, y: 5pt),
  paragraph-leading: 0.75em,
  paragraph-spacing: 1.1em,
  heading-style: "general",
  cover-style: "general",
  footnote-size: 9pt,
  equation-numbering: none,
) = (
  name: name,
  colors: (
    accent: accent,
    accent-light: accent-light,
    accent-gold: accent-gold,
    gray-mid: rgb("#777f89"),
    gray-light: rgb("#c8ced6"),
    code-fill: rgb("#e8f0fb"),
    code-block: rgb("#1e1e2e"),
    code-text: rgb("#cdd6f4"),
  ),
  fonts: (
    body: body-fonts,
    mono: mono-fonts,
  ),
  text-size: text-size,
  code-size: code-size,
  table-size: table-size,
  table-inset: table-inset,
  paragraph-leading: paragraph-leading,
  paragraph-spacing: paragraph-spacing,
  heading-style: heading-style,
  cover-style: cover-style,
  footnote-size: footnote-size,
  equation-numbering: equation-numbering,
)
