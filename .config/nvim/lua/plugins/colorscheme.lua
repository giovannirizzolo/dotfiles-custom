return {
	{
		"craftzdog/solarized-osaka.nvim",
		lazy = true,
		priority = 1000,
		opts = function()
			-- Repainted with the active Ghostty theme (see config/ghostty_theme.lua);
			-- falls back to stock solarized-osaka if no Ghostty theme can be read.
			local ghostty = require("config.ghostty_theme")
			return {
				transparent = true,
				-- Set to Ghostty's exact palette in on_highlights instead.
				terminal_colors = false,
				on_colors = ghostty.apply_colors,
				on_highlights = function(hl, colors)
					ghostty.apply_highlights(hl, colors)
					-- Let Ghostty's background show through the status/win bars too
					for _, group in ipairs({ "StatusLine", "StatusLineNC", "WinBar", "WinBarNC" }) do
						local current = type(hl[group]) == "table" and hl[group] or {}
						hl[group] = vim.tbl_extend("force", current, { bg = "NONE" })
					end
				end,
			}
		end,
		init = function()
			-- Follow `ghostty_theme` switches live.
			require("config.ghostty_theme").watch()
		end,
	},
}
