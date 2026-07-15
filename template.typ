// ─────────────────────────────────────────────────────────────────────────────
// horizontalrule — exportado para que pandoc pueda llamarlo directamente
// ─────────────────────────────────────────────────────────────────────────────
#let horizontalrule = {
  let accent-gold = rgb("#c2a24a")
  let gray-light  = rgb("#cccccc")
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

// ─────────────────────────────────────────────────────────────────────────────
// calert — cajas de alerta para GFM alerts (> [!NOTE] / [!TIP] / etc.)
// Usado por el filtro Lua alerts.lua
// ─────────────────────────────────────────────────────────────────────────────
#let calert(kind: "note", title: none, body) = {
  let configs = (
    note: (
      color: rgb("#2563a8"),
      bg:    rgb("#eaf2fc"),
      label: "Note",
    ),
    tip: (
      color: rgb("#2d7a4f"),
      bg:    rgb("#eaf6ef"),
      label: "Tip",
    ),
    important: (
      color: rgb("#6b3fa0"),
      bg:    rgb("#f3edf9"),
      label: "Important",
    ),
    warning: (
      color: rgb("#c2a24a"),
      bg:    rgb("#fdf7e6"),
      label: "Warning",
    ),
    caution: (
      color: rgb("#c0392b"),
      bg:    rgb("#fdecea"),
      label: "Caution",
    ),
  )
  let cfg = configs.at(kind, default: configs.note)
  let display-title = if title != none and title != "" { title } else { cfg.label }

  v(0.6em)
  block(
    width: 100%,
    radius: 4pt,
    clip: true,
    stroke: (left: 3.5pt + cfg.color),
    {
      // Cabecera coloreada
      block(
        width: 100%,
        inset: (x: 10pt, y: 5pt),
        fill: cfg.color.lighten(80%),
        text(
          weight: "bold",
          size: 9pt,
          fill: cfg.color,
          tracking: 0.5pt,
          upper(display-title)
        )
      )
      // Cuerpo
      block(
        width: 100%,
        inset: (x: 12pt, y: 8pt),
        fill: cfg.bg,
        text(size: 10pt, body)
      )
    }
  )
  v(0.6em)
}

