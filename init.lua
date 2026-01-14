vim.g.use_complete_setup = vim.env.USE_COMPLETE_NVIM_SETUP == 'true'

vim.wo.relativenumber = true
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

-- hande 39_Highlight_Matching_Pair slowness on long lines
vim.g.matchparen_timeout = 20
vim.g.matchparen_insert_timeout = 20

local set = vim.opt
set.tabstop = 4
set.softtabstop = 4
set.shiftwidth = 4
set.expandtab = false
set.scrolloff = 8
set.cursorline = true

-- set highlight on search
vim.o.hlsearch = false
vim.o.incsearch = true

-- make line numbers default
vim.wo.number = true

-- enable mouse mode
vim.o.mouse = 'a'

-- sync clipboard between os and neovim.
--  remove this option if you want your os clipboard to remain independent.
--  see `:help 'clipboard'`
vim.o.clipboard = 'unnamedplus'

-- enable break indent
vim.o.breakindent = true

-- save undo history
vim.o.undofile = true

-- case-insensitive searching unless \c or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- keep signcolumn on by default
vim.wo.signcolumn = 'yes'

-- decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- note: you should make sure your terminal supports this
vim.o.termguicolors = true

-- install package manager
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system {
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable', -- latest stable release
        lazypath,
    }
end
vim.opt.rtp:prepend(lazypath)

local function is_complete_setup(_)
    return vim.g.use_complete_setup
end

-- HACK: handle issues with treesitter syntax highlight
vim.filetype.add {
    extension = {
        gotmpl = 'gotmpl',
    },
    pattern = {
        ['.*/templates/.*%.tpl'] = 'helm',
        ['.*/templates/.*%.ya?ml'] = 'helm',
        ['helmfile.*%.ya?ml'] = 'helm',
    },
}
vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'mustache' },
    callback = function()
        if vim.fn.expand '%:e' == 'tpl' then
            vim.bo.filetype = 'helm'
        end
    end,
})

