# Apply Progress: Refine Cover and Page Layout

- **Mode:** Strict TDD; authoritative real-PDF GREEN reached with the temporary official Pandoc 3.8 provision.
- **Delivery:** PR 3, work unit `pr3-docs-evidence`, stacked-to-main, targets updated `main` after PR 2.
- **Task state:** 10/10 complete: 1.1–1.3, 2.1–2.4, and 3.1–3.3.
- **Cumulative history:** the prior apply attempt stopped at dependency preflight with exit 99 because Pandoc was unavailable; this continuation ran the same candidate through Pandoc → Typst → PDF and preserved the prior blocked evidence.
- **Implemented candidate:** PR 1 cover/provenance, PR 2 flow/furniture, and PR 3 configuration guidance plus final four-profile verification evidence.

## TDD Cycle Evidence

| Task | Test file/layer | Safety net | RED | GREEN | Triangulate | Refactor |
|---|---|---|---|---|---|---|
| 1.1 | `tests/run.sh` + `tests/fixtures/profile-reference.md` / integration | Attempt 1 blocked at Pandoc preflight; recovery pre-fix run was 513/518 because five candidate test assertions needed correction | Written before implementation in prior attempt | `PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" ./tests/run.sh` → 519/519 | 100 focused real-PDF checks across four profiles, omitted/explicit titles, and sparse covers | Minimal test assertion correction for permitted title reflow; focused and full suites green |
| 1.2 | `tests/run.sh` / integration | Attempt 1 blocked at Pandoc preflight; recovery pre-fix run was 513/518 | Written first in prior attempt | Full CLI → Pandoc → Typst → PDF suite → 519/519 | Sparse metadata, furniture-free page one, long subtitle, and explicit/omitted title cases for General, Technical, Report, and Academic | Semantic assertions now distinguish replaced explicit fixture metadata from supplied multilingual metadata |
| 2.1 | `share/md2pdf/typst/template.typ`, `document.typ` + `tests/run.sh` / integration | Attempt 1 blocked at Pandoc preflight | Written first in prior attempt | Full suite → 519/519; omitted title hides normalized `Document`, explicit `Document` remains visible | Four profiles and both title-provenance branches | Private argument remains outside `config` and schema |
| 2.2 | `share/md2pdf/typst/page.typ` + `tests/run.sh` / integration | Attempt 1 blocked at Pandoc preflight | Written first in prior attempt | Full suite → 519/519; all four profile covers render and rasterize | Four profile branches, long/multilingual title, sparse configured landscape cover, and body-after-cover checks | Direct Typst 0.15.0 compile, bbox containment, and manual raster inspection passed |
| 3.1 | `share/md2pdf/typst/page.typ` + focused/full integration | Attempt 1 blocked at Pandoc preflight | Written first in prior attempt | Full suite → 519/519 | Cover/body raster pair and bbox checks for every enabled profile | No clipping, ellipsis, fixed-height text, assets, dependencies, schema fields, or forced breaks introduced |
| 1.3 | `tests/run.sh` / real-PDF integration | 519/519 passed before PR 2 edits | Exact full command after RED tests: exit 1; 537 passed, 16 expected failures, 553 total | Exact full command: exit 0; 553/553 | Four profiles, current/latest-earlier/title-fallback headers, default/explicit/disabled furniture, numbering on/off, flow boundaries, bbox zones, rasters, and pairwise profile inequality | Corrected the right-aligned long-title assertion to observe its rightmost supplied word rather than requiring its first word to start in the right half |
| 2.3 | `share/md2pdf/typst/page.typ` / real-PDF integration | 519/519 passed before production edits | Task 1.3 failures proved old document-title headers and reversed author/date-left, number-right footers | 553/553; current-page then latest-earlier level-one lookup and title fallback pass | Current page, continued chapter page, no-heading fallback, explicit header/footer, disabled furniture, numbering disabled | Removed the redundant one-line default-header helper; kept query logic local to running furniture |
| 2.4 | `share/md2pdf/typst/theme.typ` / real-PDF geometry+raster | 519/519 passed before production edits | General profile band inset failed before production edits; cross-profile flow/raster checks were present | 553/553; all four profile band geometry and flow assertions pass | Profile-specific inset thresholds, same-page multiple headings, boundary heading/content, and six pairwise body-raster inequalities | All four branches use the existing local block pattern with `breakable: true`; no helper, forced break, fixed height, clipping, or ellipsis |
| 3.2 | `docs/configuration.md` / documentation | Existing schema/default documentation reviewed against `runtime.lua` and `page.typ` | N/A — documentation-only task; no production behavior changed | Focused documentation contract assertions passed | Sparse/title-provenance, Academic dedicated-cover, default furniture, and override sections checked against implementation | Kept the change within the existing metadata, profile-default, and furniture structure; no duplicate schema reference added |
| 3.3 | existing integration, semantic, bbox, and raster harnesses | PR 2 candidate passed 553/553 before this documentation-only slice | RDD correction added observable disabled-furniture assertions without production changes | Required combined suite passed 568/568; shell syntax and whitespace checks exited 0 | Fresh four-profile PDFs plus enabled negative controls passed 16/16 focused checks | Inspected every fresh cover/body pair; correction changed only tests and evidence |