// ─────────────────────────────────────────────────────────────────────────────
// project — función principal de la plantilla
// ─────────────────────────────────────────────────────────────────────────────
#let project(
  title: "",
  subtitle: "",
  author: "",
  date: "",
  toc: true,
  number-sections: false,
  body
) = {

  // ── Colores ──────────────────────────────────────────────────────────────
  let accent       = rgb("#1a3c6e")
  let accent-light = rgb("#2563a8")
  let accent-gold  = rgb("#c2a24a")
  let gray-mid     = rgb("#888888")
  let gray-light   = rgb("#cccccc")

  // ── Metadatos del PDF ────────────────────────────────────────────────────
  set document(
    title: title,
    author: author,
  )

  // ── Configuración de página ──────────────────────────────────────────────
  set page(
    paper: "a4",
    margin: (top: 2.8cm, bottom: 2.8cm, left: 2.5cm, right: 2.5cm),
    numbering: "1",
    number-align: right,
  )

  // ── Tipografía base ──────────────────────────────────────────────────────
  set text(font: "Linux Libertine O", size: 11pt, lang: "es")
  set par(justify: true, leading: 0.75em, spacing: 1.1em)
  set smartquote(enabled: true)

  // ── Encabezado (oculto en portada) ──────────────────────────────────────
  set page(header: context {
    if counter(page).get().first() > 1 {
      set text(size: 9pt, fill: gray-mid)
      align(left, title)
      v(-0.6em)
      line(length: 100%, stroke: 0.5pt + gray-light)
    }
  })

  // ── Footer (oculto en portada) ───────────────────────────────────────────
  set page(footer: context {
    if counter(page).get().first() > 1 {
      set text(size: 9pt, fill: gray-mid)
      line(length: 100%, stroke: 0.5pt + gray-light)
      v(-0.6em)
      grid(
        columns: (1fr, auto),
        align(left, if author != "" { author } else { [] }),
        align(right,
          box(
            fill: accent,
            inset: (x: 6pt, y: 2pt),
            radius: 2pt,
            text(fill: white, size: 8pt, weight: "bold",
              counter(page).display("1")
            )
          )
        )
      )
    }
  })

  // ── Numeración de secciones (opcional) ───────────────────────────────────
  if number-sections {
    set heading(numbering: "1.1.1.")
  }

  // ── Headings ─────────────────────────────────────────────────────────────
  show heading.where(level: 1): it => {
    v(1.5em)
    set text(size: 18pt, weight: "bold", fill: accent)
    it
    v(0.25em)
    grid(
      columns: (8pt, 1fr),
      gutter: 6pt,
      align(horizon, circle(radius: 3pt, fill: accent-gold)),
      align(horizon, line(length: 100%, stroke: gradient.linear(accent, rgb("#1a3c6e00"))))
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

  // ── Código inline ────────────────────────────────────────────────────────
  // Usamos highlight() en lugar de box() para que pueda romper línea
  // dentro de celdas de tabla. box() es no-breakable por diseño en Typst.
  show raw.where(block: false): it => {
    h(0pt, weak: true)
    text(
      font: "JetBrains Mono",
      size: 9pt,
      fill: accent,
      highlight(fill: rgb("#e8f0fb"), radius: 3pt, it)
    )
    h(0pt, weak: true)
  }

  // ── Bloques de código (con etiqueta de lenguaje) ──────────────────────────
  show raw.where(block: true): it => {
    let lang-label = if it.lang != none {
      box(
        fill: rgb("#313244"),
        inset: (x: 8pt, y: 3pt),
        radius: (top-left: 4pt, top-right: 4pt),
        text(font: "JetBrains Mono", size: 8pt, fill: rgb("#89b4fa"), it.lang)
      )
    } else { none }

    v(0.4em)
    stack(
      dir: ttb,
      if lang-label != none { lang-label } else { v(0pt) },
      block(
        width: 100%,
        fill: rgb("#1e1e2e"),
        inset: 14pt,
        radius: if it.lang != none {
          (top-left: 0pt, top-right: 4pt, bottom-left: 6pt, bottom-right: 6pt)
        } else { 6pt },
        {
          set text(font: "JetBrains Mono", size: 9pt, fill: rgb("#cdd6f4"))
          set par(leading: 0.55em)
          it
        }
      )
    )
    v(0.4em)
  }

  // ── Tablas ───────────────────────────────────────────────────────────────
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
  // Captions de tabla arriba, prefijo en español
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.where(kind: table): set figure(supplement: [Tabla])

  // ── Figuras / imágenes ───────────────────────────────────────────────────
  show figure.where(kind: image): it => {
    v(0.8em)
    align(center, it.body)
    v(0.3em)
    align(center,
      block(
        width: 80%,
        text(
          size: 9pt,
          style: "italic",
          fill: gray-mid,
          {
            text(weight: "bold", fill: accent-light)[Figura ]
            context counter(figure.where(kind: image)).display()
            if it.caption != none {
              [. ]
              it.caption.body
            }
          }
        )
      )
    )
    v(0.8em)
  }
  set figure(supplement: [Figura])

  // ── Links ────────────────────────────────────────────────────────────────
  show link: it => {
    set text(fill: accent-light)
    underline(it)
  }

  // ── Listas no ordenadas (• ◦ ▪) ──────────────────────────────────────────
  set list(
    indent: 8pt,
    marker: (
      text(fill: accent,       size: 11pt, [•]),
      text(fill: accent-light, size: 9pt,  [◦]),
      text(fill: gray-mid,     size: 9pt,  [▪]),
    )
  )

  // ── Listas ordenadas ─────────────────────────────────────────────────────
  set enum(indent: 8pt, numbering: "1.a.i.")

  // ── Listas de definición (término : definición) ───────────────────────────
  show terms: it => {
    for child in it.children {
      grid(
        columns: (auto, 1fr),
        gutter: 8pt,
        text(weight: "bold", fill: accent, child.term),
        block(inset: (left: 0pt), child.description)
      )
      v(0.3em)
    }
  }

  // ── Blockquotes ──────────────────────────────────────────────────────────
  set quote(block: true)
  show quote.where(block: true): it => {
    block(
      width: 100%,
      inset: (left: 20pt, right: 8pt, top: 8pt, bottom: 8pt),
      stroke: (left: 3pt + accent-gold),
      fill: rgb("#f8f6f0"),
      {
        place(
          dx: -16pt, dy: -2pt,
          text(size: 28pt, fill: accent-gold, weight: "bold",
            font: "Linux Libertine O", ["])
        )
        text(style: "italic", fill: rgb("#444444"), it.body)
      }
    )
  }

  // ── Notas al pie ─────────────────────────────────────────────────────────
  set footnote.entry(
    separator: line(length: 30%, stroke: 0.5pt + gray-light),
    gap: 0.5em,
  )
  show footnote.entry: it => {
    set text(size: 9pt, fill: gray-mid)
    it
  }

  // ── Tachado ──────────────────────────────────────────────────────────────
  show strike: it => {
    set text(fill: gray-mid)
    it
  }

  // ── Ecuaciones matemáticas ────────────────────────────────────────────────
  set math.equation(numbering: none)
  show math.equation.where(block: true): it => {
    v(0.3em)
    align(center, it)
    v(0.3em)
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ── Portada ──────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────────
  if title != "" {
    align(center)[
      #v(3cm)
      #text(size: 28pt, weight: "bold", fill: accent)[#title]
      #v(0.4em)
      #grid(
        columns: (1fr, 12pt, 1fr),
        gutter: 0pt,
        align(horizon, line(length: 100%,
          stroke: gradient.linear(rgb("#1a3c6e00"), accent))),
        align(horizon, circle(radius: 4pt, fill: accent-gold)),
        align(horizon, line(length: 100%,
          stroke: gradient.linear(accent, rgb("#1a3c6e00")))),
      )
      #v(0.4em)
      #if subtitle != "" {
        text(size: 14pt, fill: rgb("#555555"), style: "italic")[#subtitle]
        v(0.5em)
      }
      #v(2cm)
      #if author != "" {
        text(size: 12pt, fill: rgb("#555555"))[#author]
        v(0.3em)
      }
      #if date != "" {
        text(size: 11pt, fill: gray-mid)[#date]
      }
      #v(1fr)
    ]
    pagebreak()
  }

  // ── Tabla de contenidos (opcional) ───────────────────────────────────────
  if toc {
    show outline.entry.where(level: 1): it => {
      v(0.4em)
      strong(it)
    }
    outline(
      title: text(size: 16pt, weight: "bold", fill: accent)[Contenido],
      indent: auto,
      depth: 3,
    )
    pagebreak()
  }

  // ── Cuerpo ────────────────────────────────────────────────────────────────
  body
}
