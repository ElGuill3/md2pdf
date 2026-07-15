---
title: General Profile Reference
subtitle: Blue and gold runtime
author:
  - name: Runtime Maintainer
    affiliation: Portable Systems Group
date: 2026-07-14
lang: en
md2pdf:
  profile: general
  cover: true
  toc:
    enabled: true
    depth: 3
  section-numbering: true
---

# Typography and structure

This paragraph includes **strong text**, *emphasis*, ~~deleted text~~, a
[link](https://example.com), inline code `path/to_value-name`, and a note.[^1]

## Lists

- First item
  - Nested item
- Second item

1. Ordered item
2. Another item

Term
: A concise definition.

> A document theme should clarify structure without overpowering content.

---

## Code

```sh
printf '%s\n' "portable"
```

## Table

| Name | Purpose | Status |
|:-----|:--------|:------:|
| Pandoc | Parse Markdown | Ready |
| Typst | Compose PDF | Ready |

## Figure

![Blue and gold identity](assets/mark.svg)

## Mathematics

The identity $a^2 + b^2 = c^2$ is shown inline.

[^1]: Footnotes remain part of the document flow.