### PR 2 Test Summary

- **Safety net:** exact full command passed 519/519 before PR 2 test or production edits.
- **RED:** exact full command exited 1 with 537 passed and 16 expected failures of 553 total.
- **GREEN:** exact full command passed 553/553; after refactor the exact full command again passed 553/553.
- **Focused real-PDF:** 30/30 checks passed from `/tmp/opencode/md2pdf-pr2-flow-furniture-focused.sh` (SHA-256 `187ffcb5e20b51b36cdedb8ef1e92a0a892179a8f68b49a1a257de98a6865b88`).
- **Runtime:** CLI → Pandoc 3.8 → Typst 0.15.0 → PDF → Poppler bbox/raster checks passed for all profiles, contextual continuation, and explicit controls.
- **Visual inspection:** `/tmp/opencode/md2pdf-pr2-evidence/{general,technical,report,academic}-body.png` showed readable distinct bands, chapter headers, page numbers left, and long document titles right without clipping.

### Test Summary

- **Focused real-PDF checks:** 100 passed, 0 failed.
- **Full `./tests/run.sh`:** 519 passed, 0 failed, exit 0.
- **Tests written/extended in this slice:** fixture/input and semantic integration assertions in `tests/run.sh`.
- **Integration layer:** CLI → Pandoc 3.8 → Lua filters → Typst 0.15.0 → PDF → Poppler.
- **Approval tests:** None — this slice changes cover behavior rather than refactoring an isolated existing function.
- **Pure functions created:** None — Typst layout helpers are private rendering functions.

## Work Unit Evidence

