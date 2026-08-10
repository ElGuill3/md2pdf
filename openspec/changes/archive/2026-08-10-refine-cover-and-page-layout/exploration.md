## Exploration: Refine Cover and Page Layout

### Current State
`md2pdf` has a clean three-stage presentation flow. The POSIX launcher stages the fixed Typst runtime and invokes Pandoc; `share/md2pdf/filters/runtime.lua` validates front matter, merges structural profile defaults, and writes `config.json`; `share/md2pdf/typst/document.typ` selects one of four visual profile themes and passes the document through `apply-theme` and `page-layout`.

The metadata pipeline already carries exactly the requested factual inputs: `title`, optional `subtitle`, authors with optional `affiliation`, and optional `date`. There is no organization or edition field. The cover should therefore render only non-empty existing values, treating an author affiliation as organizational context when supplied, rather than adding fields or labels. The CLI/profile precedence and metadata schema do not need to change.

`share/md2pdf/typst/page.typ` owns all cover and running-furniture rendering. Each profile has a separate cover branch using the existing navy/blue/gold palette, serif or sans profile font, and simple `rect`, `line`, `circle`, and gradient primitives. General, Technical, and Report end on a page break; Academic currently continues body content on the same page. Running headers are static document-title or explicit-text labels above a rule. Running footers show author semantics, or the date for Report, on the left and a gold page-number badge on the right. They are suppressed only on the first page when a cover is enabled.

`share/md2pdf/typst/theme.typ` owns heading hierarchy. Level-one headings vary by `heading-style`; level-two headings are already restrained, tracked, and uppercase outside Academic. Section numbering is driven by Typst's heading counter. Headings do not force chapter page breaks, and running furniture does not inspect the current level-one heading.

Profile identity is data-driven through `share/md2pdf/typst/profiles/shared.typ` and the four small profile modules. Existing tokens include profile colors, body/mono fonts, type sizes, paragraph rhythm, and `cover-style`/`heading-style`. The requested design can reuse these tokens without adding a new profile or dependency. The current identity is strongest in its navy/blue/gold palette, Libertinus/Noto typography, gold rules/nodes, and profile-specific density.

The real-PDF suite in `tests/run.sh` uses `profile-reference.md` across all four profiles, PDF metadata/text extraction, page-specific assertions, bounding boxes, rasterization smoke checks, SVG inspection for selected details, and pairwise PNG inequality to prove profiles remain visually distinct. It does not keep committed pixel goldens and does not prove that a specific visual composition is correct. The existing `profile-reference.md` already contains title, subtitle, affiliation, date, and two level-one headings, so it can carry most new regression evidence. Local visual execution is currently unavailable because Pandoc is missing; Typst 0.15.0 and the Poppler tools are installed.

### Affected Areas
- `share/md2pdf/typst/page.typ` — primary change: native cover signature, disciplined metadata cluster, dedicated cover behavior, current-chapter lookup, and revised header/footer composition.
- `share/md2pdf/typst/theme.typ` — primary change: thin profile-aware level-one title band and refined vertical rhythm; existing level-two treatment can be retained.
- `share/md2pdf/typst/profiles/shared.typ` — reuse its colors, fonts, rhythm, and style selectors; edit only if one small geometry/furniture token proves necessary.
- `share/md2pdf/typst/profiles/{general,technical,report,academic}.typ` — preserve profile differences; no change should be needed unless visual inspection shows one profile needs a local scale adjustment.
- `tests/run.sh` — update footer/header semantics, Academic cover pagination, page-specific chapter-title checks, bounding-box checks, raster smoke checks, and profile-distinctness evidence.
- `tests/fixtures/profile-reference.md` — reuse or minimally extend for chapter-page and long-title evidence; avoid a new fixture unless page placement cannot be made deterministic.
- `docs/configuration.md` — update documented default furniture semantics if the footer changes from author/date to document title.
- `share/md2pdf/filters/runtime.lua` — mapped but should remain unchanged; it already supplies all factual metadata and structural overrides required by the design.
- `md2pdf`, `install.sh`, and `uninstall.sh` — mapped but should remain unchanged with native Typst geometry because the edited Typst files are already staged and installed.

