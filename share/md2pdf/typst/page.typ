#let is-spanish(lang) = lang == "es" or lang.starts-with("es-")

#let profile-label(config, theme) = {
  let spanish = is-spanish(config.lang)
  if theme.name == "technical" {
    if spanish { "TÉCNICO" } else { "TECHNICAL" }
  } else if theme.name == "report" {
    if spanish { "INFORME" } else { "REPORT" }
  } else if theme.name == "academic" {
    if spanish { "ACADÉMICO" } else { "ACADEMIC" }
  } else {
    ""
  }
}

#let default-header(config, theme) = {
  let profile = profile-label(config, theme)
  if profile == "" { config.title } else { profile + " · " + config.title }
}

#let default-footer(config, theme) = {
  let authors = config.authors.map(author => author.name).join(", ")
  if theme.name == "report" and config.date != "" {
    profile-label(config, theme) + " · " + config.date
  } else if theme.name == "technical" {
    profile-label(config, theme)
  } else {
    authors
  }
}

#let running-header(config, theme) = context {
  let page-number = counter(page).get().first()
  if config.header.enabled and (not config.cover or page-number > 1) {
    let label = if config.header.text != "" { config.header.text } else { default-header(config, theme) }
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

#let cover-page(config, theme) = {
  if theme.cover-style == "technical" {
    rect(width: 100%, height: 10pt, fill: theme.colors.accent)
    v(1.4cm)
    text(size: 9pt, weight: "bold", tracking: 1.5pt, fill: theme.colors.accent-gold, profile-label(config, theme))
    v(0.5em)
    text(size: 25pt, weight: "bold", fill: theme.colors.accent, config.title)
    if config.subtitle != "" {
      v(0.4em)
      text(size: 12pt, fill: theme.colors.accent-light, config.subtitle)
    }
    v(1.5cm)
    line(length: 100%, stroke: 1pt + theme.colors.accent-gold)
    v(0.8em)
    for author in config.authors {
      text(size: 10pt, author.name)
      if author.affiliation != "" { text(size: 8pt, fill: theme.colors.gray-mid, " · " + author.affiliation) }
      linebreak()
    }
    v(1fr)
    if config.date != "" { text(size: 9pt, fill: theme.colors.gray-mid, config.date) }
  } else if theme.cover-style == "report" {
    rect(width: 34%, height: 8pt, fill: theme.colors.accent-gold)
    v(2.2cm)
    text(size: 9pt, weight: "bold", tracking: 2pt, fill: theme.colors.accent-light, profile-label(config, theme))
    v(0.8em)
    text(size: 30pt, weight: "bold", fill: theme.colors.accent, config.title)
    if config.subtitle != "" {
      v(0.5em)
      text(size: 14pt, fill: theme.colors.gray-mid, config.subtitle)
    }
    v(2cm)
    grid(
      columns: (4pt, 1fr),
      gutter: 12pt,
      rect(width: 4pt, height: 3cm, fill: theme.colors.accent-gold),
      {
        for author in config.authors {
          text(size: 11pt, weight: "bold", fill: theme.colors.accent, author.name)
          if author.affiliation != "" {
            linebreak()
            text(size: 9pt, fill: theme.colors.gray-mid, author.affiliation)
          }
          linebreak()
        }
      },
    )
    v(1fr)
    line(length: 100%, stroke: 0.75pt + theme.colors.gray-light)
    v(0.5em)
    if config.date != "" { text(size: 10pt, fill: theme.colors.gray-mid, config.date) }
  } else if theme.cover-style == "academic" {
    align(center)[
      #v(0.7cm)
      #text(size: 8pt, tracking: 1.2pt, fill: theme.colors.gray-mid, profile-label(config, theme))
      #v(0.35em)
      #text(size: 19pt, weight: "bold", fill: theme.colors.accent, config.title)
      #if config.subtitle != "" {
        v(0.35em)
        text(size: 11pt, style: "italic", fill: theme.colors.gray-mid, config.subtitle)
      }
      #v(0.8em)
      #for author in config.authors {
        text(size: 10pt, author.name)
        if author.affiliation != "" { text(size: 8.5pt, fill: theme.colors.gray-mid, " · " + author.affiliation) }
        linebreak()
      }
      #if config.date != "" { text(size: 9pt, fill: theme.colors.gray-mid, config.date) }
      #v(0.6em)
      #line(length: 35%, stroke: 0.75pt + theme.colors.accent-gold)
    ]
    v(1em)
  } else {
    align(center)[
      #v(3cm)
      #text(size: 28pt, weight: "bold", fill: theme.colors.accent, config.title)
      #v(0.4em)
      #grid(
        columns: (1fr, 12pt, 1fr),
        gutter: 0pt,
        align(horizon, line(length: 100%, stroke: gradient.linear(rgb("#1a3c6e00"), theme.colors.accent))),
        align(horizon, circle(radius: 4pt, fill: theme.colors.accent-gold)),
        align(horizon, line(length: 100%, stroke: gradient.linear(theme.colors.accent, rgb("#1a3c6e00")))),
      )
      #v(0.4em)
      #if config.subtitle != "" {
        text(size: 14pt, fill: rgb("#555555"), style: "italic", config.subtitle)
        v(0.5em)
      }
      #v(2cm)
      #for author in config.authors {
        text(size: 12pt, fill: rgb("#555555"), author.name)
        if author.affiliation != "" {
          linebreak()
          text(size: 9pt, fill: theme.colors.gray-mid, author.affiliation)
        }
        linebreak()
      }
      #if config.date != "" {
        v(0.3em)
        text(size: 11pt, fill: theme.colors.gray-mid, config.date)
      }
      #v(1fr)
    ]
  }
  if theme.cover-style != "academic" { pagebreak() }
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

#let page-layout(config, theme, body) = {
  let paper-name = (
    a3: "a3",
    a4: "a4",
    a5: "a5",
    letter: "us-letter",
    legal: "us-legal",
  ).at(config.page.paper)
  set text(font: theme.fonts.body, size: theme.text-size, lang: config.lang, hyphenate: true)
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
    cover-page(config, theme)
  }
  if config.toc.enabled {
    contents-page(config, theme)
  }
  body
}
