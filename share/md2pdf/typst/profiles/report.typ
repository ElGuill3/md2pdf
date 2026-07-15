#import "shared.typ": profile

// Formal reports use a strong cover, chapter-like hierarchy, and sober furniture.
#let report = profile(
  name: "report",
  accent: rgb("#17365d"),
  accent-light: rgb("#315b82"),
  accent-gold: rgb("#b08d35"),
  text-size: 11pt,
  table-size: 8.25pt,
  paragraph-leading: 0.78em,
  paragraph-spacing: 1.2em,
  heading-style: "report",
  cover-style: "report",
)
