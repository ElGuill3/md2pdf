#import "runtime/document.typ": md2pdf-document, md2pdf-table-code
#import "runtime/theme.typ": horizontalrule, alert-box

#let config = json("config.json")
#let md2pdf-alert = alert-box.with(lang: config.lang)
#let md2pdf-table-code = md2pdf-table-code.with(config)

#show: md2pdf-document.with(config: config)

$body$
