#import "runtime/document.typ": md2pdf-document
#import "runtime/theme.typ": horizontalrule, alert-box, md2pdf-table-code

#let config = json("config.json")
#let md2pdf-alert = alert-box.with(lang: config.lang)

#show: md2pdf-document.with(config: config)

$body$
