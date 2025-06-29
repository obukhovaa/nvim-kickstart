if not vim.g.use_complete_setup then
    return {}
end

return {

    'mfussenegger/nvim-dap',
    dependencies = {
        -- Creates a beautiful debugger UI
        'rcarriga/nvim-dap-ui',
        -- Required dependency for nvim-dap-ui
        'nvim-neotest/nvim-nio',
        -- Installs the debug adapters for you
        'mason-org/mason.nvim',
        'jay-babu/mason-nvim-dap.nvim',

        -- Add your own debuggers here
        'leoluz/nvim-dap-go',
        {
            'mxsdev/nvim-dap-vscode-js',
            dependencies = {
                {
                    'microsoft/vscode-js-debug',
                    build = 'npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out',
                },
            },
        },
        -- Add inline debug values
        'theHamsta/nvim-dap-virtual-text',
    },
    config = function()
        local dap = require 'dap'
        local dapui = require 'dapui'

        require('mason-nvim-dap').setup {
            -- Makes a best effort to setup the various debuggers with
            -- reasonable debug configurations
            automatic_installation = true,

            -- You can provide additional configuration to the handlers,
            -- see mason-nvim-dap README for more information
            handlers = {},

            -- You'll need to check that you have the required things installed
            -- online, please don't ask me how to install them :)
            ensure_installed = {
                -- Update this to ensure that you have the debuggers for the langs you want
                'delve',
                'js',
                'kotlin',
            },
        }

        require('nvim-dap-virtual-text').setup()

        -- Basic debugging keymaps, feel free to change to your liking!
        vim.keymap.set('n', '<F5>', dap.continue, { desc = 'Debug: Start/Continue' })
        vim.keymap.set('n', '<F1>', dap.step_into, { desc = 'Debug: Step Into' })
        vim.keymap.set('n', '<F2>', dap.step_over, { desc = 'Debug: Step Over' })
        vim.keymap.set('n', '<F3>', dap.step_out, { desc = 'Debug: Step Out' })
        vim.keymap.set('n', '<leader>b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
        vim.keymap.set('n', '<leader>B', function()
            dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
        end, { desc = 'Debug: Set Breakpoint' })

        -- Dap UI setup
        -- For more information, see |:help nvim-dap-ui|
        dapui.setup {
            -- Set icons to characters that are more likely to work in every terminal.
            --    Feel free to remove or use ones that you like more! :)
            --    Don't feel like these are good choices.
            icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
            controls = {
                icons = {
                    pause = '⏸',
                    play = '▶',
                    step_into = '⏎',
                    step_over = '⏭',
                    step_out = '⏮',
                    step_back = 'b',
                    run_last = '▶▶',
                    terminate = '⏹',
                    disconnect = '⏏',
                },
            },
        }

        -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
        vim.keymap.set('n', '<F7>', dapui.toggle, { desc = 'Debug: See last session result.' })

        dap.listeners.after.event_initialized['dapui_config'] = dapui.open
        dap.listeners.before.event_terminated['dapui_config'] = dapui.close
        dap.listeners.before.event_exited['dapui_config'] = dapui.close

        -- Install golang specific config
        require('dap-go').setup()
        vim.keymap.set('n', '<leader>td', function()
            require('dap-go').debug_test()
        end, { desc = 'Debug closest test' })
        vim.keymap.set('n', '<leader>tl', function()
            require('dap-go').debug_last_test()
        end, { desc = 'Debug last test' })
        vim.keymap.set('n', '<leader>ti', function()
            require('dap-go').debug_test { buildFlags = '-tags=integration' }
        end, { desc = 'Debug closest integration test' })

        -- Install js specific config
        require('dap-vscode-js').setup {
            -- node_path = "node", -- Path of node executable. Defaults to $NODE_PATH, and then "node"
            debugger_path = os.getenv 'HOME' .. '/.local/share/nvim/lazy/vscode-js-debug', -- Path to vscode-js-debug installation.
            -- debugger_cmd = 'js-debug-adapter' },
            adapters = { 'chrome', 'node', 'pwa-node', 'pwa-chrome', 'node-terminal', 'pwa-extensionHost' }, -- which adapters to register in nvim-dap
            -- log_file_path = "(stdpath cache)/dap_vscode_js.log" -- Path for file logging
            -- log_file_level = false -- Logging level for output to file. Set to false to disable file logging.
            -- log_console_level = vim.log.levels.ERROR
        }

        -- language config
        for _, language in ipairs { 'typescript', 'javascript' } do
            dap.configurations[language] = {
                {
                    type = 'pwa-node',
                    request = 'launch',
                    name = 'Launch Current File (pwa-node)',
                    cwd = vim.fn.getcwd(),
                    args = { '${file}' },
                    sourceMaps = true,
                    protocol = 'inspector',
                },
                {
                    type = 'pwa-node',
                    request = 'launch',
                    name = 'Launch Current File (pwa-node with ts-node)',
                    cwd = vim.fn.getcwd(),
                    runtimeArgs = { '--loader', 'ts-node/esm' },
                    runtimeExecutable = 'node',
                    args = { '${file}' },
                    sourceMaps = true,
                    protocol = 'inspector',
                    skipFiles = { '<node_internals>/**', 'node_modules/**' },
                    resolveSourceMapLocations = {
                        '${workspaceFolder}/**',
                        '!**/node_modules/**',
                    },
                },
                {
                    type = 'pwa-node',
                    request = 'launch',
                    name = 'Launch Test Current File (pwa-node with jest)',
                    cwd = vim.fn.getcwd(),
                    runtimeArgs = { '${workspaceFolder}/node_modules/.bin/jest' },
                    runtimeExecutable = 'node',
                    args = { '${file}', '--coverage', 'false' },
                    rootPath = '${workspaceFolder}',
                    sourceMaps = true,
                    console = 'integratedTerminal',
                    internalConsoleOptions = 'neverOpen',
                    skipFiles = { '<node_internals>/**', 'node_modules/**' },
                },
                -- node --inspect ./app.js ; then F5 and `Attach to the process`
                {
                    type = 'pwa-node',
                    request = 'attach',
                    name = 'Attach to the process',
                    processId = require('dap.utils').pick_process,
                    cwd = '${workspaceFolder}',
                },
                {
                    type = 'pwa-chrome',
                    request = 'launch',
                    name = 'Start Chrome with "localhost"',
                    url = 'http://localhost:3000',
                    webRoot = '${workspaceFolder}',
                },
                {
                    name = 'Wrangler',
                    type = 'pwa-node',
                    request = 'attach',
                    port = 9229,
                    cwd = vim.fn.getcwd(),
                    resolveSourceMapLocations = nil,
                    attachExistingChildren = false,
                    autoAttachChildProcesses = false,
                    sourceMaps = true,
                },
            }
        end
    end,
}
