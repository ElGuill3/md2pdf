```yaml
schema: gentle-ai.verify-result/v1
evidence_revision: sha256:3caa2d8180824761388cade89cf75d906e19d9c20b23bfdb1f750e514e4ec8d9
verdict: pass_with_warnings
blockers: 0
critical_findings: 0
requirements: 6/6
scenarios: 10/10
test_command: PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" ./tests/run.sh && PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" ./tests/skill-installer.sh
test_exit_code: 0
test_output_hash: sha256:99e13a140c30e7904b7a1b00fd94437d5a1964440c02546532d294a393535a29
build_command: sh -n md2pdf install.sh uninstall.sh install-skill.sh tests/run.sh tests/skill-installer.sh && git diff --check
build_exit_code: 0
build_output_hash: sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

## Verification Report

**Change**: `refine-cover-and-page-layout`
**Version**: N/A
**Mode**: Strict TDD
### Completeness

| Metric | Value |
|---|---:|
| Tasks total | 10 |
| Tasks complete | 10 |
| Tasks incomplete | 0 |
| Requirements | 6/6 |
| Scenarios | 10/10 |

### Build & Tests Execution

**Tests**: ✅ 557/557 real-PDF integration checks and 7/7 skill-installer checks passed.

```text
PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" ./tests/run.sh && PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" ./tests/skill-installer.sh
exit: 0
```

**Build/static validation**: ✅ POSIX syntax and whitespace checks passed.

```text
sh -n md2pdf install.sh uninstall.sh install-skill.sh tests/run.sh tests/skill-installer.sh && git diff --check
exit: 0
output: sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

**Focused visual evidence**: ✅ Fresh General, Technical, Report, and Academic PDFs passed semantic and containment checks; all four cover rasters and all four body rasters had distinct hashes.

```text
/tmp/md2pdf-final-verify-evidence-check.sh /tmp/md2pdf-pr3-evidence
exit: 0
script: sha256:fa417f5423c55cbdf428917373a6665ad4a3efd9c7f7dc859b4708b35d55671b
output: sha256:c4f24223d2399194bff598714dda22ed7db223bea4d6a5107592ad73a967d7c1
```

**Focused disabled-furniture correction**: ✅ `PATH="/tmp/opencode/pandoc-3.8/pandoc-3.8/bin:$PATH" sh /tmp/md2pdf-r3-disabled-focused.sh /home/guill3/md2pdf` passed 16/16; script `sha256:0874f82308a4de08c05a40cd63430dc5179f2d98c40264c013fa85e6366f7e1b`; output `sha256:dc2ec2fe8f6458200016a53bb7eb9d8d45cf38120cd9a96d2f5df3be69d859a0`.

**Manual inspection**: ✅ Inspected `/tmp/md2pdf-pr3-evidence/contact-sheet.png`. All four cover/body pairs showed readable multilingual metadata, furniture-free covers, readable body furniture and heading bands, and visibly distinct profile treatments without clipping or overlap.

**Coverage**: ➖ Not available; the project declares no coverage tool.

### Spec Compliance Matrix

| Requirement | Scenario | Runtime evidence | Result |
|---|---|---|---|
| Profile-aware cover composition | Identity and sparse metadata | `tests/run.sh`: four profile renders, supplied metadata assertions, sparse-cover assertions; fresh semantic/manual evidence | ✅ COMPLIANT |
| Profile-aware cover composition | Cross-profile distinction | `tests/run.sh`: six pairwise cover-raster comparisons; fresh four-hash set and manual inspection | ✅ COMPLIANT |
| Usable long and multilingual metadata | Long or mixed-language title | `tests/run.sh`: long/CJK/Greek retention and profile PDF raster checks; fresh bbox containment and manual inspection | ✅ COMPLIANT |
| Dedicated furniture-free covers | Cover page honors configuration | `tests/run.sh`: four sparse landscape covers, dedicated page, body separation, absent header/footer | ✅ COMPLIANT |
| Profile-aware level-one bands preserve flow | Heading remains in normal flow | `tests/run.sh`: Architecture and Verification coexist on the representative body page for every profile | ✅ COMPLIANT |
| Profile-aware level-one bands preserve flow | Boundary uses ordinary pagination | `tests/run.sh`: boundary heading and marker remain together without a mandatory chapter break | ✅ COMPLIANT |
| Contextual running furniture | Default headers and footers | `tests/run.sh`: current/latest-earlier/title-fallback headers and left-number/right-title bbox zones | ✅ COMPLIANT |
| Contextual running furniture | Explicit controls remain compatible | `tests/run.sh`: explicit header/footer, numbering on/off, and zone-specific absence of actual header/footer output for disabled structure overrides | ✅ COMPLIANT |
| Observable compatibility and visual evidence | Compatibility behavior is observable | Current real-PDF suite exercises PDF text, page metadata, bbox placement, rasterization, flow, and numbering | ✅ COMPLIANT |
| Observable compatibility and visual evidence | Every profile has inspection evidence | Fresh eight-image contact sheet inspected for General, Technical, Report, and Academic | ✅ COMPLIANT |

