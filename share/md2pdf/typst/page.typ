#let is-spanish(lang) = {
  let normalized = lower(lang)
  normalized == "es" or normalized.starts-with("es-")
}

#let cover-options(theme) = {
  let style = theme.cover-style
  let technical = style == "technical"
  let report = style == "report"
  let academic = style == "academic"
  let title-size = if technical { 25pt } else if report { 30pt } else if academic { 21pt } else { 29pt }
  (
    position: if technical { "left" } else if report { "right" } else { "center" },
    signature-width: if technical { 0.78 } else if report { 0.86 } else if academic { 0.7 } else { 0.84 },
    signature-cap: if technical { 21pt } else if report { 31pt } else if academic { 20pt } else { 26pt },
    grid-stroke: if report { 0.7pt + theme.colors.accent } else if academic { 0.45pt + theme.colors.accent-light } else { 0.55pt + theme.colors.accent-light },
    curve-stroke: if technical { 1.25pt + theme.colors.accent-gold } else if report { 1.5pt + theme.colors.accent-gold } else if academic { 1pt + theme.colors.accent } else { 1.25pt + theme.colors.accent-gold },
    normal-width: if technical { 0.72 } else if academic { 0.68 } else { 0.7 },
    wide-width: if technical { 0.84 } else { 0.82 },
    compact-width: if report { 0.94 } else if academic { 0.95 } else { 0.94 },
    normal-limit: 2.6 * title-size,
    wide-limit: 3.7 * title-size,
    top-spacing: if technical { 0.35cm } else if report { 0.5cm } else if academic { 0.25cm } else { 0.45cm },
    metadata-spacing: if technical { 0.65cm } else if report { 0.8cm } else if academic { 0.55cm } else { 0.8cm },
    title-size: title-size,
    subtitle-size: if technical { 12pt } else if report { 14pt } else if academic { 11pt } else { 13pt },
  )
}

#let cover-signature(options) = layout(size => {
  let unit = calc.min(size.width * options.signature-width / 8, size.height * 0.28 / 5, options.signature-cap)
  let width = 8 * unit
  let height = 5 * unit
  let geometry = box(width: width, height: height, {
    place(dx: 0pt, dy: 0pt, rect(width: width, height: height, fill: none, stroke: options.grid-stroke))
    place(dx: 0pt, dy: 0pt, rect(width: 5 * unit, height: 5 * unit, fill: none, stroke: options.grid-stroke))
    place(dx: 5 * unit, dy: 0pt, rect(width: 3 * unit, height: 3 * unit, fill: none, stroke: options.grid-stroke))
    place(dx: 5 * unit, dy: 3 * unit, rect(width: 2 * unit, height: 2 * unit, fill: none, stroke: options.grid-stroke))
    place(dx: 0pt, dy: 0pt, curve(
      fill: none,
      stroke: options.curve-stroke,
      curve.move((0.35 * unit, 4.65 * unit)),
      curve.cubic(none, (3.8 * unit, 4.65 * unit), (5 * unit, 3.2 * unit)),
      curve.cubic((5 * unit, 1.5 * unit), none, (6.45 * unit, 1.5 * unit)),
      curve.cubic((7.7 * unit, 1.5 * unit), (7.7 * unit, 3.9 * unit), (6.45 * unit, 4.55 * unit)),
      curve.cubic((5.4 * unit, 4.85 * unit), (3.5 * unit, 4.9 * unit), (3.4 * unit, 3.65 * unit)),
    ))
  })
  if options.position == "left" { align(left, geometry) } else if options.position == "right" { align(right, geometry) } else { align(center, geometry) }
})

