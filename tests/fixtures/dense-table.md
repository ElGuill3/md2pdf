---
title: Dense Technical Evidence
author:
  - Layout Tester
md2pdf:
  profile: technical
  cover: false
  toc: false
  header:
    enabled: true
    text: DENSE TABLE HEADER
  footer:
    enabled: true
    text: DENSE TABLE FOOTER
    numbering: true
---

# Evidence matrix

Outside table code stays styled: `OUTSIDE_CODE_SENTINEL/path_value.ext`.

| Evidence | Files | Impact |
|:---------|:------|:-------|
| EV-01 baseline | TABLE_PROSE_MARKER and `artifact/src/platform/renderers/dense_table/technical_profile.v2:layout-check` | Establishes the baseline. |
| EV-02 parser | `artifact/src/parsers/markdown/table_context.lua` and `artifact/tests/parser/table_context_test.lua` | Confirms semantic scope. |
| EV-03 theme | `artifact/share/md2pdf/typst/theme.typ` and `artifact/share/md2pdf/typst/profiles/technical.typ` | Matches table prose. |
| EV-04 output | `artifact/build/reports/dense_table/result.final.pdf` | Preserves searchable text. |
| EV-05 slash | `artifact/services/conversion/pipeline/stages/layout/render.typ` | Breaks after separators. |
| EV-06 underscore | `artifact/modules/table_layout/column_width_resolver.lua` | Keeps narrow cells safe. |
| EV-07 dots | `artifact/releases/v2.4.1/compatibility.matrix.json` | Retains literal dots. |
| EV-08 colon | `artifact/cache/profile:technical/table:layout/result.txt` | Retains literal colons. |
| EV-09 hyphen | `artifact/packages/layout-engine/dense-table/check-result.log` | Retains literal hyphens. |
| EV-10 mixed | Review *emphasis*, [reference](https://example.com), and `artifact/src/mixed_content/table_cell.typ` | Preserves inline semantics. |
| EV-11 image path | `artifact/assets/diagrams/table_layout/overview.svg` | Keeps asset names readable. |
| EV-12 citation path | `artifact/references/layout/table_evidence.bib` | Keeps references stable. |
| EV-13 renderer | `artifact/src/renderers/pdf/table_row_paginator.lua` | Supports page boundaries. |
| EV-14 footer | `artifact/tests/integration/footer_clearance.test.lua` | Protects running footers. |
| EV-15 header | `artifact/tests/integration/repeated_header.test.lua` | Repeats table headings. |
| EV-16 caption | `artifact/docs/tables/dense_evidence_caption.md` | Leaves captions intact. |
| EV-17 links | [Public evidence](https://example.com/evidence) and `artifact/docs/linked_path/reference.md` | Keeps links active. |
| EV-18 emphasis | *Priority evidence* in `artifact/src/priority_checks/layout_guard.lua` | Keeps emphasis intact. |
| EV-19 ordinary | Ordinary table text remains proportional and quiet. | Avoids visual noise. |
| EV-20 nested | `artifact/src/platform/components/table/cells/inline_code.typ` | Wraps deeply nested paths. |
| EV-21 config | `artifact/config/profiles/technical_dense_table.toml` | Keeps configuration clear. |
| EV-22 snapshot | `artifact/tests/golden/dense_table/page_02.snapshot.txt` | Records boundary output. |
| EV-23 report | `artifact/reports/layout/2026.07/dense_table_audit.md` | Keeps dated paths intact. |
| EV-24 runtime | `artifact/share/md2pdf/filters/runtime.lua` | Uses trusted conversion. |
| EV-25 template | `artifact/share/md2pdf/typst/template.typ` | Exposes the helper safely. |
| EV-26 profile | `artifact/share/md2pdf/typst/profiles/technical.typ` | Uses technical dimensions. |
| EV-27 search | `artifact/index/search/table_paths.search.json` | Remains searchable. |
| EV-28 copy | `artifact/clipboard/tests/copied_path_exact.txt` | Remains copyable. |
| EV-29 bounds | `artifact/tests/poppler/bbox/column_boundary_check.xml` | Stays inside columns. |
| EV-30 leading | `artifact/tests/visual/table_cell_leading.reference.png` | Prevents row overlap. |
| EV-31 pagination | `artifact/tests/pagination/final_row_visibility.test.lua` | Prevents clipped rows. |
| EV-32 final | `artifact/releases/dense_table/final-verification.ok` | Completes the matrix. |

POST_TABLE_SENTINEL
