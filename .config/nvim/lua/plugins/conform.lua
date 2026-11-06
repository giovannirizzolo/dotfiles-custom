-- lua/plugins/conform.lua
return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	opts = function(_, opts)
		opts.formatters_by_ft = opts.formatters_by_ft or {}
		opts.formatters_by_ft.python = { "ruff_format", "ruff_organize_imports" }
		opts.formatters_by_ft.xml = { "xmllint" }
		-- snacks bigfile sets ft=bigfile but keeps the original ft in 'syntax'
		opts.formatters_by_ft.bigfile = function(bufnr)
			return vim.bo[bufnr].syntax == "xml" and { "xmllint" } or {}
		end
		-- oxfmt exclusively for ts/tsx, overriding prettier from the formatting.prettier extra
		opts.formatters_by_ft.typescript = { "oxfmt" }
		opts.formatters_by_ft.typescriptreact = { "oxfmt" }
	end,
}
