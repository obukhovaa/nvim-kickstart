local function is_complete_setup(_)
    return vim.g.use_complete_setup
end

-- Function to check if a model name contains any whitelisted pattern
local function is_white_listed(model_list, id)
    if next(model_list) == nil then
        return true
    end
    for _, pattern in ipairs(model_list) do
        if id:match(pattern) then
            return true
        end
    end
    return false
end

return {
    {
        'LunarVim/bigfile.nvim',
    },
    -- AI code agent: https://aider.chat
    {
        'joshuavial/aider.nvim',
        opts = {
            auto_manage_context = true, -- automatically manage buffer context
            default_bindings = true, -- use default <leader>A keybindings
            debug = false,
        },
    },
    -- Ollama/OpenAI GPT
    {
        'obukhovaa/gen.nvim',
        branch = 'fix/choices-npe-open-web-ui',
        cond = is_complete_setup(),
        config = function()
            -- default to local setup
            vim.g.gen_remote_toggle_on = true
            -- default to openai when remtoe mode activated, could be changed to `ollama`
            vim.g.gen_remote_type = 'openai'
            -- adjust to set your API key
            local get_api_token = function()
                local api_key = os.getenv 'OPEN_AI_PIANO_TOKEN' or ''
                if api_key == '' then
                    print "Can't find OPEN AI token, set OPEN_AI_PIANO_TOKEN env variable"
                end
                return api_key
            end
            local gen_local_opts = {
                model = 'deepseek-coder-v2:latest', -- The default model to use, will be used for both local and remote Ollama service
                model_options = {
                    -- allowed_openai_params = { 'logprobs' },
                    -- logprobs = false,
                },
                host = 'localhost', -- The host running the Ollama service.
                port = '11434', -- The port on which the Ollama service is listening.
                quit_map = 'q', -- Set keymap for close the response window
                retry_map = '<c-r>', -- Set keymap to re-send the current prompt
                init = function(_)
                    pcall(io.popen, 'ollama serve > /dev/null 2>&1 &')
                end,
                command = function(options)
                    local req = 'curl --silent --no-buffer -X POST http://' .. options.host .. ':' .. options.port .. '/api/chat -d $body'
                    return req
                end,
                display_mode = 'vertical-split', -- The display mode. Can be "float" or "vertical-split" or "horizontal-split".
                show_prompt = true, -- Shows the prompt submitted to Ollama.
                show_model = true, -- Displays which model you are using at the beginning of your chat session.
                show_usage = true, -- Shows token usage at the end
                no_auto_close = true, -- Never closes the window automatically.
                debug = false, -- Prints errors and the command which is run.
                openai_path_prefix = '', -- If remote supports multiple backends, can be managed via paths.
                ollama_path_prefix = '',
                result_filetype = 'markdown', -- Configure filetype of the result buffer
            }
            local gen_remote_override_opts = {
                model = 'claude-opus-4-6', -- 'us.anthropic.claude-opus-4-20250514-v1:0',
                host = 'litellm.de-prod.cxense.com',
                port = '443',
                openai_path_prefix = '/v1',
                ollama_path_prefix = '/ollama',
                command = function(options)
                    local path
                    if vim.g.gen_remote_type == 'openai' then
                        path = options.openai_path_prefix .. '/chat/completions'
                    else
                        path = options.ollama_path_prefix .. '/api/chat'
                    end
                    local req = 'curl --silent --no-buffer -X POST https://'
                        .. options.host
                        .. ':'
                        .. options.port
                        .. path
                        .. ' -d $body'
                        .. " -H 'Content-Type: application/json'"
                        .. " -H 'Authorization: Bearer "
                        .. get_api_token()
                        .. "'"
                    if gen_local_opts.debug then
                        vim.api.nvim_echo({ { 'GenNVIM: ', 'InfoMsg' }, { vim.inspect(req) } }, true, {})
                    end
                    return req
                end,
            }
            local prepare_opts = function()
                local new_opts = {}
                for k, v in pairs(gen_local_opts) do
                    if vim.g.gen_remote_toggle_on and gen_remote_override_opts[k] ~= nil then
                        -- assuming that remote and local ollama has the same model
                        if vim.g.gen_remote_type == 'ollama' and k == 'model' then
                            new_opts[k] = gen_local_opts.model
                        else
                            new_opts[k] = gen_remote_override_opts[k]
                        end
                    else
                        new_opts[k] = v
                    end
                end
                new_opts.list_models = function(options)
                    local model_white_list = {
                        'o5$',
                        '^gpt%-5',
                        -- 'gpt%-4o%-audio.*2025',
                        -- 'high/1536.*gpt%-image%-1',
                        -- 'medium/1536.*gpt%-image%-1',
                        '^claude%-opus%-4%-6$',
                        '^claude%-sonnet%-4%-5$',
                        'gemini%-3',
                    }
                    local models_path = '/api/tags'
                    local auth = ''
                    if vim.g.gen_remote_toggle_on then
                        auth = " -H 'Authorization: Bearer " .. get_api_token() .. "'"
                        if vim.g.gen_remote_type == 'openai' then
                            models_path = options.openai_path_prefix .. '/models'
                        else
                            models_path = options.ollama_path_prefix .. '/api/tags'
                        end
                    end
                    local schema
                    if options.port == '443' then
                        schema = 'https://'
                    else
                        schema = 'http://'
                    end
                    local curl = 'curl --silent --no-buffer ' .. schema .. options.host .. ':' .. options.port .. models_path .. auth
                    local response = vim.fn.systemlist(curl)
                    local list = vim.fn.json_decode(response)
                    if gen_local_opts.debug then
                        vim.api.nvim_echo({ { 'GenNVIM: ', 'InfoMsg' }, { curl } }, true, {})
                        vim.api.nvim_echo({ { 'GenNVIM: ', 'InfoMsg' }, { vim.inspect(list) } }, true, {})
                    end
                    local models = {}
                    if list ~= nil and list.detail ~= nil and string.find(list.detail, '401 Unauthorized') then
                        vim.api.nvim_echo({ { 'GenNVIM: ', 'ErrorMsg' }, { 'Unauthorized: OPEN_AI_PIANO_TOKEN is invalid' } }, true, {})
                        return models
                    end
                    if vim.g.gen_remote_toggle_on and vim.g.gen_remote_type == 'openai' then
                        -- Filter models based on the whitelist
                        for key, _ in pairs(list.data) do
                            local modelName = list.data[key].id
                            if is_white_listed(model_white_list, modelName) then
                                table.insert(models, modelName)
                            end
                        end
                        table.sort(models)
                        -- keep 12 most recent models
                        local size = #models
                        while size > 12 do
                            table.remove(models, 1)
                            size = size - 1
                        end
                    else
                        for key, _ in pairs(list.models) do
                            table.insert(models, list.models[key].name)
                        end
                        table.sort(models)
                    end
                    return models
                end
                return new_opts
            end

            -- :GenRemoteToggle to select between local and remote server modes
            vim.api.nvim_create_user_command('GenRemoteToggle', function()
                vim.g.gen_remote_toggle_on = not vim.g.gen_remote_toggle_on
                if vim.g.gen_remote_toggle_on then
                    print(string.format('Using remote gpt from %s', vim.g.gen_remote_type))
                else
                    print 'Using local ollama GPT API'
                end
                require('gen').setup(prepare_opts())
            end, {})

            -- :GenRemoteTypeSwap to select between openai and ollama remote models
            vim.api.nvim_create_user_command('GenRemoteTypeSwap', function()
                if vim.g.gen_remote_type == 'openai' or vim.g.gen_remote_type == nil then
                    vim.g.gen_remote_type = 'ollama'
                else
                    vim.g.gen_remote_type = 'openai'
                end
                print(string.format('Using %s remote api', vim.g.gen_remote_type))
                require('gen').setup(prepare_opts())
            end, {})

            require('gen').setup(prepare_opts())
        end,
        init = function()
            -- Remap to run GPT prompt
            vim.keymap.set({ 'n', 'v' }, '<leader>`', ':Gen<CR>')
            -- Remap to choose GPR model
            vim.keymap.set({ 'n' }, '<leader>~', require('gen').select_model, { desc = 'Select LLM to use' })
        end,
    },

    {
        'obukhovaa/gotests-vim', -- generates go test templates
        cond = is_complete_setup(),
    },
    {
        'folke/trouble.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        opts = {
            -- your configuration comes here
            -- or leave it empty to use the default settings
            -- refer to the configuration section below
        },
    },
    {
        'folke/zen-mode.nvim',
        opts = {
            window = {
                backdrop = 1, -- shade the backdrop of the Zen window. Set to 1 to keep the same as Normal
                -- height and width can be:
                -- * an absolute number of cells when > 1
                -- * a percentage of the width / height of the editor when <= 1
                -- * a function that returns the width or the height
                width = 125, -- width of the Zen window
                height = 0.90, -- height of the Zen window
                -- by default, no options are changed for the Zen window
                -- uncomment any of the options below, or add other vim.wo options you want to apply
                options = {
                    -- signcolumn = 'no', -- disable signcolumn
                    -- number = false, -- disable number column
                    -- relativenumber = false, -- disable relative numbers
                    -- cursorline = false, -- disable cursorline
                    -- cursorcolumn = false, -- disable cursor column
                    -- foldcolumn = "0", -- disable fold column
                    -- list = false, -- disable whitespace characters
                },
            },
            plugins = {
                options = {
                    enabled = true,
                    ruler = false, -- disables the ruler text in the cmd line area
                    showcmd = false, -- disables the command in the last line of the screen
                    laststatus = 0, -- turn off the statusline in zen mode, 3 - to enable
                },
                gitsigns = { enabled = false },
                twilight = { enabled = true },
                tmux = { enabled = false },
                todo = { enabled = false },
                undotree = {
                    enabled = true,
                    position = 'left',
                    width_relative = 0.2,
                },
            },
            -- callback where you can add custom code when the Zen window opens
            on_open = function(win)
                vim.api.nvim_command ':!tmux set-option status off'
            end,
            -- callback where you can add custom code when the Zen window closes
            on_close = function()
                vim.api.nvim_command ':!tmux set-option status on'
            end,
        },
        init = function()
            vim.keymap.set('n', '<leader><Home>', '<Cmd>ZenMode<CR>', { desc = 'Toggle zenmode' })
        end,
    },
    -- Markdown files preview
    {
        'iamcco/markdown-preview.nvim',
        cond = is_complete_setup(),
        cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
        ft = { 'markdown' },
        build = ':call mkdp#util#install()',
    },
    {
        'MeanderingProgrammer/render-markdown.nvim',
        -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' }, -- if you use the mini.nvim suite
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' }, -- if you use standalone mini plugins
        -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
        opts = {},
    },
    -- replace cmdline
    {
        'folke/noice.nvim',
        event = 'VeryLazy',
        opts = {
            -- add any options here
        },
        dependencies = {
            -- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
            'MunifTanjim/nui.nvim',
            -- OPTIONAL:
            --   `nvim-notify` is only needed, if you want to use the notification view.
            --   If not available, we use `mini` as the fallback
            -- {
            --     'rcarriga/nvim-notify',
            --     config = function()
            --         require('notify').setup {
            --             -- stages = "fade_in_slide_out",
            --             stages = 'static',
            --             render = 'compact',
            --             background_colour = 'FloatShadow',
            --             -- timeout = 3000,
            --             merge_duplicates = true,
            --             fps = 60,
            --             top_down = false,
            --         }
            --         vim.notify = require 'notify'
            --     end,
            -- },
        },
        config = function()
            require('noice').setup {
                lsp = {
                    -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
                    override = {
                        ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
                        ['vim.lsp.util.stylize_markdown'] = true,
                        ['cmp.entry.get_documentation'] = true, -- requires hrsh7th/nvim-cmp
                    },
                },
                -- you can enable a preset for easier configuration
                presets = {
                    bottom_search = true, -- use a classic bottom cmdline for search
                    command_palette = false, -- position the cmdline and popupmenu together
                    long_message_to_split = true, -- long messages will be sent to a split
                    inc_rename = false, -- enables an input dialog for inc-rename.nvim
                    lsp_doc_border = false, -- add a border to hover docs and signature help
                },
            }
        end,
    },
    {
        'kylechui/nvim-surround',
        version = '*', -- Use for stability; omit to use `main` branch for the latest features
        event = 'VeryLazy',
        config = function()
            require('nvim-surround').setup {
                -- Configuration here, or leave empty to use defaults
            }
        end,
    },
    {
        -- integration with ssh, docker and other remote providers
        'miversen33/netman.nvim',
        cond = is_complete_setup(),
        dependencies = {
            'nvim-neo-tree/neo-tree.nvim',
        },
    },
    {
        'mrbjarksen/neo-tree-diagnostics.nvim',
        cond = is_complete_setup(),
        dependencies = {
            'nvim-neo-tree/neo-tree.nvim',
        },
    },
    {
        'mbbill/undotree',
        config = function()
            vim.g.undotree_WindowLayout = 3
            vim.g.undotree_ShortIndicators = 1
            vim.g.undotree_SplitWidth = 40
            vim.g.undotree_HelpLine = 0
            vim.g.undotree_CursorLine = 1
        end,
    },

    {
        'akinsho/toggleterm.nvim',
        version = '*',
        opts = {
            open_mapping = [[<c-\>]],
        },
    },

    {
        'folke/twilight.nvim',
        opts = {
            dimming = {
                alpha = 0.25, -- amount of dimming
                -- we try to get the foreground from the highlight groups or fallback color
                color = { 'Normal', '#ffffff' },
                term_bg = '#000000', -- if guibg=NONE, this will be used to calculate text color
                inactive = false, -- when true, other windows will be fully dimmed (unless they contain the same buffer)
            },
            context = 10, -- amount of lines we will try to show around the current line
            treesitter = true, -- use treesitter when available for the filetype
            -- treesitter is used to automatically expand the visible text,
            -- but you can further control the types of nodes that should always be fully expanded
            expand = { -- for treesitter, we we always try to expand to the top-most ancestor with these types
                'function',
                'method',
                'table',
                'if_statement',
            },
            exclude = {}, -- exclude these filetypes
        },
    },

    {
        'shellRaining/hlchunk.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        config = function()
            require('hlchunk').setup {
                chunk = {
                    enable = true,
                    use_treesitter = false,
                    -- animation related
                    style = {
                        { fg = '#c678dd' },
                        { fg = '#e06c75' },
                    },
                    delay = 0,
                },
                indent = {
                    -- instead of 'lukas-reineke/indent-blankline.nvim',
                    -- but I like latter more
                    enable = false,
                },
                line_num = {
                    enable = false,
                    style = '#c678dd',
                },
            }
        end,
    },
    {
        -- add indentation guides even on blank lines
        'lukas-reineke/indent-blankline.nvim',
        main = 'ibl',
        opts = {
            enabled = true,
            scope = {
                enabled = false,
            },
            whitespace = {
                highlight = 'iblwhitespace',
                remove_blankline_trail = true,
            },
            indent = {
                char = { '│' },
            },
        },
    },

    {
        -- theme inspired by atom
        -- 'navarasu/onedark.nvim',
        -- 	'Mofiqul/dracula.nvim',
        -- 	'xiantang/darcula-dark.nvim',
        'olimorris/onedarkpro.nvim',
        priority = 1000,
        config = function()
            require('onedarkpro').setup {
                colors = {
                    dark = {
                        cursorline = '#2d313b',
                    },
                    light = {
                        cursorline = '#f0f0f0',
                    },
                },
                options = {
                    cursorline = true,
                },
            }
            vim.cmd.colorscheme 'onedark'

            -- Semantic token highlights for Go
            vim.api.nvim_set_hl(0, '@lsp.type.namespace', { link = 'Include' })
            vim.api.nvim_set_hl(0, '@lsp.type.type', { link = 'Type' })
            vim.api.nvim_set_hl(0, '@lsp.type.class', { link = 'Structure' })
            vim.api.nvim_set_hl(0, '@lsp.type.enum', { link = 'Type' })
            vim.api.nvim_set_hl(0, '@lsp.type.interface', { link = 'Structure' })
            vim.api.nvim_set_hl(0, '@lsp.type.struct', { link = 'Structure' })
            vim.api.nvim_set_hl(0, '@lsp.type.parameter', { link = 'Identifier' })
            vim.api.nvim_set_hl(0, '@lsp.type.variable', { link = 'Variable' })
            vim.api.nvim_set_hl(0, '@lsp.type.property', { link = 'Property' })
            vim.api.nvim_set_hl(0, '@lsp.type.enumMember', { link = 'Constant' })
            vim.api.nvim_set_hl(0, '@lsp.type.function', { link = 'Function' })
            vim.api.nvim_set_hl(0, '@lsp.type.method', { link = 'Function' })
            vim.api.nvim_set_hl(0, '@lsp.type.macro', { link = 'Macro' })
            vim.api.nvim_set_hl(0, '@lsp.type.decorator', { link = 'Special' })

            vim.api.nvim_create_user_command('ToggleTheme', function()
                if vim.o.background == 'dark' then
                    vim.cmd 'colorscheme onelight'
                else
                    vim.cmd 'colorscheme onedark'
                end
            end, {})

            vim.keymap.set('n', '<leader><End>', '<Cmd>ToggleTheme<CR>', { desc = 'Toggle theme' })
        end,
    },
    {
        -- set lualine as statusline
        'nvim-lualine/lualine.nvim',
        opts = {
            options = {
                icons_enabled = true,
                theme = 'auto',
                component_separators = '|',
                section_separators = '',
            },
        },
    },
    {
        'ruifm/gitlinker.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        init = function()
            vim.api.nvim_set_keymap('n', '<leader>gY', '<cmd>lua require"gitlinker".get_repo_url()<cr>', { silent = true, desc = '[g]it repo url [Y]ank' })
            vim.api.nvim_set_keymap(
                'n',
                '<leader>gB',
                '<cmd>lua require"gitlinker".get_repo_url({action_callback = require"gitlinker.actions".open_in_browser})<cr>',
                { silent = true, desc = '[g]o to git repo in [B]rowser' }
            )
            vim.api.nvim_set_keymap(
                'n',
                '<leader>gbb',
                '<cmd>lua require"gitlinker".get_buf_range_url("n", {action_callback = require"gitlinker.actions".open_in_browser})<cr>',
                { silent = true, desc = '[g]o to git line in [2b]rowser' }
            )
            vim.api.nvim_set_keymap('n', '<leader>gy', '<cmd>lua require"gitlinker".get_buf_range_url()<cr>', { silent = true, desc = '[g]it line url [Y]ank' })
            vim.api.nvim_set_keymap(
                'v',
                '<leader>gy',
                '<cmd>lua require"gitlinker".get_buf_range_url("v")<cr>',
                { silent = true, desc = '[g]it lines url [Y]ank' }
            )
            vim.api.nvim_set_keymap(
                'v',
                '<leader>gb',
                '<cmd>lua require"gitlinker".get_buf_range_url("v", {action_callback = require"gitlinker.actions".open_in_browser})<cr>',
                { desc = '[g]o to git lines in [b]rowser' }
            )
        end,
    },
    {
        'wfxr/minimap.vim',
        init = function()
            vim.g.minimap_width = 10
            vim.g.minimap_auto_start = 0
            vim.g.minimap_auto_start_win_enter = 0
            vim.g.minimap_highlight_search = 1
            vim.g.minimap_git_colors = 1
        end,
    },
}