| Evidence | Result |
|---|---|
| PR 1 focused test command and exact result | `PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" ./tests/run.sh` → exit 0; `519 tests passed; 0 tests failed; 519 total` |
| PR 1 full test command and exact result | `PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" ./tests/run.sh` → exit 0; `519 tests passed; 0 tests failed; 519 total` |
| Focused test command and exact result | `PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" /tmp/opencode/md2pdf-pr2-flow-furniture-focused.sh /home/guill3/md2pdf` → exit 0; `30 focused PR2 real-PDF checks passed` |
| Full test command and exact result | `PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" ./tests/run.sh` → exit 0; `553 tests passed; 0 tests failed; 553 total` |
| Static shell syntax | `PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" sh -n md2pdf install.sh uninstall.sh install-skill.sh tests/run.sh tests/skill-installer.sh tests/fixtures/mock-curl tests/fixtures/typst-proxy` → exit 0 |
| Direct Typst check | `PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" typst compile share/md2pdf/typst/page.typ /tmp/opencode/md2pdf-pr1-evidence/page-direct.pdf` → exit 0; Typst 0.15.0 |
| Skill installer | `PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" ./tests/skill-installer.sh` → exit 0; 7 passed, 0 failed |
| Whitespace check | `PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" git diff --check` → exit 0 |
| Cover bbox check | `pdftotext -f 1 -l 1 -bbox` for each evidence PDF → exit 0; General 35 words, Technical 34, Report 35, Academic 34, all contained within page bounds |
| Runtime harness | `PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" sh -eu -c` inline profile-reference/omitted-title/explicit-`Document`/cover-sparse harness → exit 0; `100 focused PR1 real-PDF checks passed` |
| Visual inspection | Inspected page 1 cover and the representative body page in each pair: `/tmp/opencode/md2pdf-pr1-evidence/general-cover.png` + `general-body.png` (PDF pages 1 and 3), `technical-cover.png` + `technical-body.png` (pages 1 and 3), `report-cover.png` + `report-body.png` (pages 1 and 3), and `academic-cover.png` + `academic-body.png` (pages 1 and 2). Covers showed responsive distinct signatures, supplied metadata, no header/footer/page number, and no clipping; body pages remained readable with profile-specific identity, furniture, and numbering. |
| PR 1 rollback boundary | Revert only `share/md2pdf/typst/template.typ`, `share/md2pdf/typst/document.typ`, `share/md2pdf/typst/page.typ`, `tests/run.sh`, `tests/fixtures/profile-reference.md`, and `tests/fixtures/cover-sparse.md` to remove PR 1 behavior and its tests. |
| PR 2 runtime harness | `PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" /tmp/opencode/md2pdf-pr2-flow-furniture-focused.sh /home/guill3/md2pdf` → exit 0; 30 semantic, bbox, raster, continuation, override, and profile-inequality checks passed. |
| PR 2 visual inspection | Inspected `/tmp/opencode/md2pdf-pr2-evidence/{general,technical,report,academic}-body.png`; all four showed distinct readable level-one bands, chapter context at top, page number left, and the multilingual document title right without clipping. |
| PR 2 rollback boundary | Revert only the PR 2 hunks in `share/md2pdf/typst/page.typ`, `share/md2pdf/typst/theme.typ`, and `tests/run.sh`; PR 1 cover/provenance behavior remains intact. |
| PR 3 documentation focused check | `sh -eu -c` with fixed `grep -F` assertions for `Cover metadata is sparse`, omitted and explicit `title: Document`, Academic dedicated covers, current/title-fallback headers, left page numbers, and existing overrides against `docs/configuration.md` → exit 0; 8/8 assertions passed. |
| PR 3 documentation runtime harness | N/A — task 3.2 changes documentation only and introduces no runtime boundary; task 3.3 reruns the existing real-PDF harness. |
| PR 3 rollback boundary | Revert `docs/configuration.md`, `verify-report.md`, and the PR 3 evidence additions in this apply-progress artifact; PR 1 and PR 2 runtime behavior remains intact. |
| PR 3 full verification | Full suite → 557/557 integration and 7/7 installer checks; disabled-furniture focus → 16/16 using script `sha256:0874f82308a4de08c05a40cd63430dc5179f2d98c40264c013fa85e6366f7e1b` and evidence `sha256:3caa2d8180824761388cade89cf75d906e19d9c20b23bfdb1f750e514e4ec8d9`. |
| PR 3 static verification | `sh -n md2pdf install.sh uninstall.sh install-skill.sh tests/run.sh tests/skill-installer.sh && git diff --check` → exit 0. |
| PR 3 focused PDF evidence | Fresh `./md2pdf --profile "$profile" tests/fixtures/profile-reference.md` renders for General, Technical, Report, and Academic, followed by page-scoped `pdftotext`, `pdftotext -bbox`, and `pdftoppm`; `sh /tmp/md2pdf-pr3-evidence/check.sh` (SHA-256 `0aefe9a06477a0ddeb345fdd9b152baa76bb3c84ad7e335dc96c6da1856a18a7`) → exit 0; 12/12 semantic assertions, 8/8 contained bbox documents, and 8/8 distinct raster hashes. |
| PR 3 visual inspection | Inspected `/tmp/md2pdf-pr3-evidence/contact-sheet.png`: General, Technical, and Report pages 1/3 plus Academic pages 1/2. All covers retained readable multilingual metadata, distinct bounded signatures, whitespace, and no furniture; all body pages had readable distinct bands, contextual headers, left page numbers, and right document titles without clipping or overlap. |
| PR 3 work-unit rollback boundary | Revert only `docs/configuration.md`, `tests/run.sh`, `openspec/changes/refine-cover-and-page-layout/tasks.md`, `apply-progress.md`, and `verify-report.md`; runtime behavior from PR 1 and PR 2 remains unchanged. |

