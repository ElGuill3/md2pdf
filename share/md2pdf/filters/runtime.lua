local stringify = pandoc.utils.stringify

local stage_dir = os.getenv("MD2PDF_STAGE_DIR")
local source_dir = os.getenv("MD2PDF_SOURCE_DIR")
local cli_profile = os.getenv("MD2PDF_CLI_PROFILE") or ""
local error_file = os.getenv("MD2PDF_FILTER_ERROR")

local profiles = {
  general = {},
  technical = {},
  report = {},
  academic = {},
}

local base = {
  profile = "general",
  title = "Document",
  subtitle = "",
  authors = {},
  date = "",
  lang = "en",
  page = {
    paper = "a4",
    orientation = "portrait",
    margins = {
      top = 79.37007874,
      bottom = 79.37007874,
      left = 70.86614173,
      right = 70.86614173,
    },
  },
  cover = true,
  toc = { enabled = true, depth = 3 },
  section_numbering = false,
  header = { enabled = true, text = "" },
  footer = { enabled = true, text = "", numbering = true },
}

local paper_names = {
  a3 = true,
  a4 = true,
  a5 = true,
  letter = true,
  legal = true,
}

local function abort(message)
  if error_file then
    local handle = io.open(error_file, "wb")
    if handle then
      handle:write(message)
      handle:close()
    end
  end
  error("md2pdf filter aborted", 0)
end

if not stage_dir or stage_dir == "" or not source_dir or source_dir == "" then
  abort("the Pandoc filter requires a trusted staging environment")
end

local function value_type(value)
  return pandoc.utils.type(value)
end

local function trim(value)
  return value:match("^%s*(.-)%s*$")
end

local function scalar(value, path, allow_empty)
  local kind = value_type(value)
  if kind ~= "string" and kind ~= "Inlines" and kind ~= "Blocks" then
    abort(path .. " must be a string")
  end
  local result = stringify(value)
  if not allow_empty and result == "" then
    abort(path .. " must not be empty")
  end
  return result
end

local function boolean(value, path)
  if value_type(value) ~= "boolean" then
    abort(path .. " must be a boolean")
  end
  return value
end

local function integer(value, path, minimum, maximum)
  local text = scalar(value, path, false)
  if not text:match("^%d+$") then
    abort(path .. " must be an integer")
  end
  local result = tonumber(text)
  if result < minimum or result > maximum then
    abort(path .. " must be between " .. minimum .. " and " .. maximum)
  end
  return result
end

local function is_sequence(value)
  local kind = value_type(value)
  if kind == "List" then
    return true
  end
  if kind ~= "table" then
    return false
  end
  for key in pairs(value) do
    if type(key) == "number" then
      return true
    end
  end
  return false
end

local function mapping(value, path)
  if value_type(value) ~= "table" or is_sequence(value) then
    abort(path .. " must be a mapping")
  end
  return value
end

local function reject_unknown(map, allowed, path)
  for key in pairs(map) do
    if type(key) == "string" and not allowed[key] then
      abort(path .. " contains unknown key '" .. key .. "'")
    end
  end
end

local function clone(value)
  if type(value) ~= "table" then
    return value
  end
  local result = {}
  for key, child in pairs(value) do
    result[key] = clone(child)
  end
  return result
end

local function merge(target, source)
  for key, value in pairs(source) do
    if type(value) == "table" and type(target[key]) == "table" then
      merge(target[key], value)
    else
      target[key] = clone(value)
    end
  end
end

local function profile_name(value, path)
  local result = scalar(value, path, false)
  if not profiles[result] then
    abort(path .. " has unknown profile '" .. result .. "'")
  end
  return result
end

local function author_detail(value, path)
  local kind = value_type(value)
  if kind == "string" or kind == "Inlines" or kind == "Blocks" then
    return scalar(value, path, true)
  end
  if (kind == "table" or kind == "List") and is_sequence(value) then
    local parts = {}
    for index, item in ipairs(value) do
      parts[index] = scalar(item, path .. "[" .. index .. "]", false)
    end
    return table.concat(parts, "; ")
  end
  abort(path .. " must be a string or list of strings")
end

