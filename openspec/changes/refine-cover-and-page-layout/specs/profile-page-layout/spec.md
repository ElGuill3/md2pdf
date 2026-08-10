# Profile Page Layout Specification

## Purpose

Define profile-aware layout while preserving supplied metadata and configuration controls.

## Requirements

### Requirement: Profile-aware cover composition

Each enabled profile MUST render a golden-ratio/Fibonacci-inspired signature adapted to its existing identity. The cover MUST use non-empty supplied title, subtitle, author, affiliation, and date values and MUST NOT invent fields or values.

#### Scenario: Identity and sparse metadata

- GIVEN an enabled profile and any subset of the five metadata values
- WHEN a PDF is rendered
- THEN the cover shows the adapted signature and the supplied non-empty values.

#### Scenario: Cross-profile distinction

- GIVEN identical metadata rendered with two enabled profiles
- WHEN their covers are compared
- THEN the signatures are observably distinct and each reflects its profile.

### Requirement: Usable long and multilingual metadata

Long or multilingual supplied titles and subtitles MUST remain readable and contained. They MAY wrap or reflow but MUST NOT be silently truncated, clipped, overlapped, or overflow the page.

#### Scenario: Long or mixed-language title

- GIVEN a long or mixed-language title or subtitle in supplied metadata
- WHEN rendered for an enabled profile and configured orientation
- THEN all text remains contained and readable without collision, clipping, or loss.

### Requirement: Dedicated furniture-free covers

Every enabled profile, including Academic, MUST receive a dedicated cover page. It MUST honor configured paper size and orientation and contain no header, footer, or page number.

#### Scenario: Cover page honors configuration

- GIVEN an enabled profile, including Academic, and configured paper size and orientation
- WHEN a document with a cover is rendered
- THEN the cover occupies its own configured page and the body follows without cover furniture.

### Requirement: Profile-aware level-one bands preserve flow

Level-one headings MUST receive profile-aware title bands and remain in normal flow. A level-one heading MUST NOT force a chapter page break solely by level.

#### Scenario: Heading remains in normal flow

- GIVEN a level-one heading with enough space for its band and following content
- WHEN the document is rendered
- THEN the band appears without moving it to a new page solely by level.

#### Scenario: Boundary uses ordinary pagination

- GIVEN a level-one heading near a page boundary with insufficient space
- WHEN the document is rendered
- THEN any break follows ordinary layout constraints, not a mandatory chapter-opening rule.

### Requirement: Contextual running furniture

Without explicit overrides, headers MUST show current chapter context or document-title fallback. Enabled footers MUST show page number left and document title right, or an explicit footer title right. Header/footer enablement, explicit text, and page-numbering controls MUST preserve their effects.

#### Scenario: Default headers and footers

- GIVEN enabled furniture with no overrides across pages with and without chapter context
- WHEN the document is rendered
- THEN headers show chapter context or document-title fallback, while footers show numbering left and document title right.

#### Scenario: Explicit controls remain compatible

- GIVEN explicit header or footer text, customized numbering, or disabled furniture or numbering
- WHEN the document is rendered
- THEN explicit values remain, disabled elements stay absent, and numbering is preserved.

### Requirement: Observable compatibility and visual evidence

Verification MUST use real PDFs with semantic, geometric, and raster checks for compatibility and profile distinction. Render success alone MUST NOT count as visual evidence; a manually inspected cover/body pair MUST be recorded for every enabled profile, including Academic.

#### Scenario: Compatibility behavior is observable

- GIVEN a fixture exercising defaults, overrides, disabled controls, and heading flow
- WHEN real-PDF verification runs
- THEN it observes pagination, text, placement, and numbering rather than source text or exit status alone.

#### Scenario: Every profile has inspection evidence

- GIVEN one rendered cover/body pair for each enabled profile
- WHEN visual inspection is completed
- THEN evidence records each pair and confirms readable metadata, furniture-free covers, body layout, and profile distinction.