**Compliance summary**: 10/10 scenarios compliant.

### Correctness (Static Evidence)

| Requirement | Status | Notes |
|---|---|---|
| Profile-aware cover composition | ✅ Implemented | `page.typ` uses profile-specific native 8/5/3/2 grid and curve options and sparse metadata composition. |
| Usable long and multilingual metadata | ✅ Implemented | Width selection uses `layout` and `measure`; no clipping, ellipsis, or fixed-height text was introduced. |
| Dedicated furniture-free covers | ✅ Implemented | Global configured page geometry applies before `cover-page`; cover furniture is suppressed and `pagebreak()` dedicates the page. |
| Profile-aware level-one bands preserve flow | ✅ Implemented | `theme.typ` retains profile branches with `breakable: true` blocks and no heading-triggered page break. |
| Contextual running furniture | ✅ Implemented | `page.typ` selects current-page then latest-earlier level-one headings, preserves overrides, and places number left/title right. |
| Observable compatibility and visual evidence | ✅ Implemented | `tests/run.sh` observes semantic, geometric, raster, pagination, and compatibility behavior through real PDFs. |

### Coherence (Design)

| Decision | Followed? | Notes |
|---|---|---|
| Private template title provenance | ✅ Yes | `$if(title)$` flows through `document.typ` without a public config/schema field. |
| Native responsive geometry | ✅ Yes | Cover geometry uses Typst primitives and existing theme tokens; no asset or dependency was added. |
| Physical-page heading lookup | ✅ Yes | Contextual queries compare heading and current physical page locations. |
| Local helpers and minimal rollback | ✅ Yes | Presentation helpers remain in `page.typ` and `theme.typ`; PR3 changes only docs and SDD evidence. |

### TDD Compliance

| Check | Result | Details |
|---|---|---|
| TDD evidence reported | ✅ | `apply-progress.md` contains a 10-row TDD Cycle Evidence table. |
| All tasks have verification | ✅ | Eight implementation tasks map to real-PDF assertions; documentation/evidence tasks have focused contract and full-suite checks. |
| RED confirmed | ✅ | Test files exist; PR1 preserves failing recovery evidence and PR2 records 16 expected RED failures before production edits. |
| GREEN confirmed | ✅ | Current independent execution passed 557/557 plus 7/7 checks. |
| Triangulation adequate | ✅ | Four profiles, provenance branches, sparse/configured covers, furniture controls, flow boundaries, bbox zones, and raster inequalities are covered. |
| Safety net for modified files | ⚠️ | PR2 and PR3 have passing pre-change safety nets; PR1's original pre-modification run was blocked because Pandoc was unavailable. |

**TDD Compliance**: 5/6 checks fully passed; one historical safety-net warning is preserved.

### Test Layer Distribution

| Layer | Tests | Files | Tools |
|---|---:|---:|---|
| Unit | 0 | 0 | Not configured |
| Integration | 564 | 2 | POSIX shell, Pandoc 3.8, Typst 0.15, Poppler |
| E2E | 0 | 0 | Not configured |

### Changed File Coverage

Coverage analysis skipped — no coverage tool is configured.

### Assertion Quality

**Assertion quality**: ✅ The changed real-PDF harness assertions invoke production rendering and assert observable values, pagination, placement, or raster differences; no tautologies, orphan empty checks, type-only assertions, or ghost loops were found.

### Quality Metrics

**Linter**: ➖ Not available
**Type Checker**: ➖ Not available
**Static validation**: ✅ POSIX shell syntax passed
**Whitespace validation**: ✅ `git diff --check` passed

### Issues Found

**CRITICAL**: None.
**WARNING**: PR1's original pre-modification safety-net execution was blocked by missing Pandoc. Later RED evidence, focused real-PDF checks, and the current full GREEN suite substantiate the behavior, but they cannot recreate that historical pre-change run.
**SUGGESTION**: The per-page header implementation queries all level-one headings and partitions them twice; consider measuring performance on unusually chapter-dense documents before optimizing, because the current simple implementation is correct and tested.

**PR3 rollback boundary**: Revert `docs/configuration.md`, `tests/run.sh`, `tasks.md`, `apply-progress.md`, and this `verify-report.md`; PR1 and PR2 runtime behavior remains intact.

### Verdict

**PASS WITH WARNINGS**

All 6 requirements and 10 scenarios are compliant under current independent real-PDF execution and manual visual inspection. The sole warning concerns unavailable historical PR1 safety-net execution, not current behavior or archive readiness.
