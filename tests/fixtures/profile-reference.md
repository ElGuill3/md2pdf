---
title: Profile Reference — Diseño editorial para sistemas documentales 中文排版测试 Ελληνικά
subtitle: One source, four document systems — a long multilingual metadata study for readable publication across configured page orientations
author:
  - name: Ada Example
    affiliation: Systems Laboratory
date: 2026-07-14
lang: en
---

# Architecture

Each profile must express hierarchy, rhythm, and running furniture through
meaningful typesetting choices while retaining the shared blue and gold identity.

## Runtime policy

The trusted runtime normalizes metadata, stages resources, and keeps generated
Typst inside an isolated root. The publication step remains atomic.

```sh
printf '%s\n' "profile evidence"
```

| Layer | Responsibility | Evidence |
|:------|:---------------|:---------|
| Shell | Orchestration | Atomic output |
| Lua | Policy | Typed metadata |
| Typst | Presentation | Distinct profiles |

# Verification

Repeated prose makes layout density visible across the four profiles. Technical
documents favor compact scanning, reports favor formal hierarchy, academic
documents favor restrained reading, and General remains the balanced default.

Repeated prose makes layout density visible across the four profiles. Technical
documents favor compact scanning, reports favor formal hierarchy, academic
documents favor restrained reading, and General remains the balanced default.

Repeated prose makes layout density visible across the four profiles. Technical
documents favor compact scanning, reports favor formal hierarchy, academic
documents favor restrained reading, and General remains the balanced default.

Repeated prose makes layout density visible across the four profiles. Technical
documents favor compact scanning, reports favor formal hierarchy, academic
documents favor restrained reading, and General remains the balanced default.

Repeated prose makes layout density visible across the four profiles. Technical
documents favor compact scanning, reports favor formal hierarchy, academic
documents favor restrained reading, and General remains the balanced default.

Repeated prose makes layout density visible across the four profiles. Technical
documents favor compact scanning, reports favor formal hierarchy, academic
documents favor restrained reading, and General remains the balanced default.

$$
E = mc^2
$$

The closing note remains visible in every profile.[^profile-note]

[^profile-note]: Footnote treatment is profile-aware.

# Normal Flow Marker

NORMAL_FLOW_MARKER keeps a future heading-flow check stable without changing
the document's meaning.

# Boundary Flow Marker

BOUNDARY_FLOW_MARKER keeps a future boundary-pagination check stable without
changing the document's meaning.