require('lazy').setup({
    -- git related plugins
    'tpope/vim-fugitive',
    'tpope/vim-rhubarb',

    -- detect tabstop and shiftwidth automatically
    'tpope/vim-sleuth',

    {
        -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
        -- used for completion, annotations and signatures of Neovim apis
        'folke/lazydev.nvim',
        ft = 'lua',
        cond = is_complete_setup,
        opts = {
            library = {
                -- Load luvit types when the `vim.uv` word is found
                { path = 'luvit-meta/library', words = { 'vim%.uv' } },
            },
        },
    },
    { 'Bilal2453/luvit-meta', lazy = true },
    {
        -- lsp configuration & plugins
        'neovim/nvim-lspconfig',
        cond = is_complete_setup,
        dependencies = {
            -- automatically install lsps to stdpath for neovim
            'mason-org/mason.nvim',
            'mason-org/mason-lspconfig.nvim',
            'WhoIsSethDaniel/mason-tool-installer.nvim',
            -- useful status updates for lsp
            -- note: `opts = {}` is the same as calling `require('fidget').setup({})`
            { 'j-hui/fidget.nvim', tag = 'legacy', opts = {} },
            -- note: required for sqls
            { 'nanotee/sqls.nvim' },

            -- Allows extra capabilities provided by nvim-cmp
            'hrsh7th/cmp-nvim-lsp',
        },
        config = function()
            -- [[ Configure LSP ]]
            local on_attach = function(client, bufnr)
                local nmap = function(keys, func, desc)
                    if desc then
                        desc = 'LSP: ' .. desc
                    end

                    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
                end

                -- HACK: it is broken: https://github.com/sqls-server/sqls/issues/149
                if client.name == 'sqls' then
                    client.server_capabilities.documentFormattingProvider = nil
                    client.server_capabilities.documentRangeFormattingProvider = nil
                end

                nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
                nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

                nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
                nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
                nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
                nmap('<leader>D', vim.lsp.buf.type_definition, 'Type [D]efinition')
                nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
                nmap('<leader>ss', function()
                    require('telescope.builtin').lsp_dynamic_workspace_symbols { bufnr = bufnr }
                end, '[W]orkspace [S]ymbols')

                -- See `:help K` for why this keymap
                nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
                nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

                -- Lesser used LSP functionality
                nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
                -- Replaced by conform
                -- nmap('<leader>cf', vim.lsp.buf.format, '[C]ode [F]ormat')
                nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
                nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
                nmap('<leader>wl', function()
                    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                end, '[W]orkspace [L]ist Folders')

                -- Create a command `:Format` local to the LSP buffer
                vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
                    vim.lsp.buf.format()
                end, { desc = 'Format current buffer with LSP' })

                -- Activate inline hints
                if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
                    vim.lsp.inlay_hint.enable(true)
                    nmap('<leader>th', function()
                        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr })
                    end, '[T]oggle Inlay [H]ints')
                end

                -- Enable semantic tokens
                if client.server_capabilities.semanticTokensProvider then
                    vim.lsp.semantic_tokens.start(bufnr, client.id)
                end
            end

            local servers = nil
            local lsp_dependencies = nil
            if vim.g.use_complete_setup == true then
                -- https://mason-registry.dev/registry/list
                lsp_dependencies = {
                    'stylua',
                    'ktlint',
                    'prettierd',
                    'isort',
                    'black',
                    'gofumpt',
                    'goimports',
                    'gotests',
                    'shfmt',
                    'tflint',
                    'tree-sitter-cli',
                    'sql-formatter',
                }
                servers = {
                    -- rust_analyzer = {},
                    bashls = {},
                    docker_compose_language_service = {},
                    dockerls = {},
                    eslint = {},
                    zls = {},
                    -- golangci_lint_ls = {},
                    gopls = {
                        settings = {
                            gopls = {
                                analyses = {
                                    shadow = true,
                                    useany = false,
                                    ST1000 = false,
                                    ST1020 = false,
                                    ST1021 = false,
                                    ST1022 = false,
                                },
                                staticcheck = true,
                                hints = {
                                    assignVariableTypes = true,
                                    compositeLiteralFields = true,
                                    compositeLiteralTypes = true,
                                    constantValues = true,
                                    functionTypeParameters = true,
                                    parameterNames = true,
                                    rangeVariableTypes = true,
                                },
                                buildFlags = { '-tags=integration wireinject !wireinject' },
                                directoryFilters = { '-.git', '-.vscode', '-.idea', '-.vscode-test', '-node_modules' },
                                semanticTokens = true,
                                codelenses = {
                                    gc_details = false,
                                    generate = true,
                                    regenerate_cgo = true,
                                    run_govulncheck = true,
                                    test = true,
                                    tidy = true,
                                    upgrade_dependency = true,
                                    vendor = true,
                                },
                            },
                        },
                    },
                    templ = {},
                    gradle_ls = {},
                    helm_ls = {},
                    html = { filetypes = { 'html', 'twig', 'hbs' } },
                    jsonls = {},
                    -- kotlin_lsp = {},
                    ts_ls = {},
                    sqls = {
                        settings = {
                            sqls = {
                                connections = {
                                    {
                                        driver = 'mysql',
                                        dataSourceName = 'root:root@tcp(127.0.0.1:3306)/tinypass',
                                    },
                                },
                            },
                        },
                    },
                    marksman = {},
                    lua_ls = {
                        -- cmd = {...},
                        -- filetypes = { ...},
                        -- capabilities = {},
                        settings = {
                            Lua = {
                                completion = {
                                    callSnippet = 'Replace',
                                },
                            },
                        },
                    },
                }
            else
                lsp_dependencies = {
                    'stylua',
                    'gofumpt',
                    'goimports',
                    'shfmt',
                    'sql-formatter',
                }
                servers = {
                    gopls = {
                        settings = {
                            gopls = {
                                semanticTokens = true,
                                analyses = {
                                    shadow = true,
                                    useany = false,
                                },
                                staticcheck = true,
                                hints = {
                                    assignVariableTypes = true,
                                    compositeLiteralFields = true,
                                    compositeLiteralTypes = true,
                                    constantValues = true,
                                    functionTypeParameters = true,
                                    parameterNames = true,
                                    rangeVariableTypes = true,
                                },
                            },
                        },
                    },
                    lua_ls = {
                        settings = {
                            Lua = {
                                completion = {
                                    callSnippet = 'Replace',
                                },
                            },
                        },
                    },
                }
            end

            -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())
            capabilities.textDocument.semanticTokens = {
                dynamicRegistration = false,
                requests = {
                    full = { delta = true },
                    range = true,
                },
                tokenTypes = {
                    'namespace',
                    'type',
                    'class',
                    'enum',
                    'interface',
                    'struct',
                    'typeParameter',
                    'parameter',
                    'variable',
                    'property',
                    'enumMember',
                    'event',
                    'function',
                    'method',
                    'macro',
                    'keyword',
                    'modifier',
                    'comment',
                    'string',
                    'number',
                    'regexp',
                    'operator',
                    'decorator',
                },
                tokenModifiers = {
                    'declaration',
                    'definition',
                    'readonly',
                    'static',
                    'deprecated',
                    'abstract',
                    'async',
                    'modification',
                    'documentation',
                    'defaultLibrary',
                },
                formats = { 'relative' },
                overlappingTokenSupport = false,
                multilineTokenSupport = false,
            }

            for server_name, server_config in pairs(servers) do
                local extended_capabilities = vim.tbl_deep_extend('force', {}, capabilities, server_config.capabilities or {})
                local config = vim.tbl_deep_extend('force', { on_attach = on_attach, capabilities = extended_capabilities }, server_config or {})
                vim.lsp.config(server_name, config)
            end

            -- vim.lsp.enable(vim.tbl_keys(servers))

            require('mason').setup()
            local ensure_installed_lsp = vim.tbl_keys(servers or {})
            local ensure_installed_all = vim.tbl_keys(servers or {})
            vim.list_extend(ensure_installed_all, lsp_dependencies)
            require('mason-tool-installer').setup { ensure_installed = ensure_installed_all }
            require('mason-lspconfig').setup {
                ensure_installed = ensure_installed_lsp,
                automatic_enable = true,
            }
        end,
    },

    {
        -- autocompletion
        'hrsh7th/nvim-cmp',
        cond = is_complete_setup,
        dependencies = {
            -- snippet engine & its associated nvim-cmp source
            'l3mon4d3/luasnip',
            'saadparwaiz1/cmp_luasnip',

            -- show function parameter while typing
            'hrsh7th/cmp-nvim-lsp-signature-help',
            -- adds lsp completion capabilities
            'hrsh7th/cmp-nvim-lsp',

            -- adds a number of user-friendly snippets
            'rafamadriz/friendly-snippets',
        },
    },

    -- useful plugin to show you pending keybinds.
    {
        'folke/which-key.nvim',
        opts = {
            icons = {
                -- show cool icons if nerd font is installed
                mappings = true,
            },
        },
    },
    {
        -- adds git related signs to the gutter, as well as utilities for managing changes
        'lewis6991/gitsigns.nvim',
        opts = {
            -- see `:help gitsigns.txt`
            signs = {
                add = { text = '+' },
                change = { text = '~' },
                delete = { text = '_' },
                topdelete = { text = '‾' },
                changedelete = { text = '~' },
            },
            on_attach = function(bufnr)
                local gitsigns = require 'gitsigns'
                vim.keymap.set('n', '<leader>hp', gitsigns.preview_hunk, { buffer = bufnr, desc = 'preview git hunk' })
                vim.keymap.set('n', '<leader>hb', gitsigns.toggle_current_line_blame, { buffer = bufnr, desc = 'toggle git blame' })
                vim.keymap.set('n', '<leader>hC', gitsigns.blame, { buffer = bufnr, desc = 'git blame commit' })
                vim.keymap.set('n', '<leader>hc', gitsigns.blame_line, { buffer = bufnr, desc = 'git blame commits' })
                vim.keymap.set('n', '<leader>hD', function()
                    gitsigns.diffthis '@'
                end, { buffer = bufnr, desc = 'diff against last commit' })

                -- don't override the built-in and fugitive keymaps
                local gs = package.loaded.gitsigns
                vim.keymap.set({ 'n', 'v' }, ']c', function()
                    if vim.wo.diff then
                        return ']c'
                    end
                    vim.schedule(function()
                        gs.next_hunk()
                    end)
                    return '<ignore>'
                end, { expr = true, buffer = bufnr, desc = 'jump to next hunk' })
                vim.keymap.set({ 'n', 'v' }, '[c', function()
                    if vim.wo.diff then
                        return '[c'
                    end
                    vim.schedule(function()
                        gs.prev_hunk()
                    end)
                    return '<ignore>'
                end, { expr = true, buffer = bufnr, desc = 'jump to previous hunk' })
            end,
        },
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

    -- "gc" to comment visual regions/lines
    { 'numtostr/comment.nvim', opts = {} },

    -- Highlight todo, notes, etc in comments
    {
        'folke/todo-comments.nvim',
        cond = is_complete_setup,
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = {},
    },

    -- auto closer for brackets
    {
        'windwp/nvim-autopairs',
        event = 'InsertEnter',
        config = function()
            require('nvim-autopairs').setup {}
            -- if you want to automatically add `(` after selecting a function or method
            if is_complete_setup() then
                local cmp_autopairs = require 'nvim-autopairs.completion.cmp'
                local cmp = require 'cmp'
                cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
            end
        end,
    },

    -- fuzzy finder (files, lsp, etc)
    {
        'nvim-telescope/telescope.nvim',
        --BUG: https://github.com/nvim-telescope/telescope.nvim/issues/3438
        -- branch = '0.1.x',
        dependencies = {
            'nvim-lua/plenary.nvim',
            -- fuzzy finder algorithm which requires local dependencies to be built.
            -- only load if `make` is available. make sure you have the system
            -- requirements installed.
            {
                'nvim-telescope/telescope-fzf-native.nvim',
                -- note: if you are having trouble with this installation,
                --       refer to the readme for telescope-fzf-native for more instructions.
                build = 'make',
                cond = function()
                    return vim.fn.executable 'make' == 1
                end,
            },
        },
        config = function()
            -- See `:help telescope` and `:help telescope.setup()`
            require('telescope').setup {
                defaults = {
                    mappings = {
                        i = {
                            ['<C-u>'] = false,
                            ['<C-d>'] = false,
                        },
                    },
                },
                extensions = {
                    ['ui-select'] = {
                        require('telescope.themes').get_dropdown(),
                    },
                },
            }

            -- Enable telescope fzf native, if installed and custom dropdowns
            pcall(require('telescope').load_extension, 'fzf')
            pcall(require('telescope').load_extension, 'ui-select')

            -- See `:help telescope.builtin`
            local builtin = require 'telescope.builtin'
            vim.keymap.set('n', '<leader>?', builtin.oldfiles, { desc = '[?] Find recently opened files' })
            vim.keymap.set('n', '<leader><space>', builtin.buffers, { desc = '[ ] Find existing buffers' })
            vim.keymap.set('n', '<leader>/', function()
                -- You can pass additional configuration to telescope to change theme, layout, etc.
                require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                    winblend = 10,
                    previewer = false,
                })
            end, { desc = '[/] Fuzzily search in current buffer' })
            vim.keymap.set('n', '<leader>gf', builtin.git_files, { desc = 'Search [G]it [F]iles' })
            vim.keymap.set('n', '<leader>gs', builtin.git_status, { desc = 'Search [G]it [S]tatus' })
            vim.keymap.set('n', '<leader>gc', builtin.git_commits, { desc = 'Search [G]it [C]ommits' })
            vim.keymap.set('n', '<leader>gb', builtin.git_branches, { desc = 'Search [G]it [B]ranches' })
            vim.keymap.set('n', '<leader>gt', builtin.git_stash, { desc = 'Search [G]it S[t]ash' })
            vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
            vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
            vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
            vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
            vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
            vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]resume' })
            vim.keymap.set('n', '<leader>sa', ':', { desc = '[S]earch [A]action' })
            vim.keymap.set('n', '<leader>s/', function()
                builtin.live_grep {
                    grep_open_files = true,
                    prompt_title = 'Live Grep in Open Files',
                }
            end, { desc = '[S]earch [/] in Open Files' })
        end,
    },

    -- file tree
    {
        'nvim-neo-tree/neo-tree.nvim',
        branch = 'v3.x',
        cond = is_complete_setup,
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
            'muniftanjim/nui.nvim',
            'mbbill/undotree',
        },
        opts = {
            filesystem = {
                hijack_netrw_behavior = 'disabled',
                follow_current_file = {
                    enabled = true,
                    leave_dirs_open = true,
                },
                filtered_items = {
                    visible = false,
                    show_hidden_count = true,
                    hide_dotfiles = false,
                    hide_gitignored = true,
                    hide_by_name = {
                        '.git',
                        '.DS_Store',
                    },
                    never_show = {},
                },
            },
            sources = {
                'filesystem',
                'buffers',
                'git_status',
                'diagnostics',
                'netman.ui.neo-tree',
            },
            source_selector = {
                winbar = false,
                statusline = false,
                sources = {
                    {
                        source = 'filesystem',
                        display_name = ' 󰉓 ',
                    },
                    {
                        source = 'buffers',
                        display_name = ' 󰈚 ',
                    },
                    {
                        source = 'git_status',
                        display_name = ' 󰊢 ',
                    },
                    {
                        source = 'diagnostics',
                        display_name = '  ',
                    },
                    {
                        source = 'remote',
                        display_name = ' 󰢹 ',
                    },
                },
            },
        },
    },

    {
        -- highlight, edit, and navigate code
        'nvim-treesitter/nvim-treesitter',
        dependencies = {
            'nvim-treesitter/nvim-treesitter-textobjects',
            {
                'nvim-treesitter/nvim-treesitter-context',
                build = ':TSContext enable',
                opts = {
                    max_lines = 3,
                    multiline_threshold = 3,
                },
                init = function()
                    vim.keymap.set('n', '<leader>k', function()
                        require('treesitter-context').go_to_context(vim.v.count1)
                    end, { silent = true, desc = 'Jump to context root' })
                end,
            },
            'nvim-treesitter/nvim-treesitter-refactor',
        },
        build = ':TSUpdate',
        main = 'nvim-treesitter.configs',
        opts = {
            -- Add languages to be installed here that you want installed for treesitter
            ensure_installed = {
                'c',
                'cpp',
                'go',
                'gotmpl',
                'lua',
                'python',
                'rust',
                'tsx',
                'css',
                'javascript',
                'typescript',
                'vimdoc',
                'vim',
                'kotlin',
                'java',
                'yaml',
                'helm',
                'bash',
                'markdown',
                'query',
                'comment',
                'terraform',
                'zig',
                'latex',
            },

            -- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
            auto_install = true,

            highlight = {
                enable = true,
                -- disable = function(lang, buf)
                --     print 'DISABLING'
                --     local max_filesize = 100 * 1024 -- 100 KB
                --     local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
                --     if ok and stats and stats.size > max_filesize then
                --         return true
                --     end
                -- end,
            },
            -- NOTE: it breaks go lang indent, try to enable it some time later
            indent = { enable = true, disable = { 'go', 'lua' } },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = '<c-space>',
                    node_incremental = '<c-space>',
                    scope_incremental = '<c-s>',
                    node_decremental = '<M-space>',
                },
            },
            textobjects = {
                select = {
                    enable = true,
                    lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
                    keymaps = {
                        -- You can use the capture groups defined in textobjects.scm
                        ['aa'] = '@parameter.outer',
                        ['ia'] = '@parameter.inner',
                        ['af'] = '@function.outer',
                        ['if'] = '@function.inner',
                        ['ac'] = '@class.outer',
                        ['ic'] = '@class.inner',
                    },
                },
                move = {
                    enable = true,
                    set_jumps = true, -- whether to set jumps in the jumplist
                    goto_next_start = {
                        [']m'] = '@function.outer',
                        [']]'] = '@class.outer',
                    },
                    goto_next_end = {
                        [']M'] = '@function.outer',
                        [']['] = '@class.outer',
                    },
                    goto_previous_start = {
                        ['[m'] = '@function.outer',
                        ['[['] = '@class.outer',
                    },
                    goto_previous_end = {
                        ['[M'] = '@function.outer',
                        ['[]'] = '@class.outer',
                    },
                },
                swap = {
                    enable = true,
                    swap_next = {
                        ['<leader>a'] = '@parameter.inner',
                    },
                    swap_previous = {
                        ['<leader>A'] = '@parameter.inner',
                    },
                },
            },
            refactor = {
                highlight_definitions = {
                    -- Lags on big files
                    disable = function(lang, buf)
                        local max_filesize = 100 * 1024 -- 100 KB
                        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
                        if ok and stats and stats.size > max_filesize then
                            return true
                        end
                    end,
                    enable = true,
                    -- Set to false if you have an `updatetime` of ~100.
                    clear_on_cursor_move = true,
                },
                highlight_current_scope = { enable = false },
            },
        },
    },

    require 'kickstart.plugins.autoformat',
    require 'kickstart.plugins.debug',
    { import = 'custom.plugins' },
    { import = 'custom.profile' },
    { import = 'custom.zig' },
    { import = 'custom.math' },
}, {})

