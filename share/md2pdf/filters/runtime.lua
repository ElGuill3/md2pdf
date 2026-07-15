local stringify = pandoc.utils.stringify

local stage_dir = os.getenv("MD2PDF_STAGE_DIR")
local source_dir = os.getenv("MD2PDF_SOURCE_DIR")
local cli_profile = os.getenv("MD2PDF_CLI_PROFILE") or ""
local error_file = os.getenv("MD2PDF_FILTER_ERROR")

local profiles = {
  general = {},
  technical = {
    page = {
      margins = {
        top = 56.69291339,
        bottom = 56.69291339,
        left = 51.02362205,
        right = 51.02362205,
      },
    },
    cover = true,
    toc = { enabled = true, depth = 4 },
    section_numbering = true,
  },
  report = {
    page = {
      margins = {
        top = 70.86614173,
        bottom = 70.86614173,
        left = 70.86614173,
        right = 70.86614173,
      },
    },
    cover = true,
    toc = { enabled = true, depth = 3 },
    section_numbering = true,
  },
  academic = {
    page = {
      margins = {
        top = 70.86614173,
        bottom = 70.86614173,
        left = 68.03149606,
        right = 68.03149606,
      },
    },
    cover = true,
    toc = { enabled = false, depth = 3 },
    section_numbering = true,
  },
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

  local preferred_body = config.profile == "technical" and
    "Noto Sans" or "Libertinus Serif"
  local fonts, font_message = io.open(stage_dir .. "/preferred-fonts.txt", "wb")
  if not fonts then
    abort("cannot write preferred font policy: " .. tostring(font_message))
  end
  fonts:write("body|", preferred_body, "\nmono|IosevkaTerm NF\n")
  fonts:close()
end

local staged_images = {}
local staged_resources = {}
local remote_images = {}
local remote_failures = {}
local citation_keys = {}
local max_remote_bytes = 5 * 1024 * 1024

local function resolve_local_resource(target, label)
  if target:sub(1, 1) == "/" then
    abort("absolute " .. label .. " paths are not permitted: " .. target)
  end

  local parts = {}
  for component in target:gmatch("[^/]+") do
    if component == ".." then
      if #parts == 0 then
        abort(label .. " path escapes the source directory: " .. target)
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
    abort(label .. " path traverses a symbolic link: " .. target)
  end
  return relative, source_dir .. "/" .. relative
end

local function safe_basename(relative, fallback)
  local basename = relative:match("([^/]+)$") or fallback
  basename = basename:gsub("[^%w._-]", "_")
  if basename == "" or basename == "." or basename == ".." then
    return fallback
  end
  return basename
end

local function copy_local_resource(target, label, directory)
  if target:find("\0", 1, true) then
    abort(label .. " paths cannot contain a null byte")
  end
  if target:find("[?#]") then
    abort(label .. " paths cannot contain a query or fragment: " .. target)
  end

  local relative_source, source = resolve_local_resource(target, label)
  local existing = staged_resources[source]
  if existing then
    return existing
  end

  local input, message = io.open(source, "rb")
  if not input then
    abort(label .. " is missing or unreadable: " .. target .. " (" ..
      tostring(message) .. ")")
  end

  local basename = safe_basename(relative_source, "resource")
  local relative = directory .. "/" .. pandoc.sha1(source):sub(1, 16) ..
    "-" .. basename
  local output, output_message = io.open(stage_dir .. "/" .. relative, "wb")
  if not output then
    input:close()
    abort("cannot stage " .. label .. ": " .. target .. " (" ..
      tostring(output_message) .. ")")
  end

  while true do
    local chunk = input:read(65536)
    if not chunk then break end
    output:write(chunk)
  end
  input:close()
  output:close()

  staged_resources[source] = relative
  return relative
end

local function touch_stage_file(name)
  local handle, message = io.open(stage_dir .. "/" .. name, "wb")
  if not handle then
    abort("cannot record citation state: " .. tostring(message))
  end
  handle:close()
end

local function citation_paths(value, path)
  local kind = value_type(value)
  if kind == "string" or kind == "Inlines" or kind == "Blocks" then
    return { scalar(value, path, false) }
  end
  if (kind ~= "table" and kind ~= "List") or not is_sequence(value) then
    abort(path .. " must be a string or list of strings")
  end
  local result = {}
  for index, item in ipairs(value) do
    result[index] = scalar(item, path .. "[" .. index .. "]", false)
  end
  return result
end

local function stage_citation_path(target, label, extension)
  if target:match("^//") or target:match("^[%a][%w%+%.%-]*:") then
    abort(label .. " must be a local " .. extension .. " file: " .. target)
  end
  if target:lower():sub(-#extension) ~= extension then
    abort(label .. " must use the " .. extension .. " extension: " .. target)
  end
  return copy_local_resource(target, label, "citations")
end

local function register_references(value, path)
  if value == nil then return end
  local kind = value_type(value)
  if (kind ~= "table" and kind ~= "List") or not is_sequence(value) then
    abort(path .. " must be a list of citation records")
  end
  for index, reference in ipairs(value) do
    local record = mapping(reference, path .. "[" .. index .. "]")
    if record.id == nil then
      abort(path .. "[" .. index .. "].id is required")
    end
    citation_keys[scalar(record.id, path .. "[" .. index .. "].id", false)] = true
  end
end

local function register_bibliography(relative, target)
  local handle, message = io.open(stage_dir .. "/" .. relative, "rb")
  if not handle then
    abort("bibliography is unreadable after staging: " .. target .. " (" ..
      tostring(message) .. ")")
  end
  local contents = handle:read("*a")
  handle:close()
  local ok, bibliography = pcall(pandoc.read, contents, "bibtex")
  if not ok then
    abort("bibliography is invalid: " .. target)
  end
  register_references(bibliography.meta.references, "bibliography " .. target)
end

local function stage_citations(meta, config)
  local requested = false
  register_references(meta.references, "references")
  if meta.bibliography ~= nil then
    local staged = {}
    for index, target in ipairs(citation_paths(meta.bibliography, "bibliography")) do
      local relative = stage_citation_path(target, "bibliography", ".bib")
      register_bibliography(relative, target)
      staged[index] = pandoc.MetaString(stage_dir .. "/" .. relative)
    end
    meta.bibliography = pandoc.MetaList(staged)
    requested = true
    if meta["reference-section-title"] == nil then
      local title = config.lang:lower():match("^es") and "Referencias" or "References"
      meta["reference-section-title"] = pandoc.MetaString(title)
    end
  end

  if meta.csl ~= nil then
    local target = scalar(meta.csl, "csl", false)
    meta.csl = pandoc.MetaString(
      stage_dir .. "/" .. stage_citation_path(target, "csl", ".csl"))
    requested = true
  end

  if requested then
    touch_stage_file("citations-requested")
  end
  return meta
end

local function validate_citation_keys(document)
  local unresolved = {}
  document:walk({
    Cite = function(cite)
      for _, citation in ipairs(cite.citations) do
        if not citation_keys[citation.id] then unresolved[citation.id] = true end
      end
    end,
  })
  local keys = {}
  for key in pairs(unresolved) do keys[#keys + 1] = "@" .. key end
  if #keys > 0 then
    table.sort(keys)
    abort("unresolved citation: " .. table.concat(keys, ", "))
  end
end

local remote_mimes = {
  ["image/png"] = ".png",
  ["image/jpeg"] = ".jpg",
  ["image/gif"] = ".gif",
  ["image/svg+xml"] = ".svg",
  ["image/webp"] = ".webp",
}

local function valid_image_payload(mime, payload)
  if mime == "image/png" then
    return payload:sub(1, 8) == "\137PNG\13\10\26\10"
  end
  if mime == "image/jpeg" then
    return payload:sub(1, 3) == "\255\216\255"
  end
  if mime == "image/gif" then
    local signature = payload:sub(1, 6)
    return signature == "GIF87a" or signature == "GIF89a"
  end
  if mime == "image/webp" then
    return payload:sub(1, 4) == "RIFF" and payload:sub(9, 12) == "WEBP"
  end
  if mime == "image/svg+xml" then
    return payload:sub(1, 1024):lower():find("<svg", 1, true) ~= nil
  end
  return false
end

local function remote_placeholder(image, target, reason, warn)
  if warn ~= false then
    pandoc.log.warn("remote image unavailable; using linked placeholder (" ..
      target .. "): " .. reason)
  end
  local description = stringify(image.caption)
  if description == "" then description = "remote image" end
  return pandoc.Link(
    { pandoc.Str("Remote image unavailable: " .. description) },
    target,
    image.title
  )
end

local function remote_failure(image, target, reason)
  local cached = remote_failures[target]
  if cached then
    return remote_placeholder(image, target, cached, false)
  end
  remote_failures[target] = reason
  return remote_placeholder(image, target, reason, true)
end

local function private_ipv4(host)
  local first, second, third, fourth =
    host:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
  first, second, third, fourth = tonumber(first), tonumber(second),
    tonumber(third), tonumber(fourth)
  if not first or first > 255 or second > 255 or third > 255 or fourth > 255 then
    return false
  end
  return first == 0 or first == 10 or first == 127 or
    (first == 169 and second == 254) or
    (first == 172 and second >= 16 and second <= 31) or
    (first == 192 and second == 168)
end

local function blocked_remote_host(target)
  local authority = target:match("^[Hh][Tt][Tt][Pp][Ss]://([^/?#]+)")
  if not authority then return "invalid HTTPS URL" end
  authority = authority:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)
  authority = authority:match(".*@(.*)$") or authority

  local host = authority:match("^%[([^%]]+)%]") or authority:match("^([^:]+)") or ""
  host = host:lower():gsub("%.$", "")
  if host == "localhost" or host:match("%.localhost$") or
     host == "localhost.localdomain" or host:match("%.localhost%.localdomain$") then
    return "localhost hostnames are not permitted"
  end
  if host == "localhost6" or host == "localhost6.localdomain6" or
     host == "ip6-localhost" or host == "ip6-loopback" then
    return "localhost hostnames are not permitted"
  end
  if private_ipv4(host) then
    return "loopback, link-local, and private IP literals are not permitted"
  end

  local mapped_ipv4 = host:match("^::ffff:(%d+%.%d+%.%d+%.%d+)$")
  if host == "::" or host == "::1" or host == "0:0:0:0:0:0:0:0" or
     host == "0:0:0:0:0:0:0:1" or host:match("^f[cd]") or
     host:match("^fe[89ab]") or (mapped_ipv4 and private_ipv4(mapped_ipv4)) then
    return "loopback, link-local, and private IP literals are not permitted"
  end
  return nil
end

local function download_reached_limit(path)
  local handle = io.open(path, "rb")
  if not handle then return false end
  local payload = handle:read(max_remote_bytes) or ""
  handle:close()
  return #payload >= max_remote_bytes
end

local function fetch_remote_image(image, target)
  local existing = remote_images[target]
  if existing then
    image.src = existing
    return image
  end
  if remote_failures[target] then
    return remote_placeholder(image, target, remote_failures[target], false)
  end

  local blocked = blocked_remote_host(target)
  if blocked then return remote_failure(image, target, blocked) end

  local download = stage_dir .. "/assets/remote-" ..
    pandoc.sha1(target):sub(1, 20) .. ".download"
  local curl_arguments = {
    "--location",
    "--max-redirs", "5",
    "--fail",
    "--silent",
    "--show-error",
    "--proto", "=https",
    "--proto-redir", "=https",
    "--connect-timeout", "5",
    "--max-time", "20",
    "--max-filesize", tostring(max_remote_bytes),
    "--user-agent", "md2pdf/0.1.0",
    "--output", download,
    "--write-out", "%{content_type}",
    "--",
    target,
  }
  local shell_arguments = {
    "-c",
    [[
limit=$1
shift
if ulimit -f "$limit" 2>/dev/null; then
  exec curl "$@"
fi
exec curl "$@"
]],
    "md2pdf-remote-fetch",
    tostring(max_remote_bytes / 512),
  }
  for _, argument in ipairs(curl_arguments) do
    shell_arguments[#shell_arguments + 1] = argument
  end
  local ok, mime = pcall(
    pandoc.pipe,
    "sh",
    shell_arguments,
    ""
  )
  if not ok then
    local reason = download_reached_limit(download) and
      "payload exceeds 5 MiB" or "HTTPS fetch failed"
    os.remove(download)
    return remote_failure(image, target, reason)
  end

  mime = trim(mime):lower():match("^[^;%s]+") or ""
  local extension = remote_mimes[mime]
  if not extension then
    os.remove(download)
    return remote_failure(image, target,
      "unsupported response MIME type '" .. (mime ~= "" and mime or "unknown") .. "'")
  end

  local input, message = io.open(download, "rb")
  if not input then
    return remote_failure(image, target,
      "fetched payload is unreadable (" .. tostring(message) .. ")")
  end
  local payload = input:read(max_remote_bytes + 1) or ""
  input:close()
  if #payload > max_remote_bytes then
    os.remove(download)
    return remote_failure(image, target, "payload exceeds 5 MiB")
  end
  if not valid_image_payload(mime, payload) then
    os.remove(download)
    return remote_failure(image, target, "response is not a valid " .. mime .. " image")
  end

  local relative = "assets/remote-" .. pandoc.sha1(target):sub(1, 20) .. extension
  if not os.rename(download, stage_dir .. "/" .. relative) then
    os.remove(download)
    return remote_failure(image, target, "cannot stage fetched payload")
  end
  remote_images[target] = relative
  image.src = relative
  return image
end

local function copy_image(image)
  local target = image.src
  local scheme = target:match("^([%a][%w%+%.%-]*):")
  if target:match("^//") then
    return remote_failure(image, target, "scheme-relative URLs are not permitted")
  end
  if scheme then
    if scheme:lower() == "https" then
      return fetch_remote_image(image, target)
    end
    return remote_failure(image, target,
      "only HTTPS remote images are permitted (received " .. scheme:lower() .. ")")
  end

  target = target:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)
  local relative = copy_local_resource(target, "local image", "assets")
  staged_images[target] = relative
  image.src = relative
  return image
end

local function reject_raw_typst(element)
  if element.format and element.format:lower() == "typst" then
    abort("raw Typst input is not permitted")
  end
end

local alert_kinds = {
  note = true,
  tip = true,
  important = true,
  warning = true,
  caution = true,
}

local function alert_blocks(kind, blocks)
  local result = {
    pandoc.RawBlock("typst", '#md2pdf-alert("' .. kind .. '")[\n'),
  }
  for _, block in ipairs(blocks) do
    result[#result + 1] = block
  end
  result[#result + 1] = pandoc.RawBlock("typst", "\n]\n")
  return result
end

local function blockquote_alert(quote)
  local first = quote.content[1]
  if not first or (first.t ~= "Para" and first.t ~= "Plain") then
    return nil
  end
  local marker = first.content[1]
  if not marker or marker.t ~= "Str" then return nil end
  local kind = marker.text:match("^%[!([%a]+)%]$")
  if not kind then return nil end
  kind = kind:lower()
  if not alert_kinds[kind] then return nil end

  first.content:remove(1)
  if first.content[1] and
     (first.content[1].t == "Space" or first.content[1].t == "SoftBreak" or
      first.content[1].t == "LineBreak") then
    first.content:remove(1)
  end
  if #first.content == 0 then
    quote.content:remove(1)
  end
  return alert_blocks(kind, quote.content)
end

local function div_alert(div)
  local kind
  for _, class in ipairs(div.classes) do
    if alert_kinds[class:lower()] then
      kind = class:lower()
      break
    end
  end
  if not kind then return nil end

  if div.content[1] and div.content[1].t == "Div" then
    for _, class in ipairs(div.content[1].classes) do
      if class == "title" then
        div.content:remove(1)
        break
      end
    end
  end
  return alert_blocks(kind, div.content)
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
  document.meta = stage_citations(document.meta, config)
  validate_citation_keys(document)
  write_config(config)

  document = document:walk({
    Image = copy_image,
    RawBlock = reject_raw_typst,
    RawInline = reject_raw_typst,
  })
  document = document:walk({
    BlockQuote = blockquote_alert,
    Div = div_alert,
  })
  document = document:walk({ Table = wide_table(config) })
  return document
end