local function one_author(value, path)
  local kind = value_type(value)
  if kind == "string" or kind == "Inlines" or kind == "Blocks" then
    return { name = scalar(value, path, false), affiliation = "", email = "" }
  end

  local map = mapping(value, path)
  reject_unknown(map, { name = true, affiliation = true, email = true }, path)
  if map.name == nil then
    abort(path .. ".name is required")
  end
  return {
    name = scalar(map.name, path .. ".name", false),
    affiliation = map.affiliation and
      author_detail(map.affiliation, path .. ".affiliation") or "",
    email = map.email and scalar(map.email, path .. ".email", true) or "",
  }
end

local function authors(value, path)
  local kind = value_type(value)
  if (kind ~= "table" and kind ~= "List") or not is_sequence(value) then
    return { one_author(value, path) }
  end
  local result = {}
  for index, item in ipairs(value) do
    result[index] = one_author(item, path .. "[" .. index .. "]")
  end
  return result
end

local function length_in_points(value, path)
  local text = trim(scalar(value, path, false))
  local amount, unit = text:match("^(%d+%.?%d*)(%a+)$")
  local factors = { pt = 1, mm = 72 / 25.4, cm = 72 / 2.54, ['in'] = 72 }
  if not amount or not factors[unit] then
    abort(path .. " must be a non-negative length in pt, mm, cm, or in")
  end
  return tonumber(amount) * factors[unit]
end

local function apply_margins(config, value, path)
  local kind = value_type(value)
  if kind == "string" or kind == "Inlines" or kind == "Blocks" then
    local points = length_in_points(value, path)
    config.page.margins = {
      top = points,
      bottom = points,
      left = points,
      right = points,
    }
    return
  end

  local map = mapping(value, path)
  reject_unknown(map, { top = true, bottom = true, left = true, right = true }, path)
  for _, side in ipairs({ "top", "bottom", "left", "right" }) do
    if map[side] ~= nil then
      config.page.margins[side] = length_in_points(map[side], path .. "." .. side)
    end
  end
end

local function apply_page(config, value, path)
  local map = mapping(value, path)
  reject_unknown(map, { paper = true, orientation = true, margins = true }, path)
  if map.paper ~= nil then
    local paper = scalar(map.paper, path .. ".paper", false):lower()
    if not paper_names[paper] then
      abort(path .. ".paper has unsupported value '" .. paper .. "'")
    end
    config.page.paper = paper
  end
  if map.orientation ~= nil then
    local orientation = scalar(map.orientation, path .. ".orientation", false):lower()
    if orientation ~= "portrait" and orientation ~= "landscape" then
      abort(path .. ".orientation must be 'portrait' or 'landscape'")
    end
    config.page.orientation = orientation
  end
  if map.margins ~= nil then
    apply_margins(config, map.margins, path .. ".margins")
  end
end

local function apply_toc(config, value, path)
  if value_type(value) == "boolean" then
    config.toc.enabled = boolean(value, path)
    return
  end
  local map = mapping(value, path)
  reject_unknown(map, { enabled = true, depth = true }, path)
  if map.enabled ~= nil then
    config.toc.enabled = boolean(map.enabled, path .. ".enabled")
  end
  if map.depth ~= nil then
    config.toc.depth = integer(map.depth, path .. ".depth", 1, 6)
  end
end

local function apply_header(config, value, path)
  if value_type(value) == "boolean" then
    config.header.enabled = boolean(value, path)
    return
  end
  local map = mapping(value, path)
  reject_unknown(map, { enabled = true, text = true }, path)
  if map.enabled ~= nil then
    config.header.enabled = boolean(map.enabled, path .. ".enabled")
  end
  if map.text ~= nil then
    config.header.text = scalar(map.text, path .. ".text", true)
  end
end

local function apply_footer(config, value, path)
  if value_type(value) == "boolean" then
    config.footer.enabled = boolean(value, path)
    return
  end
  local map = mapping(value, path)
  reject_unknown(map, { enabled = true, text = true, numbering = true }, path)
  if map.enabled ~= nil then
    config.footer.enabled = boolean(map.enabled, path .. ".enabled")
  end
  if map.text ~= nil then
    config.footer.text = scalar(map.text, path .. ".text", true)
  end
  if map.numbering ~= nil then
    config.footer.numbering = boolean(map.numbering, path .. ".numbering")
  end
end