#let cover-metadata(config, theme, title-supplied, options) = layout(size => {
  let present = title-supplied and config.title != ""
  let title = text(size: options.title-size, weight: "bold", fill: theme.colors.accent, config.title)
  let normal = size.width * options.normal-width
  let wide = size.width * options.wide-width
  let compact = size.width * options.compact-width
  let normal-height = if present { measure(title, width: normal).height } else { 0pt }
  let wide-height = if present { measure(title, width: wide).height } else { 0pt }
  let width = if not present or normal-height <= options.normal-limit { normal } else if wide-height <= options.wide-limit { wide } else { compact }
  let metadata = block(width: width, breakable: false, {
    if present { title }
    if config.subtitle != "" {
      v(0.4em)
      text(size: options.subtitle-size, fill: theme.colors.gray-mid, style: "italic", config.subtitle)
    }
    if config.authors.len() > 0 {
      v(0.85em)
      for author in config.authors {
        text(size: theme.text-size, author.name)
        if author.affiliation != "" {
          linebreak()
          text(size: theme.text-size - 2pt, fill: theme.colors.gray-mid, author.affiliation)
        }
        linebreak()
      }
    }
    if config.date != "" {
      v(0.55em)
      text(size: theme.text-size - 1pt, fill: theme.colors.gray-mid, config.date)
    }
  })
  if options.position == "left" { align(left, metadata) } else if options.position == "right" { align(right, metadata) } else { align(center, metadata) }
})

#let default-header(config) = config.title

#let default-footer(config, theme) = {
  let authors = config.authors.map(author => author.name).join(", ")
  if theme.name == "report" and config.date != "" {
    config.date
  } else {
    authors
  }
}

#let running-header(config, theme) = context {
  let page-number = counter(page).get().first()
  if config.header.enabled and (not config.cover or page-number > 1) {
    let label = if config.header.text != "" { config.header.text } else { default-header(config) }
    set text(size: 9pt, fill: theme.colors.gray-mid)
    align(left, text(label))
    v(-0.6em)
    line(length: 100%, stroke: 0.5pt + theme.colors.gray-light)
  }
}

#let running-footer(config, theme) = context {
  let page-number = counter(page).get().first()
  if config.footer.enabled and (not config.cover or page-number > 1) {
    let label = if config.footer.text != "" { config.footer.text } else { default-footer(config, theme) }
    set text(size: 9pt, fill: theme.colors.gray-mid)
    line(length: 100%, stroke: 0.5pt + theme.colors.gray-light)
    v(-0.6em)
    grid(
      columns: (1fr, auto),
      align(left, text(label)),
      align(
        right,
        if config.footer.numbering {
          box(
            fill: theme.colors.accent,
            inset: (x: 6pt, y: 2pt),
            radius: 2pt,
            text(
              fill: white,
              size: 8pt,
              weight: "bold",
              counter(page).display("1"),
            ),
          )
        },
      ),
    )
  }
}

#let cover-page(config, theme, title-supplied: false) = {
  let options = cover-options(theme)
  if theme.cover-style == "technical" {
    rect(width: 100%, height: 10pt, fill: theme.colors.accent)
  } else if theme.cover-style == "report" {
    rect(width: 34%, height: 8pt, fill: theme.colors.accent-gold)
  }
  v(options.top-spacing)
  cover-signature(options)
  v(options.metadata-spacing)
  cover-metadata(config, theme, title-supplied, options)
  v(1fr)
  pagebreak()
}

#let contents-page(config, theme) = {
  let contents-label = if is-spanish(config.lang) { "Índice" } else { "Contents" }
  show outline.entry.where(level: 1): it => {
    v(0.4em)
    strong(it)
  }
  outline(
    title: text(size: 16pt, weight: "bold", fill: theme.colors.accent, contents-label),
    indent: auto,
    depth: config.toc.depth,
  )
  pagebreak()
}

#let page-layout(config, theme, body, title-supplied: false) = {
  let typst-lang = config.lang.split("-").first()
  let paper-name = (
    a3: "a3",
    a4: "a4",
    a5: "a5",
    letter: "us-letter",
    legal: "us-legal",
  ).at(config.page.paper)
  set text(font: theme.fonts.body, size: theme.text-size, lang: typst-lang, hyphenate: true)
  set par(justify: true, leading: theme.paragraph-leading, spacing: theme.paragraph-spacing)
  set smartquote(enabled: true)
  set page(
    paper: paper-name,
    flipped: config.page.orientation == "landscape",
    margin: (
      top: config.page.margins.top * 1pt,
      bottom: config.page.margins.bottom * 1pt,
      left: config.page.margins.left * 1pt,
      right: config.page.margins.right * 1pt,
    ),
    numbering: none,
    header: running-header(config, theme),
    footer: running-footer(config, theme),
  )

  if config.cover {
    cover-page(config, theme, title-supplied: title-supplied)
  }
  if config.toc.enabled {
    contents-page(config, theme)
  }
  body
}
