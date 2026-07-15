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

#let apply-theme(theme, body) = {
  let accent = theme.colors.accent
  let accent-light = theme.colors.accent-light
  let accent-gold = theme.colors.accent-gold
  let gray-mid = theme.colors.gray-mid
  let gray-light = theme.colors.gray-light

  show heading.where(level: 1): it => {
    v(1.5em)
    set text(size: 18pt, weight: "bold", fill: accent)
    it
    v(0.25em)
    grid(
      columns: (8pt, 1fr),
      gutter: 6pt,
      align(horizon, circle(radius: 3pt, fill: accent-gold)),
      align(horizon, line(length: 100%, stroke: gradient.linear(accent, rgb("#1a3c6e00")))),
    )
    v(0.5em)
  }

  show heading.where(level: 2): it => {
    v(1em)
    set text(size: 10pt, weight: "bold", fill: accent-light, tracking: 0.8pt)
    upper(it)
    v(0.2em)
  }

  show heading.where(level: 3): it => {
    v(0.8em)
    set text(size: 11pt, weight: "bold", fill: accent-light)
    it
    v(0.1em)
  }

  show heading.where(level: 4): it => {
    v(0.6em)
    set text(size: 10pt, weight: "bold", fill: gray-mid)
    it
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
        inset: 14pt,
        radius: if it.lang != none {
          (top-left: 0pt, top-right: 4pt, bottom-left: 6pt, bottom-right: 6pt)
        } else {
          6pt
        },
        {
          set text(font: theme.fonts.mono, size: theme.code-size, fill: theme.colors.code-text)
          set par(leading: 0.55em)
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
    inset: (x: 4pt, y: 5pt),
  )
  show table: set text(size: 8.5pt, hyphenate: true)
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
    set text(size: 9pt, fill: gray-mid)
    it
  }

  show strike: it => {
    set text(fill: gray-mid)
    it
  }

  set math.equation(numbering: none)
  show math.equation.where(block: true): it => {
    v(0.3em)
    align(center, it)
    v(0.3em)
  }

  body
}