local function normalize(meta)
  local namespace = {}
  if meta.md2pdf ~= nil then
    namespace = mapping(meta.md2pdf, "md2pdf")
    reject_unknown(namespace, {
      profile = true,
      page = true,
      cover = true,
      toc = true,
      ["toc-depth"] = true,
      ["section-numbering"] = true,
      ["number-sections"] = true,
      header = true,
      footer = true,
    }, "md2pdf")
  end

  if meta.profile ~= nil and namespace.profile ~= nil then
    abort("profile and md2pdf.profile cannot both be set")
  end

  local yaml_profile = "general"
  if namespace.profile ~= nil then
    yaml_profile = profile_name(namespace.profile, "md2pdf.profile")
  elseif meta.profile ~= nil then
    yaml_profile = profile_name(meta.profile, "profile")
  end

  local selected_profile = yaml_profile
  if cli_profile ~= "" then
    if not profiles[cli_profile] then
      abort("CLI profile has unknown profile '" .. cli_profile .. "'")
    end
    selected_profile = cli_profile
  end

  local config = clone(base)
  merge(config, profiles[selected_profile])
  config.profile = selected_profile

  if meta.title ~= nil then
    config.title = scalar(meta.title, "title", true)
  end
  if meta.subtitle ~= nil then
    config.subtitle = scalar(meta.subtitle, "subtitle", true)
  end
  if meta.author ~= nil and meta.authors ~= nil then
    abort("author and authors cannot both be set")
  end
  if meta.author ~= nil then
    config.authors = authors(meta.author, "author")
  elseif meta.authors ~= nil then
    config.authors = authors(meta.authors, "authors")
  end
  if meta.date ~= nil then
    config.date = scalar(meta.date, "date", true)
  end
  if meta.lang ~= nil then
    local lang = scalar(meta.lang, "lang", false)
    if not lang:match("^[A-Za-z][A-Za-z0-9-]*$") then
      abort("lang must be a language tag")
    end
    config.lang = lang
  end
  if meta.toc ~= nil then
    config.toc.enabled = boolean(meta.toc, "toc")
  end
  if meta["toc-depth"] ~= nil then
    config.toc.depth = integer(meta["toc-depth"], "toc-depth", 1, 6)
  end
  if meta["number-sections"] ~= nil then
    config.section_numbering = boolean(meta["number-sections"], "number-sections")
  end

  if namespace.page ~= nil then
    apply_page(config, namespace.page, "md2pdf.page")
  end
  if namespace.cover ~= nil then
    config.cover = boolean(namespace.cover, "md2pdf.cover")
  end
  if namespace.toc ~= nil then
    apply_toc(config, namespace.toc, "md2pdf.toc")
  end
  if namespace["toc-depth"] ~= nil then
    config.toc.depth = integer(namespace["toc-depth"], "md2pdf.toc-depth", 1, 6)
  end
  if namespace["section-numbering"] ~= nil then
    config.section_numbering = boolean(
      namespace["section-numbering"], "md2pdf.section-numbering")
  end
  if namespace["number-sections"] ~= nil then
    config.section_numbering = boolean(
      namespace["number-sections"], "md2pdf.number-sections")
  end
  if namespace.header ~= nil then
    apply_header(config, namespace.header, "md2pdf.header")
  end
  if namespace.footer ~= nil then
    apply_footer(config, namespace.footer, "md2pdf.footer")
  end

  return config
end

local function json_string(value)
  local escaped = value:gsub('[%z\1-\31\\"]', function(character)
    if character == '"' then return '\\"' end
    if character == '\\' then return '\\\\' end
    if character == '\b' then return '\\b' end
    if character == '\f' then return '\\f' end
    if character == '\n' then return '\\n' end
    if character == '\r' then return '\\r' end
    if character == '\t' then return '\\t' end
    return string.format("\\u%04x", character:byte())
  end)
  return '"' .. escaped .. '"'
end

local function json_boolean(value)
  return value and "true" or "false"
end