-- [[ basic keymaps ]]
-- keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
-- Move visual blocks
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")
-- Better join lines
vim.keymap.set('n', 'J', 'mzJ`z')
-- Centred page scroll
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
-- Centred search result
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')
-- Paster without buffer replace
vim.keymap.set('x', '<leader>p', [["_dP]])
-- Keymap to add new line without entering insert mode
vim.keymap.set('n', '<leader>o', 'o<Esc>0"_D', { desc = 'Insert next blank line' })
vim.keymap.set('n', '<leader>O', 'O<Esc>0"_D', { desc = 'Insert blank line' })
-- Undo tree
vim.keymap.set('n', '<leader>F', vim.cmd.UndotreeToggle, { desc = 'Toggle undotree' })
-- Neotree mappings
vim.keymap.set('n', '<leader>f', '<Cmd>Neotree toggle<CR>', { desc = 'Toggle filetree' })
vim.keymap.set('n', '<leader>gg', '<Cmd>Neotree float git_status<CR>', { desc = 'Toggle [2g]it tree' })
vim.keymap.set('n', '<leader>ge', '<Cmd>Neotree float diagnostics<CR>', { desc = 'To[g]gl[e] diagnostics window' })
vim.keymap.set('n', '<leader>gr', '<Cmd>Neotree float remote<CR>', { desc = 'To[g]gle [r]emote window' })
-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', '<Cmd>TroubleToggle document_diagnostics<CR>', { desc = 'Open diagnostics list' })
-- Buffers
vim.keymap.set('n', '<leader>bda', '<Cmd>%bd|e#<CR>', { desc = 'Close all buffers, but this' })

-- [[ Highlight onyank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
        vim.highlight.on_yank()
    end,
    group = highlight_group,
    pattern = '*',
})

-- [[ Remap for toggleterm to escape from the terminal buffer]]
function _G.set_terminal_keymaps()
    local opts = { buffer = 0 }
    vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
    vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
    vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
    vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
    vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
    vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
    vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
end

-- if you only want these mappings for toggle term use term://*toggleterm#* instead
vim.cmd 'autocmd! TermOpen term://* lua set_terminal_keymaps()'

-- [[ Configure nvim-cmp ]]
-- See `:help cmp`
if is_complete_setup() then
    local cmp = require 'cmp'
    local luasnip = require 'luasnip'
    require('luasnip.loaders.from_vscode').lazy_load()
    luasnip.config.setup {}

    cmp.setup {
        snippet = {
            expand = function(args)
                luasnip.lsp_expand(args.body)
            end,
        },
        mapping = cmp.mapping.preset.insert {
            ['<C-n>'] = cmp.mapping.select_next_item(),
            ['<C-p>'] = cmp.mapping.select_prev_item(),
            ['<C-d>'] = cmp.mapping.scroll_docs(-4),
            ['<C-f>'] = cmp.mapping.scroll_docs(4),
            ['<C-Space>'] = cmp.mapping.complete {},
            ['<CR>'] = cmp.mapping.confirm {
                behavior = cmp.ConfirmBehavior.Replace,
                select = true,
            },
            ['<Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_next_item()
                elseif luasnip.expand_or_locally_jumpable() then
                    luasnip.expand_or_jump()
                else
                    fallback()
                end
            end, { 'i', 's' }),
            ['<S-Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item()
                elseif luasnip.locally_jumpable(-1) then
                    luasnip.jump(-1)
                else
                    fallback()
                end
            end, { 'i', 's' }),
        },
        sources = {
            {
                name = 'lazydev',
                -- set group index to 0 to skip loading LuaLS completions as lazydev recommends it
                group_index = 0,
            },
            { name = 'nvim_lsp' },
            { name = 'nvim_lsp_signature_help' },
            { name = 'luasnip' },
            { name = 'path' },
        },
    }
end
