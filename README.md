# comment-navigator

A simple nvim plugin to jump between (special) comments.

## Preview

![commentnavigator](https://github.com/Thomas485/comment-navigator/assets/1681511/bfeb5a64-145d-4df0-98c9-3196d646dc0c)

## Setup
This is my current setup:
```lua
local comment_navigator = require('comment_navigator')

local comment_filetypes = {
    {"*.{odin,c,cc,cpp,cxx}", comment_navigator.regex.c},
    {"*.lua", comment_navigator.regex.lua},
    {"*.py", comment_navigator.regex.python}
}

for _, cf in ipairs(comment_filetypes) do
    local cn = comment_navigator.setup({
        regex = cf[2]
    })
    vim.api.nvim_create_autocmd("BufEnter", {
        pattern = cf[1],
        callback = function()
            vim.keymap.set('n', '<space>c', cn.open, { noremap = true, silent = true })
        end
    })
end
```

## Configuration

You can find all options [here](https://github.com/Thomas485/comment-navigator/blob/main/lua/comment_navigator/init.lua#L51-L59)

### predefined comment styles

You can find a list [here](https://github.com/Thomas485/comment-navigator/blob/main/lua/comment_navigator/init.lua#L119-L124)

### custom comments

Just use your own (lua)regex.

The first capture is the indentation, the second the text to show.
