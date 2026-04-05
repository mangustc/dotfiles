local M = {}

M.config = {
  endpoint   = "http://localhost:1234/api/v1/chat",
  api_token  = vim.env.LM_API_TOKEN or "",
  model      = "", -- leave empty to use whatever is loaded in LM Studio
  win_width  = 0.8,
  win_height = 0.8,
}

---@param opts table
function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

-- ─── Prompts ────────────────────────────────────────────────────────────────

local PROMPTS = {
  {
    name = "Generate",
    prompt =
    "# Prompt\n\n## Context Buffers\n\nThe following buffers are provided as read-only context. Do not modify or repeat them in your response:\n\n$text\n\n## Task\n\nGenerate content based on the context above. Only output what is explicitly requested. Do not add explanations, caveats, or content beyond the scope of the request.\n\nRequest: $input",
    replace = true,
  },
  {
    name = "Chat",
    prompt =
    "# Prompt\n\n## Context Buffers\n\nThe following buffers are provided as read-only context. Do not modify or repeat them in your response:\n\n$text\n\n## Task\n\nRespond to the following message using the context above where relevant. If the context is not relevant, rely on your general knowledge. Be concise and direct.\n\n$input",
  },
  {
    name = "Summarize",
    prompt =
    "# Prompt\n\n## Context Buffers\n\nThe following buffers are provided as read-only context:\n\n$text\n\n## Task\n\nSummarize the content below. If the selection is empty, summarize the buffers instead. Output only the summary: no introductions, meta-commentary, or repetition of the original text.\n\nSelection:\n```\n$selection\n```",
  },
  {
    name = "Ask",
    prompt =
    "# Prompt\n\n## Context Buffers\n\nThe following buffers are provided as read-only context:\n\n$text\n\n## Task\n\nUsing the selection below as the primary subject (or the buffers if the selection is empty), answer the question that follows. Limit your response to what is answerable from the provided context. If the answer cannot be determined from the context, say so explicitly.\n\nSelection:\n```\n$selection\n```\n\nQuestion: $input",
  },
  {
    name = "Change",
    prompt =
    "# Prompt\n\n## Context Buffers\n\nThe following buffers are provided as read-only context. Do not modify or repeat them:\n\n$text\n\n## Task\n\nRewrite the text below according to the instruction provided. \n\nRules you must follow:\n- Output only the rewritten text, nothing else\n- Do not wrap the output in quotes or code blocks\n- Do not add explanations, comments, or any text outside the rewrite\n- Do not change content that the instruction does not address\n\nInstruction: $input\n\nText to change:\n$selection",
    replace = true,
  },
  {
    name = "Change Code",
    prompt =
    "# Prompt\n\n## Context Buffers\n\nThe following buffers are provided as read-only context. Do not modify or repeat them:\n\n$text\n\n## Task\n\nModify the code below according to the instruction provided.\n\nRules you must follow:\n- Output only the modified code, nothing else\n- Preserve all code that is unaffected by the instruction exactly as-is\n- Do not wrap the output in markdown code fences or quotes\n- Do not include explanations, comments, or any non-code text\n- Do not invent changes beyond what the instruction specifies\n\nInstruction: $input\n\nCode to modify:\n```\n$selection\n```",
    replace = true,
  },
}

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function get_visual_selection(source_buf, sel_start, sel_end)
  if not sel_start or sel_start == 0 then return "" end
  local start_pos = vim.api.nvim_buf_get_mark(source_buf, "<")
  local end_pos   = vim.api.nvim_buf_get_mark(source_buf, ">")
  local lines     = vim.api.nvim_buf_get_lines(source_buf, sel_start - 1, sel_end, false)
  if #lines == 0 then return "" end
  if end_pos[2] < 2147483647 then
    lines[#lines] = lines[#lines]:sub(1, end_pos[2] + 1)
  end
  lines[1] = lines[1]:sub(start_pos[2] + 1)
  return table.concat(lines, "\n")
end

local function buffer_lines(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return nil end
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then name = "[No Name]" end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return { ("### Buffer: %s"):format(name), "```", table.concat(lines, "\n"), "```" }
end

local function build_text(source_buf, mode)
  if mode == "none" then return "" end
  local parts = {}
  if mode == "current" then
    local ctx = buffer_lines(source_buf or vim.api.nvim_get_current_buf())
    if ctx then vim.list_extend(parts, ctx) end
  elseif mode == "all" then
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buflisted then
        local ctx = buffer_lines(bufnr)
        if ctx then
          vim.list_extend(parts, ctx); table.insert(parts, "")
        end
      end
    end
  end
  return table.concat(parts, "\n")
end

local function get_model()
  if M.config.model and M.config.model ~= "" then return M.config.model end
  local base = M.config.endpoint:match("^(https?://[^/]+)")
  if not base then return "unknown" end
  local ok, result = pcall(function()
    local handle = io.popen(
      string.format('curl -s -H "Authorization: Bearer %s" %s/v1/models', M.config.api_token, base)
    )
    if not handle then return nil end
    local body = handle:read("*a"); handle:close()
    local decoded = vim.fn.json_decode(body)
    if decoded and decoded.data and decoded.data[1] then return decoded.data[1].id end
    return nil
  end)
  if ok and result then return result end
  return "loaded-model"
end

local function open_float(title, width, height)
  local ui              = vim.api.nvim_list_uis()[1]
  local W               = math.floor((ui and ui.width or 120) * (width or M.config.win_width))
  local H               = math.floor((ui and ui.height or 40) * (height or M.config.win_height))
  local row             = math.floor(((ui and ui.height or 40) - H) / 2)
  local col             = math.floor(((ui and ui.width or 120) - W) / 2)
  local buf             = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local win             = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = W,
    height = H,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " " .. (title or "LM Studio") .. " ",
    title_pos = "center",
  })
  vim.wo[win].wrap      = true

  local function close() pcall(vim.api.nvim_win_close, win, true) end
  local function map(key, fn)
    vim.keymap.set("n", key, fn, { buffer = buf, nowait = true, silent = true })
  end

  map("q", close)
  map("<Esc>", close)

  return buf, win