local function write_config(config)
  local author_values = {}
  for index, author in ipairs(config.authors) do
    author_values[index] = string.format(
      '{"name":%s,"affiliation":%s,"email":%s}',
      json_string(author.name),
      json_string(author.affiliation),
      json_string(author.email)
    )
  end

  local contents = string.format([[
{
  "profile": %s,
  "title": %s,
  "subtitle": %s,
  "authors": [%s],
  "date": %s,
  "lang": %s,
  "page": {
    "paper": %s,
    "orientation": %s,
    "margins": {"top": %.8f, "bottom": %.8f, "left": %.8f, "right": %.8f}
  },
  "cover": %s,
  "toc": {"enabled": %s, "depth": %d},
  "section_numbering": %s,
  "header": {"enabled": %s, "text": %s},
  "footer": {"enabled": %s, "text": %s, "numbering": %s}
}
]],
    json_string(config.profile),
    json_string(config.title),
    json_string(config.subtitle),
    table.concat(author_values, ","),
    json_string(config.date),
    json_string(config.lang),
    json_string(config.page.paper),
    json_string(config.page.orientation),
    config.page.margins.top,
    config.page.margins.bottom,
    config.page.margins.left,
    config.page.margins.right,
    json_boolean(config.cover),
    json_boolean(config.toc.enabled),
    config.toc.depth,
    json_boolean(config.section_numbering),
    json_boolean(config.header.enabled),
    json_string(config.header.text),
    json_boolean(config.footer.enabled),
    json_string(config.footer.text),
    json_boolean(config.footer.numbering)
  )

  local handle, message = io.open(stage_dir .. "/config.json", "wb")
  if not handle then
    abort("cannot write normalized metadata: " .. tostring(message))
  end
  handle:write(contents)
  handle:close()
end

local staged_images = {}

local function resolve_local_image(target)
  if target:sub(1, 1) == "/" then
    abort("absolute local image paths are not permitted: " .. target)
  end

  local parts = {}
  for component in target:gmatch("[^/]+") do
    if component == ".." then
      if #parts == 0 then
        abort("local image path escapes the source directory: " .. target)
      end
      table.remove(parts)
    elseif component ~= "." then
      parts[#parts + 1] = component
    end
  end

  local relative = table.concat(parts, "/")
  local probe = [[
set -f
path=$1
IFS=/
for component in $2; do
  path=$path/$component
  if [ -L "$path" ]; then
    printf symlink
    exit
  fi
done
]]
  local result = pandoc.pipe(
    "sh", { "-c", probe, "md2pdf-image-probe", source_dir, relative }, ""
  )
  if result == "symlink" then
    abort("local image path traverses a symbolic link: " .. target)
  end
  return relative, source_dir .. "/" .. relative
end

local function copy_image(image)
  local target = image.src:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)
  if target:find("\0", 1, true) then
    abort("local image targets cannot contain a null byte")
  end
  if target:match("^//") or target:match("^[%a][%w%+%.%-]*:") then
    abort("remote image resources are not supported: " .. target)
  end
  if target:find("[?#]") then
    abort("local image targets cannot contain a query or fragment: " .. target)
  end

  local relative_source, source = resolve_local_image(target)

  local existing = staged_images[source]
  if existing then
    image.src = existing
    return image
  end

  local input, message = io.open(source, "rb")
  if not input then
    abort("local image is missing or unreadable: " .. target .. " (" ..
      tostring(message) .. ")")
  end

  local basename = relative_source:match("([^/]+)$") or "image"
  basename = basename:gsub("[^%w._-]", "_")
  if basename == "" or basename == "." or basename == ".." then
    basename = "image"
  end
  local relative = "assets/" .. pandoc.sha1(source):sub(1, 16) .. "-" .. basename
  local output, output_message = io.open(stage_dir .. "/" .. relative, "wb")
  if not output then
    input:close()
    abort("cannot stage local image: " .. target .. " (" ..
      tostring(output_message) .. ")")
  end

  while true do
    local chunk = input:read(65536)
    if not chunk then break end
    output:write(chunk)
  end
  input:close()
  output:close()

  staged_images[source] = relative
  image.src = relative
  return image
end

local function reject_raw_typst(element)
  if element.format and element.format:lower() == "typst" then
    abort("raw Typst input is not permitted")
  end
end

local function wide_table(config)
  return function(table_element)
    if #table_element.colspecs <= 5 or config.page.orientation == "landscape" then
      return nil
    end
    return {
      pandoc.RawBlock("typst", "#pagebreak()\n#set page(flipped: true)"),
      table_element,
      pandoc.RawBlock("typst", "#pagebreak()\n#set page(flipped: false)"),
    }
  end
end

function Pandoc(document)
  local config = normalize(document.meta)
  write_config(config)

  document = document:walk({
    Image = copy_image,
    RawBlock = reject_raw_typst,
    RawInline = reject_raw_typst,
  })
  document = document:walk({ Table = wide_table(config) })
  return document
end
