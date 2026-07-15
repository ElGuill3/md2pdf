#import "shared.typ": profile

// Restrained academic rhythm emphasizes references, notes, and numbered structure.
#let academic = profile(
  name: "academic",
  accent: rgb("#263b55"),
  accent-light: rgb("#4b6178"),
  accent-gold: rgb("#9c8240"),
  text-size: 10.75pt,
  code-size: 8.5pt,
  table-size: 8pt,
  table-inset: (x: 3.5pt, y: 4pt),
  paragraph-leading: 0.82em,
  paragraph-spacing: 0.72em,
  heading-style: "academic",
  cover-style: "academic",
  footnote-size: 8.25pt,
  equation-numbering: "(1)",
)