### Approaches
1. **Native Typst geometry and existing profile primitives** — draw a pale construction grid with `rect`/`line` and a short sequence of `curve.cubic` segments, then compose cover and page furniture from existing theme tokens.
   - Pros: No dependency or runtime asset; scales with configured paper/orientation; inherits each profile's gold, blue, gray, and typography; keeps changes concentrated in the two existing presentation modules; Typst 0.15 supports the required curve and introspection APIs.
   - Cons: The spiral is a controlled Bézier approximation and needs careful coordinates and visual inspection; dynamic chapter lookup must account for headings that start below the header on the same page.
   - Effort: Medium

2. **Bundled SVG cover signature** — add a designed SVG and place it behind the Typst cover content.
   - Pros: Exact, easy-to-preview artwork with little drawing code in `page.typ`.
   - Cons: Adds an asset plus launcher staging, installer runtime lists, uninstaller known-file lists, and installer tests; fixed SVG color/geometry adapts less naturally to four themes and multiple paper orientations; this is a larger change for no capability gain.
   - Effort: High

3. **User-provided or metadata-selected image** — reuse the existing local-image resource pipeline for cover artwork.
   - Pros: Reuses image validation and permits arbitrary art.
   - Cons: Requires a new metadata contract and security/resource handling for a purely built-in identity element; makes output source-dependent and violates the request to avoid invented or required metadata.
   - Effort: High

### Recommendation
Use native Typst geometry. It is the smallest compatible implementation and the best fit for md2pdf's existing profile architecture. Keep the current palette and fonts unchanged: the memorable element should be one very light gold/gray spiral-like construction spanning the cover, with at most one stronger gold node or rule from the current identity.

Refactor the cover into a common quiet composition with profile-specific type scale and spacing selected by the existing `cover-style`. Place an optional italic subtitle as the eyebrow, then the title, authors and affiliations, and date around the upper golden-ratio region. Omit absent values and their spacing. Do not add organization or edition metadata. Make every enabled cover, including Academic, a dedicated page, but continue honoring the configured paper and orientation rather than forcing a portrait page.

For interior pages, retain the profile colors and density while changing level-one headings to a thin framed band with the existing heading counter integrated into the frame. Do not force every level-one heading onto a new page; that would be a separate pagination behavior change. Keep the existing restrained level-two treatment rather than introducing potentially fragile font-specific small-cap behavior.

Build the running header from a fixed two-column grid and fine rule: section/page marker on the left, explicit `header.text` when present or the current level-one title on the right, falling back to the document title before any chapter. Resolve the current chapter by querying level-one headings and choosing the last heading whose `location().page()` is not after `here().page()`; using only `.before(here())` can incorrectly show the previous chapter on a chapter-opening page because the header is physically above the heading. Build the footer with page number left and explicit `footer.text` or document title right, plus a restrained gold corner/rule device. Preserve `header.enabled`, `footer.enabled`, and `footer.numbering` behavior.

Extend the existing real-PDF tests instead of introducing pixel goldens. Assert dedicated cover pagination, no cover furniture, current chapter text on selected body pages, explicit override preservation, footer title/page placement with Poppler bounding boxes, profile visual inequality, and successful cover/body rasterization. Verification must include manual inspection of all four profile cover/body pairs because the current suite has no stable visual baseline and local Pandoc is unavailable.

### Risks
- Changing Academic to a dedicated cover and changing default footer semantics will alter page counts and reader-visible output; the proposal and specs must state these compatibility changes explicitly.
- Typst contextual queries can show the previous chapter on chapter-opening pages if implemented with `before(here())` instead of physical page comparison.
- Long or multilingual chapter titles may wrap into the rule or consume header margin; include a constrained-layout regression case.
- A shared composition can accidentally make the four profiles too similar; retain the existing style branches and pairwise visual-distinctness checks.
- Pixel goldens would be brittle across Linux/macOS font and renderer differences; semantic/bounding-box checks plus inspected renders are safer.
- No current render could be inspected in this environment because Pandoc is missing, so visual quality remains unverified until apply/verify runs with the CI toolchain.

### Ready for Proposal
Yes. The proposal should scope the change to native Typst presentation primitives, no new metadata or dependencies, no forced chapter page breaks, and preservation of explicit header/footer overrides and profile identity. It should explicitly include the dedicated Academic cover and footer-default behavior changes, plus real-PDF and manual four-profile visual verification.
