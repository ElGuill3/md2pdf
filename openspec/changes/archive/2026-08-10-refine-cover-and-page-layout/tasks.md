# Tasks: Refine Cover and Page Layout

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~650–780 authored lines (about 480–560 additions and 170–220 deletions) |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 cover; PR 2 flow/furniture; PR 3 docs/evidence |
| Delivery strategy | auto-chain |
| Chain strategy | stacked-to-main |

Decision needed before apply: No
Chained PRs recommended: Yes
Chain strategy: stacked-to-main
400-line budget risk: High

Order: PR 1 → main; after PR 1 merges, PR 2 → updated main; after PR 2 merges, PR 3 → updated main. Each PR is independently verifiable and rollback-safe.

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|---|---|---|---|---|---|
| 1 | Cover provenance, metadata, dedicated covers | PR 1 | `./tests/run.sh` cover assertions | CLI → PDF for Academic and omitted/explicit titles | Cover code/tests in `page.typ`, `template.typ`, `document.typ` |
| 2 | Flow bands, furniture, compatibility controls | PR 2 | `./tests/run.sh` flow/furniture assertions | CLI → PDF for chapter, fallback, override, disabled controls | Furniture in `page.typ`, rules in `theme.typ`, fixture assertions |
| 3 | Docs and four-profile evidence | PR 3 | `./tests/run.sh && ./tests/skill-installer.sh` | `pdftoppm` cover/body inspection for all profiles | `docs/configuration.md` and evidence harness |

## Phase 1: RED — Real-PDF Contract Tests

- [x] 1.1 Extend `tests/fixtures/profile-reference.md` with long/multilingual metadata and stable heading-flow markers; generate omitted-title and explicit-`Document` inputs in `tests/run.sh`.
- [x] 1.2 Add failing semantic assertions in `tests/run.sh` for sparse supplied metadata, title provenance, dedicated configured covers including Academic, furniture-free page one, and long-title retention.
- [x] 1.3 Add failing `pdfinfo`, page-scoped `pdftotext`, `pdftotext -bbox`, raster, and profile-inequality checks for geometry, normal/boundary heading flow, chapter/fallback headers, footer zones, overrides, disables, and numbering.

## Phase 2: GREEN — Core Typst Implementation

- [x] 2.1 Modify `share/md2pdf/typst/template.typ` and `document.typ` to pass private `title-supplied` provenance without changing `config`.
- [x] 2.2 In `share/md2pdf/typst/page.typ`, implement bounded 8/5/3/2 grid/curve helpers, responsive metadata composition, profile branches, and dedicated furniture-free covers for every profile.
- [x] 2.3 In `page.typ`, resolve current-page then latest-earlier level-one headings for header fallback; preserve explicit header/footer text, enablement, and numbering switches with page number left/title right.
- [x] 2.4 In `share/md2pdf/typst/theme.typ`, add profile-aware level-one bands that remain breakable and never force a chapter page break; run `sh -n tests/run.sh` and `./tests/run.sh`.

## Phase 3: REFACTOR — Compatibility and Evidence

- [x] 3.1 Refactor private Typst helpers for valid `layout`/`measure`/`curve` geometry and readable containment; forbid clipping, ellipsis, fixed-height text, new assets, dependencies, schema fields, or forced breaks.
- [x] 3.2 Update `docs/configuration.md` for sparse covers, Academic dedicated covers, changed furniture defaults, title fallback/provenance, and preserved overrides.
- [x] 3.3 Run `./tests/run.sh && ./tests/skill-installer.sh`, `sh -n md2pdf install.sh uninstall.sh install-skill.sh tests/run.sh tests/skill-installer.sh`, and `git diff --check`; record semantic, bbox, raster, and manual evidence in the verification receipt.

Threat matrix conclusion: documentation-like paths, Git selection, commit state, push state, and PR commands remain N/A; no threat RED tests apply.

## Apply Status: PR 1 cover/provenance GREEN

- Five PR 1 tasks are complete: 1.1, 1.2, 2.1, 2.2, and 3.1.
- `PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" ./tests/run.sh` passed 519/519 tests.
- The focused PR 1 real-PDF harness passed 100 checks across all four profiles, omitted/explicit title provenance, sparse configured covers, dedicated cover pages, and cover/body rasterization.
- `sh -n md2pdf install.sh uninstall.sh install-skill.sh tests/run.sh tests/skill-installer.sh tests/fixtures/mock-curl tests/fixtures/typst-proxy` exited 0; `./tests/skill-installer.sh` passed 7/7; `git diff --check` exited 0.
- Direct `typst compile share/md2pdf/typst/page.typ /tmp/opencode/md2pdf-pr1-evidence/page-direct.pdf` passed with Typst 0.15.0.
- Visual inspection covered `/tmp/opencode/md2pdf-pr1-evidence/{general,technical,report,academic}-{cover,body}.png`; each cover was furniture-free and each body remained readable with profile distinction.

## Apply Status: PR 2 flow/furniture GREEN

- Eight tasks are complete: 1.1–1.3, 2.1–2.4, and 3.1. Only PR 3 tasks 3.2 and 3.3 remain.
- Strict-TDD RED: the exact full command exited 1 with 537 passed and 16 expected failures for contextual headers, footer zones, and missing General band geometry.
- Strict-TDD GREEN/refactor: the exact full command passed 553/553 after contextual heading lookup, footer reordering, breakable profile bands, and test-only geometry correction.
- Focused CLI → PDF runtime evidence passed 30 checks across all profiles, current/latest-earlier headings, footer placement, rasterization, and body-profile inequality.
- Authored PR 2 source/test changes are 264 lines (225 additions and 39 deletions), under the 400-line chained-PR budget.
