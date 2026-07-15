#let horizontalrule = {
  let accent-gold = rgb("#c2a24a")
  let gray-light = rgb("#cccccc")
  v(0.5em)
  grid(
    columns: (1fr, 10pt, 1fr),
    gutter: 0pt,
    align(horizon, line(length: 100%, stroke: gradient.linear(rgb("#ffffff00"), gray-light))),
    align(horizon, circle(radius: 2.5pt, fill: accent-gold)),
    align(horizon, line(length: 100%, stroke: gradient.linear(gray-light, rgb("#ffffff00")))),
  )
  v(0.5em)
}

#let alert-label(lang, kind) = {
  let normalized = lower(lang)
  let spanish = normalized == "es" or normalized.starts-with("es-")
  let labels = if spanish {
    (
      note: "Nota",
      tip: "Consejo",
      important: "Importante",
      warning: "Advertencia",
      caution: "Precaución",
    )
  } else {
    (
      note: "Note",
      tip: "Tip",
      important: "Important",
      warning: "Warning",
      caution: "Caution",
    )
  }
  labels.at(kind)
}

#let alert-box(kind, body, lang: "en") = {
  let colors = (
    note: rgb("#2563a8"),
    tip: rgb("#2f7d57"),
    important: rgb("#6b4fa1"),
    warning: rgb("#b7791f"),
    caution: rgb("#b53b3b"),
  )
  let accent = colors.at(kind)
  block(
    width: 100%,
    breakable: true,
    fill: accent.lighten(91%),
    stroke: (left: 4pt + accent),
    inset: (x: 12pt, y: 9pt),
    radius: (right: 4pt),
    {
      text(size: 9pt, weight: "bold", tracking: 0.5pt, fill: accent, alert-label(lang, kind))
      v(0.25em)
      body
    },
  )
}

#let heading-content(it, numbered: false, uppercase: false) = context {
  if numbered {
    counter(heading).display("1.1.1.")
    h(0.5em)
  }
  if uppercase { upper(it.body) } else { it.body }
}

