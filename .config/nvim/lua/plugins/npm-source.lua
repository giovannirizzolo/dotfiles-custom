return {
	{
		"nvim-lua/plenary.nvim",
		lazy = true,
		config = function()
			local Job = require("plenary.job")

			local function open_repo_for_pkg(pkg)
				if not pkg or pkg == "" then
					vim.notify("No package name found", vim.log.levels.WARN)
					return
				end

				Job:new({
					command = "pnpm",
					args = { "view", pkg, "repository.url" },
					on_exit = function(j, code)
						vim.schedule(function()
							if code ~= 0 then
								vim.notify("pnpm view failed for: " .. pkg, vim.log.levels.ERROR)
								return
							end

							local url = (j:result()[1] or ""):gsub("^git%+", ""):gsub("%.git$", "")
							if url == "" then
								vim.notify("No repository.url for: " .. pkg, vim.log.levels.WARN)
								return
							end

							local open_cmd = vim.fn.has("mac") == 1 and "open" or "xdg-open"
							vim.fn.jobstart({ open_cmd, url }, { detach = true })
							vim.notify("Opened: " .. url)
						end)
					end,
				}):start()
			end

			-- Try to grab "pkg" from import line: from "pkg"
			local function pkg_from_line()
				local line = vim.api.nvim_get_current_line()
				local pkg = line:match("from%s+[\"']([^\"']+)[\"']")
				if not pkg then
					return nil
				end
				-- strip subpath: lodash/fp -> lodash
				pkg = pkg:gsub("^(@[^/]+/[^/]+).*$", "%1"):gsub("^([^/]+).*$", "%1")
				return pkg
			end

			vim.keymap.set("n", "<leader>or", function()
				local pkg = pkg_from_line()
				if not pkg then
					-- fallback: word under cursor
					pkg = vim.fn.expand("<cword>")
				end
				open_repo_for_pkg(pkg)
			end, { desc = "Open npm package repo (pnpm view)" })
		end,
	},
}
