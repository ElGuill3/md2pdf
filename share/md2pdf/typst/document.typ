#import "profiles/general.typ": general
#import "page.typ": page-layout
#import "theme.typ": apply-theme

#let profile-themes = (
  general: general,
  technical: general,
  report: general,
  academic: general,
)

#let md2pdf-document(config: (:), body) = {
  let theme = profile-themes.at(config.profile)
  let author-names = config.authors.map(author => author.name)

  set document(
    title: config.title,
    author: author-names,
    keywords: ("md2pdf", "profile-" + config.profile),
  )

  page-layout(
    config,
    theme,
    apply-theme(theme, body),
  )
}
