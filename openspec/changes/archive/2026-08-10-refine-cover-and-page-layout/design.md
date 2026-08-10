# Design: Refine Cover and Page Layout

## Technical Approach

Keep `runtime.lua`, `config.json`, and profile tokens unchanged. Pandoc’s template context provides title provenance: `template.typ` derives a private Boolean with `$if(title)$` and passes it through `document.typ` to `page.typ`. `runtime.lua` defaults only `config.title` and returns source metadata without adding `meta.title`; therefore omitted/empty is false and any non-empty supplied title—including `Document`—is true.

Native Typst provides the responsive signature, sparse metadata, dedicated covers, in-flow bands, and physical-page chapter lookup. No assets, dependencies, public fields, filter/schema changes, or forced breaks are introduced.

## Architecture Decisions

| Option | Tradeoff | Decision and rationale |
|---|---|---|
| Template provenance versus config field/sentinel | One private argument crosses two functions. | Use `$if(title)$`; it preserves explicit `Document` without a filter/schema change. |
| Native geometry versus image/package | Bézier geometry needs inspection. | Use `layout`, primitives, and `curve`; it scales without assets. |
| Physical heading locations versus document order | Requires contextual queries. | Use the first current-page heading, else the latest earlier one, preventing stale headers. |
| Local helpers versus new module | Existing files grow slightly. | Keep private helpers in existing modules for minimal rollback. |

## Data Flow

```text
Markdown metadata -> Pandoc template `$if(title)$` -> title-supplied
       |                                              |
       +-> runtime normalization -> config.json ------+
                                      |
template.typ -> document.typ -> page-layout -> cover/furniture
                              -> apply-theme -> level-one bands/body
```

## Geometry and Containment

`cover-signature` bounds a Fibonacci-like 8/5/3/2 grid and cubic curve within available dimensions and uses `theme.colors.accent-gold.lighten(88%)`. Existing `cover-style` branches vary placement, stroke, and alignment.

`cover-metadata` uses width-constrained blocks. `layout` and `measure` select normal, wide, then compact composition; clipping, ellipsis, and fixed-height text boxes are forbidden.

## File Changes

| File | Action | Description |
|---|---|---|
| `share/md2pdf/typst/template.typ` | Modify | Derive the source-title Boolean from Pandoc metadata. |
| `share/md2pdf/typst/document.typ` | Modify | Forward the private Boolean without changing `config`. |
| `share/md2pdf/typst/page.typ` | Modify | Add signature/metadata/chapter helpers, dedicated covers, and revised furniture. |
| `share/md2pdf/typst/theme.typ` | Modify | Add profile-aware, non-breaking level-one bands. |
| `tests/fixtures/profile-reference.md` | Modify | Add long multilingual metadata and stable flow markers. |
| `tests/run.sh` | Modify | Add RED-first real-PDF semantic, geometry, raster, and compatibility checks. |
| `docs/configuration.md` | Modify | Document cover sparsity, dedicated covers, and new furniture defaults. |

## Interfaces / Contracts

`title-supplied` is a private Typst argument, not a config key. The cover emits title only when true and non-empty; other metadata retains non-empty checks. Omitted title still becomes `Document` for PDF metadata/fallback, while explicit `Document` remains visible.

Headers preserve explicit text/enablement, else use chapter then title. Footers preserve controls, with number left and explicit text or title right. Covers suppress furniture.

## Testing Strategy

| Layer | What to test | Approach |
|---|---|---|
| Unit | N/A | No unit harness; behavior crosses Pandoc, Typst, and PDF output. |
| RED integration | Every spec scenario | First generate omitted-title and explicit-`Document` inputs; page one excludes only the former. Assert sparse fields, long/multilingual containment, configured paper/orientation and dedicated covers including Academic, absent cover furniture, normal/boundary heading flow, chapter/fallback headers, footer zones, and override/disable/numbering controls. |
| GREEN/integration | Complete compatibility | Run `sh -n tests/run.sh` and `./tests/run.sh`; use `pdfinfo`, page-scoped `pdftotext`, and bbox checks. |
| Raster/manual | Identity/readability | Compare profiles and record an inspected cover/body pair for all four; render success is insufficient. |

## Threat Matrix

`tests/run.sh` gains fixed, quoted CLI/Poppler commands, not command construction or routing.

| Boundary | Applicability / reason | Design response | Planned RED tests |
|---|---|---|---|
| Documentation-like paths | N/A — Markdown fixtures remain renderer data, never executable candidates. | No classification boundary changes. | None. |
| Git repository selection | N/A — additions invoke no Git or cwd selector. | Existing repository handling is untouched. | None. |
| Commit state | N/A — no index/worktree operation changes. | None. | None. |
| Push state | N/A — no push operation exists. | None. | None. |
| PR commands | N/A — no PR command composition exists. | None. | None. |

## Migration / Rollout

No migration required. Document before release that Academic gains a dedicated cover, footer defaults change, and omitted cover titles hide the normalized fallback; explicit controls and PDF title fallback remain. Roll back Typst, fixture, harness, and docs together.

## Open Questions

None.
