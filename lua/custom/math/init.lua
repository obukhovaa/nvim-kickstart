return {
    {
        'jbyuki/nabla.nvim',
        dependencies = {
            'nvim-neo-tree/neo-tree.nvim',
            'mason-org/mason.nvim',
        },
        lazy = true,

        keys = function()
            return {
                {
                    '<leader>p',
                    ':lua require("nabla").popup()<cr>',
                    desc = 'NablaPopUp',
                },
            }
        end,
    },
}
