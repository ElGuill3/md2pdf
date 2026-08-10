# Proposal: Refine Cover and Page Layout

## Intent

Strengthen md2pdf's editorial identity with a restrained golden-ratio/Fibonacci-inspired cover signature, disciplined metadata, useful running furniture, and clearer chapter openings. Adapt the references rather than copying them.

## Scope

### In Scope
- Draw a responsive cover grid and spiral-like curve with native Typst and existing profile tokens.
- Compose only non-empty existing metadata while preserving profile typography and density.
- Give every enabled cover, including Academic, a dedicated page using configured paper and orientation.
- Add profile-aware level-one bands without forced chapter breaks.
- Default headers to current chapter context and footers to page number plus document title; preserve explicit text, enablement, and numbering overrides.
- Extend real-PDF checks and require inspected cover/body renders for all profiles.

### Out of Scope
- New metadata, profiles, dependencies, artwork assets, forced chapter pagination, or CLI/filter schema changes.
- Level-two, font, or palette redesign; pixel-golden snapshots.

## Capabilities

### New Capabilities
- `profile-page-layout`: Profile-aware covers, chapter treatment, running furniture, compatibility behavior, and visual evidence.

### Modified Capabilities
None; no existing OpenSpec capabilities are present.

## Approach

Concentrate presentation changes in `page.typ` and `theme.typ`, reusing current tokens and style branches. Build the signature from a small grid and Bézier segments. Resolve level-one headings by physical page number so chapter-opening headers avoid stale text. Extend semantic, bounding-box, raster, and profile-inequality tests instead of adding assets or goldens.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `share/md2pdf/typst/page.typ` | Modified | Covers, pagination, headers, and footers |
| `share/md2pdf/typst/theme.typ` | Modified | Level-one bands and rhythm |
| `tests/run.sh`, `tests/fixtures/profile-reference.md` | Modified | Compatibility and visual evidence |
| `docs/configuration.md` | Modified | Furniture defaults |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Academic pagination and footer output change | High | Specify and test compatibility behavior |
| Chapter lookup selects stale text | Medium | Compare physical page numbers |
| Long titles collide or wrap poorly | Medium | Test constraints and inspect renders |
| Profiles become too similar | Medium | Retain branches and inequality checks |

## Rollback Plan

Revert Typst, test, fixture, and documentation changes together. No migration or cleanup is required.

## Dependencies

- No new dependencies; verification uses existing Pandoc 3.8, Typst 0.15, and Poppler.

## Success Criteria

- [ ] All profiles render dedicated, furniture-free covers using only supplied metadata.
- [ ] Tests prove chapter-aware headers, revised footers, explicit overrides, and no forced chapter breaks.
- [ ] Bounding-box, raster, and profile-distinctness checks pass on Ubuntu and macOS.
- [ ] Evidence includes manual inspection of every profile's cover/body pair; rendering alone is insufficient.
