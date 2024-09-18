local function is_complete_setup(_)
    return vim.g.use_complete_setup
end

return {
    -- Ollama GPT
    {
        'David-Kunz/gen.nvim',
        cond = is_complete_setup(),
        opts = {
            model = 'deepseek-coder-v2:latest', -- The default model to use.
            host = 'localhost', -- The host running the Ollama service.
            port = '11434', -- The port on which the Ollama service is listening.
            quit_map = 'q', -- set keymap for close the response window
            retry_map = '<c-r>', -- set keymap to re-send the current prompt
            init = function(_)
                pcall(io.popen, 'ollama serve > /dev/null 2>&1 &')
            end,
            -- Function to initialize Ollama
            command = function(options)
                local body = { model = options.model, stream = true }
                return 'curl --silent --no-buffer -X POST http://' .. options.host .. ':' .. options.port .. '/api/chat -d $body'
            end,
            -- The command for the Ollama service. You can use placeholders $prompt, $model and $body (shellescaped).
            -- This can also be a command string.
            -- The executed command must return a JSON object with { response, context }
            -- (context property is optional).
            -- list_models = '<omitted lua function>', -- Retrieves a list of model names
            display_mode = 'float', -- The display mode. Can be "float" or "split" or "horizontal-split".
            show_prompt = false, -- Shows the prompt submitted to Ollama.
            show_model = true, -- Displays which model you are using at the beginning of your chat session.
            no_auto_close = false, -- Never closes the window automatically.
            debug = false, -- Prints errors and the command which is run.
        },
        init = function()
            -- Ollama gen.nvim
            vim.keymap.set({ 'n', 'v' }, '<leader>`', ':Gen<CR>')
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
                width = 120, -- width of the Zen window
                height = 1, -- height of the Zen window
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
                    laststatus = 0, -- turn off the statusline in zen mode
                },
                gitsigns = { enabled = true },
                twilight = { enabled = true },
                tmux = { enabled = false },
                todo = { enabled = false },
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
        build = function()
            vim.fn['mkdp#util#install']()
        end,
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
            --             timeout = 3000,
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
}