#let apply-theme(config, theme, body) = {
  let accent = theme.colors.accent
  let accent-light = theme.colors.accent-light
  let accent-gold = theme.colors.accent-gold
  let gray-mid = theme.colors.gray-mid
  let gray-light = theme.colors.gray-light

  set heading(numbering: if config.section_numbering { "1.1.1." } else { none })

  show heading.where(level: 1): it => {
    if theme.heading-style == "technical" {
      v(1em)
      block(
        width: 100%,
        fill: accent.lighten(92%),
        stroke: (left: 4pt + accent-gold),
        inset: (x: 10pt, y: 6pt),
        text(size: 15pt, weight: "bold", fill: accent, heading-content(it, numbered: config.section_numbering)),
      )
      v(0.35em)
    } else if theme.heading-style == "report" {
      v(1.7em)
      grid(
        columns: (4pt, 1fr),
        gutter: 10pt,
        rect(width: 4pt, height: 26pt, fill: accent-gold),
        text(size: 19pt, weight: "bold", fill: accent, heading-content(it, numbered: config.section_numbering)),
      )
      v(0.45em)
    } else if theme.heading-style == "academic" {
      v(1.35em)
      set text(size: 14pt, weight: "bold", fill: accent)
      heading-content(it, numbered: config.section_numbering)
      v(0.25em)
    } else {
      v(1.5em)
      set text(size: 18pt, weight: "bold", fill: accent)
      heading-content(it, numbered: config.section_numbering)
      v(0.25em)
      grid(
        columns: (8pt, 1fr),
        gutter: 6pt,
        align(horizon, circle(radius: 3pt, fill: accent-gold)),
        align(horizon, line(length: 100%, stroke: gradient.linear(accent, rgb("#1a3c6e00")))),
      )
      v(0.5em)
    }
  }

  show heading.where(level: 2): it => {
    v(if theme.heading-style == "technical" { 0.7em } else { 1em })
    if theme.heading-style == "academic" {
      set text(size: 11pt, weight: "bold", fill: accent)
      heading-content(it, numbered: config.section_numbering)
    } else {
      set text(size: 10pt, weight: "bold", fill: accent-light, tracking: 0.8pt)
      heading-content(it, numbered: config.section_numbering, uppercase: true)
    }
    v(0.2em)
  }

  show heading.where(level: 3): it => {
    v(0.8em)
    set text(size: 11pt, weight: "bold", fill: accent-light)
    heading-content(it, numbered: config.section_numbering)
    v(0.1em)
  }

  show heading.where(level: 4): it => {
    v(0.6em)
    set text(size: 10pt, weight: "bold", fill: gray-mid)
    heading-content(it, numbered: config.section_numbering)
    v(0.1em)
  }

  show raw.where(block: false): it => {
    text(
      font: theme.fonts.mono,
      size: theme.code-size,
      fill: accent,
      highlight(fill: theme.colors.code-fill, radius: 3pt, it),
    )
  }

  show raw.where(block: true): it => {
    let language = if it.lang != none {
      box(
        fill: rgb("#313244"),
        inset: (x: 8pt, y: 3pt),
        radius: (top-left: 4pt, top-right: 4pt),
        text(font: theme.fonts.mono, size: 8pt, fill: rgb("#89b4fa"), it.lang),
      )
    } else {
      none
    }

    v(0.4em)
    stack(
      dir: ttb,
      if language != none { language } else { v(0pt) },
      block(
        width: 100%,
        fill: theme.colors.code-block,
        inset: if theme.name == "technical" { 10pt } else { 14pt },
        radius: if it.lang != none {
          (top-left: 0pt, top-right: 4pt, bottom-left: 6pt, bottom-right: 6pt)
        } else {
          6pt
        },
        {
          set text(font: theme.fonts.mono, size: theme.code-size, fill: theme.colors.code-text)
          set par(leading: if theme.name == "technical" { 0.45em } else { 0.55em })
          it
        },
      ),
    )
    v(0.4em)
  }

  set table(
    stroke: (x, y) => if y == 0 {
      (bottom: 2pt + accent)
    } else {
      (bottom: 0.5pt + rgb("#e0e0e0"))
    },
    fill: (_, y) => if y == 0 {
      rgb("#f0f4f8")
    } else if calc.odd(y) {
      white
    } else {
      rgb("#f8fafc")
    },
    inset: theme.table-inset,
  )
  show table: set text(size: theme.table-size, hyphenate: true)
  show table: set par(justify: false, linebreaks: "optimized")
  show figure.where(kind: table): set block(breakable: true)
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.where(kind: image): set figure.caption(position: bottom)
  show figure.caption: it => {
    set text(size: 9pt, style: "italic", fill: gray-mid)
    it
  }

  show link: it => {
    set text(fill: accent-light)
    underline(it)
  }

  set list(
    indent: 8pt,
    marker: (
      text(fill: accent, size: 11pt, sym.bullet),
      text(fill: accent-light, size: 9pt, sym.circle.stroked),
      text(fill: gray-mid, size: 9pt, sym.square.stroked),
    ),
  )
  set enum(indent: 8pt, numbering: "1.a.i.")

  show terms: it => {
    for child in it.children {
      grid(
        columns: (auto, 1fr),
        gutter: 8pt,
        text(weight: "bold", fill: accent, child.term),
        block(inset: (left: 0pt), child.description),
      )
      v(0.3em)
    }
  }

  set quote(block: true)
  show quote.where(block: true): it => {
    block(
      width: 100%,
      inset: (left: 20pt, right: 8pt, top: 8pt, bottom: 8pt),
      stroke: (left: 3pt + accent-gold),
      fill: rgb("#f8f6f0"),
      {
        place(
          dx: -16pt,
          dy: -2pt,
          text(size: 28pt, fill: accent-gold, weight: "bold", ["]),
        )
        text(style: "italic", fill: rgb("#444444"), it.body)
      },
    )
  }

  set footnote.entry(
    separator: line(length: 30%, stroke: 0.5pt + gray-light),
    gap: 0.5em,
  )
  show footnote.entry: it => {
    set text(size: theme.footnote-size, fill: if theme.name == "academic" { accent } else { gray-mid })
    it
  }

  show strike: it => {
    set text(fill: gray-mid)
    it
  }

  set math.equation(numbering: theme.equation-numbering)
  show math.equation.where(block: true): it => {
    v(0.3em)
    align(center, it)
    v(0.3em)
  }

  body
}
