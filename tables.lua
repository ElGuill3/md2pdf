-- tables.lua
-- Dos mejoras para pandoc → Typst:
--
-- 1. Código inline: escapa correctamente los delimitadores de Typst markup
--    (_*$~) y añade zero-width spaces para permitir wrapping en celdas.
--
-- 2. Tablas con más de WIDE_THRESHOLD columnas → páginas landscape.

if FORMAT ~= "typst" then return {} end

local WIDE_THRESHOLD = 5

-- U+200B ZERO WIDTH SPACE en UTF-8 (E2 80 8B) — punto de quiebre invisible
local ZWS = "\xE2\x80\x8B"

-- ── Añadir ZWS después de separadores (sobre el texto ORIGINAL) ─────────────
-- Se hace ANTES de escapar para que los _ originales sean detectables.
local function add_break_ops(s)
  return s:gsub("([/_%.%-%:])", "%1" .. ZWS)
end

-- ── Escapar caracteres especiales de Typst markup (dentro de [...]) ──────────
-- Se hace DESPUÉS de insertar ZWS.
-- En Typst markup, estos caracteres tienen significado especial:
--   _texto_  → énfasis (italic)   ← causa "unclosed delimiter" sin escapar
--   *texto*  → negrita
--   $expr$   → matemáticas inline
--   ~        → non-breaking space
--   #        → comando Typst
--   @        → referencia cruzada
--   < >      → auto-links
--   [ ]      → bloques de contenido
local function typst_escape(s)
  s = s:gsub("\\",  "\\\\")   -- backslash primero (siempre)
  s = s:gsub("%[",  "\\[")
  s = s:gsub("%]",  "\\]")
  s = s:gsub("#",   "\\#")
  s = s:gsub("@",   "\\@")
  s = s:gsub("<",   "\\<")
  s = s:gsub("_",   "\\_")    -- énfasis: causa "unclosed delimiter"
  s = s:gsub("%*",  "\\*")    -- negrita
  s = s:gsub("%$",  "\\$")    -- matemáticas inline (e.g. $VAR en shell)
  s = s:gsub("~",   "\\~")    -- non-breaking space
  return s
end

-- ── Código inline ────────────────────────────────────────────────────────────
function Code(el)
  -- Orden importante: ZWS primero (sobre el _ original), escape después
  local text = add_break_ops(el.text)
  text = typst_escape(text)
  -- Los bytes ZWS (U+200B) no contienen ningún char especial de Typst,
  -- así que typst_escape no los toca.
  return pandoc.RawInline(
    "typst",
    '#text(font: "JetBrains Mono", size: 9pt, fill: rgb("#1a3c6e"))'
    .. '[#highlight(fill: rgb("#e8f0fb"), radius: 3pt)['
    .. text
    .. ']]'
  )
end

-- ── Tablas anchas → páginas landscape ────────────────────────────────────────
function Table(el)
  local ncols = #el.colspecs
  if ncols <= WIDE_THRESHOLD then return end

  return {
    pandoc.RawBlock("typst", "#pagebreak()\n#set page(flipped: true)"),
    el,
    pandoc.RawBlock("typst", "#pagebreak()\n#set page(flipped: false)"),
  }
end
