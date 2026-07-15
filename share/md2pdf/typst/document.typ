#import "profiles/general.typ": general
#import "profiles/technical.typ": technical
#import "profiles/report.typ": report
#import "profiles/academic.typ": academic
#import "page.typ": page-layout
#import "theme.typ": apply-theme, table-code

#let profile-themes = (
  general: general,
  technical: technical,
  report: report,
  academic: academic,
)

#let md2pdf-table-code(config, body, landscape: false) = {
  table-code(profile-themes.at(config.profile), body, landscape: landscape)
}

#let md2pdf-document(config: (:), body) = {
  let theme = profile-themes.at(config.profile)
  let author-names = config.authors.map(author => author.name)
  let author-emails = config.authors
    .filter(author => author.email != "")
    .map(author => "author-email:" + author.email)

  set document(
    title: config.title,
    author: author-names,
    keywords: ("md2pdf", "profile-" + config.profile) + author-emails,
  )

  page-layout(
    config,
    theme,
    apply-theme(config, theme, body),
  )
}
