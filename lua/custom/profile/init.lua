vim.keymap.set('n', '<leader>ups', function()
    vim.cmd [[
		:profile start /tmp/nvim-profile.log
		:profile func *
		:profile file *
	]]
end, { desc = 'Profile Start' })

vim.keymap.set('n', '<leader>upe', function()
    vim.cmd [[
		:profile stop
		:e /tmp/nvim-profile.log
	]]
end, { desc = 'Profile End' })

return {}
