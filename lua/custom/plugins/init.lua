-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
	'obukhovaa/gotests-vim',    -- generates go test templates
	{
		'mhartington/formatter.nvim', -- ktlint for koltin sources
		opts = function()
			local ktlint = require("formatter.filetypes.kotlin").ktlint
			return {
				logging = true,
				log_level = vim.log.levels.WARN,
				filetypes = {
					kotlin = {
						ktlint()
					},

					-- Use the special "*" filetype for defining formatter configurations on
					-- any filetype
					-- ["*"] = {
					-- "formatter.filetypes.any" defines default configurations for any
					-- filetype
					-- require("formatter.filetypes.any").remove_trailing_whitespace
					-- }
				}
			}
		end
	},
}
