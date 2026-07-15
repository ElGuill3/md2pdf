#let running-header(config, theme) = context {
  let page-number = counter(page).get().first()
  if config.header.enabled and (not config.cover or page-number > 1) {
    let label = if config.header.text != "" { config.header.text } else { config.title }
    set text(size: 9pt, fill: theme.colors.gray-mid)
    align(left, text(label))
    v(-0.6em)
    line(length: 100%, stroke: 0.5pt + theme.colors.gray-light)
  }
}

#let running-footer(config, theme) = context {
  let page-number = counter(page).get().first()
  if config.footer.enabled and (not config.cover or page-number > 1) {
    let author-line = config.authors.map(author => author.name).join(", ")
    let label = if config.footer.text != "" { config.footer.text } else { author-line }
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
  align(center)[
    #v(3cm)
    #text(size: 28pt, weight: "bold", fill: theme.colors.accent, config.title)
    #v(0.4em)
    #grid(
      columns: (1fr, 12pt, 1fr),
      gutter: 0pt,
      align(
        horizon,
        line(
          length: 100%,
          stroke: gradient.linear(rgb("#1a3c6e00"), theme.colors.accent),
        ),
      ),
      align(horizon, circle(radius: 4pt, fill: theme.colors.accent-gold)),
      align(
        horizon,
        line(
          length: 100%,
          stroke: gradient.linear(theme.colors.accent, rgb("#1a3c6e00")),
        ),
      ),
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
  pagebreak()
}

#let contents-page(config, theme) = {
  show outline.entry.where(level: 1): it => {
    v(0.4em)
    strong(it)
  }
  outline(
    title: text(size: 16pt, weight: "bold", fill: theme.colors.accent, [Contents]),
    indent: auto,
    depth: config.toc.depth,
  )
  pagebreak()
}

#let page-layout(config, theme, body) = {
  set text(font: theme.fonts.body, size: theme.text-size, lang: config.lang)
  set par(justify: true, leading: 0.75em, spacing: 1.1em)
  set smartquote(enabled: true)
  set page(
    paper: config.page.paper,
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

  if config.section_numbering {
    set heading(numbering: "1.1.1.")
  }
  if config.cover {
    cover-page(config, theme)
  }
  if config.toc.enabled {
    contents-page(config, theme)
  }
  body
}
