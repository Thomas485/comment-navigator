local plenary = require("plenary")

local M = {}

local function filter_comments(settings, content)
    local cursor_position = vim.api.nvim_win_get_cursor(0)
    local new_cursor = {1,0}

    local numbers, values = {}, {}
    local indentations = {}

    for i, v in ipairs(content) do
        local indent, line = string.match(v, settings.regex)
        if line then
            if settings.keep_indent then
                numbers[#numbers+1] = i
                values[#values+1] = indent .. line
                table.insert(indentations, #indent)
            else
                numbers[#numbers+1] = i
                values[#values+1] = line
            end
        end

        -- set the cursor position to the comment under the cursor
        -- or to the previous comment if not on a comment directly.
        if new_cursor[1] == 1 then
            if i == cursor_position[1] then
                new_cursor = {math.max(#numbers,1), indentations[#indentations] or 0}
            end
        end
    end

    -- strip down indentation
    if settings.keep_indent then
        local min_indentation = math.huge
        for _, indent in ipairs(indentations) do
            min_indentation = min_indentation < indent and min_indentation or indent
        end
        for i = 1, #values, 1 do
            values[i] = string.sub(values[i], min_indentation+1)
        end
    end
    return numbers, values, new_cursor
end

function M.setup(options)
    -- create a new module to support multiple file types
    local module = {}

    -- default settings
    module.settings = {
        regex = M.regex.c, -- the regex used to extract the comments (c-style default)
        line_numbers = true, -- show the line numbers in the list
        width = 100, -- width of the window
        height = 50, -- height of the window
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" }, -- the borders, nil means no border
        keep_indent = true, -- preserve the indentation of the file (shows the values in a hierarchical manner)
    }

    module.settings = vim.tbl_deep_extend("force", module.settings, options)

    -- main entry point, opens the popup window
    function module.open()
        local settings = module.settings

        local content_buffer = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
        local line_numbers, content, cursor_position = filter_comments(settings, content_buffer)

        -- FIXME: this is a hotfix
        -- removes an empty line at the end of the buffer
        if content[#content] == "" then
            table.remove(content, #content)
        end

        -- TODO: avoid module to be able to open multiple popups at the same time
        module.state = line_numbers

        -- create the buffer for the popup window
        local buffer = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buffer, -2, -1, true, content)
        vim.api.nvim_buf_set_option(buffer, 'readonly', true)
        vim.api.nvim_buf_set_keymap(buffer, "n", "<Enter>", "", {
            callback = function()
                module.go(buffer)
            end
        })
        vim.api.nvim_buf_set_keymap(buffer, "n", "<Esc>",
            "<cmd>lua vim.api.nvim_buf_delete(" .. buffer .. ", {})<CR>", {})

        local win, _ = plenary.popup.create(buffer, {
            title = "comment-navigator",
            minwidth = settings.width,
            minheight = settings.height,
            maxheight = settings.height,
            maxwidth = settings.width,
            borderchars = settings.borderchars,
        })

        if settings.line_numbers then
            vim.api.nvim_win_set_option(win, "number", true)
        end

        vim.api.nvim_win_set_cursor(win, cursor_position)
    end

    -- navigates to the comment under the cursor
    function module.go(buffer)
        local idx = vim.api.nvim__buf_stats(buffer).current_lnum
        vim.api.nvim_buf_delete(buffer, {})

        local line = module.state[idx]
        vim.api.nvim_win_set_cursor(0,{line,0})
    end

    return module
end

M.regex = {
    c = "(%s*)///%s*(.*)%s*",        -- /// comment
    lua = "(%s*)%-%-%-%s*(.*)%s*",   -- --- comment
    python = "(%s*)#:%s*(.*)%s*",    -- #: comment (not ## because of autoformatters…)
    erb =  "(%s*)<%%%s?# *(.*) *%%>" -- <%# comment %>
}

return M
