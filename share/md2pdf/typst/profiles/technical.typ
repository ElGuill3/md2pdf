#import "shared.typ": profile, sans-fonts

// Dense technical typography prioritizes code, tables, and quick navigation.
#let technical = profile(
  name: "technical",
  body-fonts: sans-fonts,
  accent: rgb("#123d6a"),
  accent-light: rgb("#1672a6"),
  text-size: 10pt,
  code-size: 8pt,
  table-size: 7.6pt,
  table-inset: (x: 3pt, y: 3.5pt),
  paragraph-leading: 0.65em,
  paragraph-spacing: 0.75em,
  heading-style: "technical",
  cover-style: "technical",
  footnote-size: 8pt,
)
