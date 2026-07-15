local error_file = os.getenv("MD2PDF_FILTER_ERROR")
local stage_dir = os.getenv("MD2PDF_STAGE_DIR")

local function abort(message)
  if error_file then
    local handle = io.open(error_file, "wb")
    if handle then
      handle:write(message)
      handle:close()
    end
  end
  error("md2pdf citation validation aborted", 0)
end

if not stage_dir or stage_dir == "" then
  abort("the citation validator requires a trusted staging environment")
end

function Pandoc(document)
  local processed, message = io.open(stage_dir .. "/citations-processed", "wb")
  if not processed then
    abort("cannot record citation processing: " .. tostring(message))
  end
  processed:close()

  return document
end