## Deviations and Issues

- The production implementation matches the design. The only continuation fix was test-only: four explicit-`Document` assertions incorrectly expected the replaced CJK title, and one legacy backslash assertion rejected a permitted line wrap; assertions now test supplied content and preserved characters without forbidding reflow.
- PR 1 added no headers, footers, or heading bands. PR 2 added only those assigned behaviors and tests; no docs, PR 3 behavior, commit, push, or RDD action was added.

## Remaining Tasks

None — all 10 implementation tasks are complete and ready for SDD verification.

## Evidence Recapture

- **Focused script:** `/tmp/opencode/md2pdf-pr1-cover-provenance-focused.sh`; SHA-256 `e6af40aff8d8777716611c39a99dfce7ff485bc7067fd439c7e87a24d1d04750`.
- **Exact invocation:** `PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" sh "/tmp/opencode/md2pdf-pr1-cover-provenance-focused.sh" "/home/guill3/md2pdf"` → exit `0`; `100 focused PR1 real-PDF checks passed`.
- **Exact line-count command:** `PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" sh -eu -c 'tracked=$(git diff --numstat -- share/md2pdf/typst/template.typ share/md2pdf/typst/document.typ share/md2pdf/typst/page.typ tests/run.sh tests/fixtures/profile-reference.md | awk "{ additions += \$1; deletions += \$2 } END { print additions + deletions }"); fixture=$(wc -l < tests/fixtures/cover-sparse.md); apply_progress=$(wc -l < openspec/changes/refine-cover-and-page-layout/apply-progress.md); tasks_artifact=$(wc -l < openspec/changes/refine-cover-and-page-layout/tasks.md); printf "tracked source/test changes: %s\\nnew source/test fixture lines: %s\\nsource/test authored changed lines: %s\\napply-progress evidence-artifact lines: %s\\ntasks artifact lines (not part of functional count): %s\\nfunctional candidate under 400: %s\\n" "$tracked" "$fixture" "$((tracked + fixture))" "$apply_progress" "$tasks_artifact" "$([ $((tracked + fixture)) -lt 400 ] && printf yes || printf no)"'` → source/test `301`, apply-progress evidence artifact `66`, tasks artifact `57`; functional candidate under `400`.
- **Before/after Git evidence:** SHA-256 hashes for all source/test/fixture files and `tasks.md` matched exactly; task checkbox text and pre-existing `git status --short` matched; no functional file or checkbox changed.
- **PR 2 focused script:** `/tmp/opencode/md2pdf-pr2-flow-furniture-focused.sh`; SHA-256 `187ffcb5e20b51b36cdedb8ef1e92a0a892179a8f68b49a1a257de98a6865b88`.
- **PR 2 exact invocation:** `PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" /tmp/opencode/md2pdf-pr2-flow-furniture-focused.sh /home/guill3/md2pdf` → exit 0; `30 focused PR2 real-PDF checks passed`.
- **PR 2 exact line count:** `git diff --numstat -- share/md2pdf/typst/page.typ share/md2pdf/typst/theme.typ tests/run.sh` → 225 additions and 39 deletions, 264 authored functional changed lines; under 400.