end

local function set_lines(buf, lines)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

local CTX_MODES     = { "none", "current", "all" }
local ctx_mode      = "current"
local online_search = true
local function picker_lines(selected)
  local lines = {}
  for i, p in ipairs(PROMPTS) do
    local prefix = (i == selected) and "▶ " or "  "
    table.insert(lines, prefix .. p.name)
  end
  return lines
end

local function picker_title()
  return string.format(" Gen  [c]ontext:%s  [s]earch:%s ",
    ctx_mode, online_search and "on" or "off")
end

local function open_picker(on_select)
  ctx_mode       = "current"
  online_search  = true
  local buf, win = open_float(picker_title(), M.config.win_width, M.config.win_height)

  local hl_ns    = vim.api.nvim_create_namespace("gen_picker_sel")
  vim.api.nvim_set_hl(0, "GenPickerSel", { reverse = true })

  local function picker_lines_plain()
    local lines = {}
    for _, p in ipairs(PROMPTS) do
      table.insert(lines, " " .. p.name)
    end
    return lines
  end

  local function redraw()
    set_lines(buf, picker_lines_plain())
    local cursor_row = vim.api.nvim_win_get_cursor(win)[1]
    local selected = math.max(1, math.min(cursor_row, #PROMPTS))
    vim.api.nvim_buf_clear_namespace(buf, hl_ns, 0, -1)
    vim.api.nvim_buf_add_highlight(buf, hl_ns, "GenPickerSel", selected - 1, 0, -1)
    vim.api.nvim_win_set_cursor(win, { selected, 0 })
    vim.api.nvim_win_set_config(win, { title = picker_title(), title_pos = "center" })
  end

  local function close() pcall(vim.api.nvim_win_close, win, true) end
  local function map(key, fn)
    vim.keymap.set("n", key, fn, { buffer = buf, nowait = true, silent = true })
  end

  map("q", close)
  map("<Esc>", close)

  map("c", function()
    local idx = 1
    for i, v in ipairs(CTX_MODES) do
      if v == ctx_mode then
        idx = i; break
      end
    end
    ctx_mode = CTX_MODES[(idx % #CTX_MODES) + 1]
    redraw()
  end)

  map("s", function()
    online_search = not online_search; redraw()
  end)

  map("<CR>", function()
    local cursor_row = vim.api.nvim_win_get_cursor(win)[1]
    local selected = math.max(1, math.min(cursor_row, #PROMPTS))
    local chosen = PROMPTS[selected]
    close()
    on_select(chosen)
  end)

  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = redraw,
  })

  redraw()
end

-- ─── Send ────────────────────────────────────────────────────────────────────

local function needs_input(tmpl) return tmpl:find("%$input") ~= nil end

local function build_full_prompt(tmpl, user_input, text, filetype, selection)
  return (tmpl
    :gsub("%$input", user_input or "")
    :gsub("%$text", text or "")
    :gsub("%$filetype", filetype or "")
    :gsub("%$selection", selection or ""))
end

local function do_replace(source_buf, sel_start, sel_end, response, extract_pat, filetype)
  local text = response
  if extract_pat then
    local pat = extract_pat:gsub("%$filetype", filetype or "")
    text = response:match(pat) or response
  end
  vim.api.nvim_buf_set_lines(source_buf, sel_start - 1, sel_end, false, vim.split(text, "\n"))
end

local function send(prompt_def, user_input, source_buf, sel_start, sel_end)
  local filetype = vim.bo[source_buf].filetype or ""
  local sel_text = get_visual_selection(source_buf, sel_start, sel_end)
  local buf_text = build_text(source_buf, ctx_mode)

  local full_prompt = build_full_prompt(prompt_def.prompt, user_input, buf_text, filetype, sel_text)
  local testbuf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_lines(testbuf, 0, -1, false, vim.split(full_prompt, "\n"))
  vim.api.nvim_set_current_buf(testbuf)

  local model = get_model()
  local out_buf, out_win = open_float(model)
  vim.bo[out_buf].filetype = "markdown"
  set_lines(out_buf, { "*Waiting for response…*" })

  local payload_tbl = { model = model, input = full_prompt }
  if online_search then
    payload_tbl.integrations = { { type = "plugin", id = "mcp/online-search" } }
  end

  local auth_header = M.config.api_token ~= ""
      and string.format('-H "Authorization: Bearer %s"', M.config.api_token) or ""

  local cmd = string.format(
    "curl -s -X POST %s -H 'Content-Type: application/json' -d %s %s",
    M.config.endpoint, vim.fn.shellescape(vim.fn.json_encode(payload_tbl)), auth_header
  )

  local stdout_chunks, stderr_chunks = {}, {}
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data) if data then vim.list_extend(stdout_chunks, data) end end,
    on_stderr = function(_, data) if data then vim.list_extend(stderr_chunks, data) end end,
    on_exit = function(_, code)
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(out_buf) then return end

        if code ~= 0 then
          set_lines(out_buf, { "# Error", "", ("curl exited with code %d"):format(code),
            "", "```", table.concat(stderr_chunks, "\n"), "```" })
          return
        end

        local raw = table.concat(stdout_chunks, "\n")
        local ok, decoded = pcall(vim.fn.json_decode, raw)
        if not ok or not decoded then
          set_lines(out_buf, { "# Parse Error", "", "Could not decode JSON.",
            "", "```", raw, "```" })
          return
        end
        if decoded.error then
          set_lines(out_buf, { "# API Error", "", tostring(decoded.error.message or decoded.error) })
          return
        end

        local parts = {}
        for _, item in ipairs(decoded.output or {}) do
          if item.type == "message" then table.insert(parts, item.content or "") end
        end
        local response_text = table.concat(parts, "\n")

        if prompt_def.replace and sel_start and sel_start > 0 then
          pcall(do_replace, source_buf, sel_start, sel_end, response_text, prompt_def.extract, filetype)
        end

        set_lines(out_buf, vim.split(response_text .. "\n", "\n"))
        if vim.api.nvim_win_is_valid(out_win) then
          vim.api.nvim_win_set_cursor(out_win, { 1, 0 })
        end
      end)
    end,
  })
end

function M.gen(line1, line2)
  local source_buf = vim.api.nvim_get_current_buf()
  local sel_start  = line1 or vim.api.nvim_buf_get_mark(source_buf, "<")[1]
  local sel_end    = line2 or vim.api.nvim_buf_get_mark(source_buf, ">")[1]

  open_picker(function(prompt_def)
    if needs_input(prompt_def.prompt) then
      vim.ui.input({ prompt = prompt_def.name .. ": " }, function(user_input)
        if user_input == nil then return end
        send(prompt_def, user_input, source_buf, sel_start, sel_end)
      end)
    else
      send(prompt_def, "", source_buf, sel_start, sel_end)
    end
  end)
end

vim.api.nvim_create_user_command("Gen", function(opts)
  M.gen(opts.range > 0 and opts.line1 or nil,
    opts.range > 0 and opts.line2 or nil)
end, { desc = "Open LM Studio prompt picker", range = true })

return M
