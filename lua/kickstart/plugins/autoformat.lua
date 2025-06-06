return {
    { -- Autoformat
        'stevearc/conform.nvim',
        event = { 'BufWritePre' },
        cmd = { 'ConformInfo' },
        keys = {
            {
                '<leader>cf',
                function()
                    require('conform').format { async = true, lsp_format = 'fallback' }
                end,
                mode = '',
                desc = '[c]code [f]ormat',
            },
        },
        opts = {
            notify_on_error = true,
            notify_no_formatters = true,
            format_on_save = function(bufnr)
                -- Disable "format_on_save lsp_fallback" for languages that don't
                -- have a well standardized coding style. You can add additional
                -- languages here or re-enable it for the disabled ones.
                local disable_filetypes = { c = true, cpp = true }
                local lsp_format_opt
                if disable_filetypes[vim.bo[bufnr].filetype] then
                    lsp_format_opt = 'never'
                else
                    lsp_format_opt = 'fallback'
                end
                return {
                    timeout_ms = 500,
                    lsp_format = lsp_format_opt,
                }
            end,
            log_level = vim.log.levels.ERROR,
            formatters_by_ft = {
                lua = { 'stylua' },
                kotlin = { 'ktlint', lsp_format = 'fallback' },
                go = { 'goimports', 'gofumpt', lsp_format = 'fallback' },
                python = { 'isort', 'black' },
                javascript = { 'prettierd', 'prettier', stop_after_first = true, lsp_format = 'fallback' },
                typescript = { 'prettierd', lsp_format = 'fallback' },
                css = { 'prettierd', lsp_format = 'fallback' },
                sh = { 'shfmt', lsp_format = 'fallback' },
                bash = { 'shfmt', lsp_format = 'fallback' },
                sql = { 'sql_formatter', lsp_format = 'fallback' },
            },
        },
    },
}
