---
title: Selective Landscape Thresholds
md2pdf:
  cover: false
  toc: false
  header: false
  footer: false
---

# Below threshold

THREE_SPANS_MARKER

| Case | Paths | Result |
|---|---|---|
| Three spans | `root/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa` `root/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb` `root/ccccccccccccccccccccccccccccccccccc` | Portrait |

FOUR_SPANS_159_CHARS_MARKER

| Case | Paths | Result |
|---|---|---|
| 159 characters | `root/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa` `root/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb` `root/ccccccccccccccccccccccccccccccccccc` `root/dddddddddddddddddddddddddddddddddd` | Portrait |

# Exact threshold

| Case | Paths | Result |
|---|---|---|
| FOUR_SPANS_160_CHARS_MARKER | `root/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa` `root/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb` `root/ccccccccccccccccccccccccccccccccccc` `root/ddddddddddddddddddddddddddddddddddd` | Landscape |

AFTER_DENSE_TABLE_MARKER

# Existing wide-table rule

MORE_THAN_FIVE_COLUMNS_MARKER

| A | B | C | D | E | F |
|---|---|---|---|---|---|
| A1 | B1 | C1 | D1 | E1 | F1 |

AFTER_WIDE_TABLE_MARKER
