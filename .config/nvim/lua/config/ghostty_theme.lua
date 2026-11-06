-- Keeps Neovim's colors in sync with the active Ghostty theme.
--
-- Reads the theme Ghostty is using (current-theme.ghostty, written by the
-- fish `ghostty_theme` picker, falling back to `theme =` in config.ghostty)
-- and repaints solarized-osaka with that theme's exact background,
-- foreground, cursor, selection and 16 ANSI colors. Shade tiers (50..950)
-- are derived from those, mixing towards the theme's own background.
--
-- `GHOSTTY_THEME_FILE=/path/to/theme nvim` forces a theme (used for testing).

local M = {}

M.dir = vim.fn.expand("~/.config/ghostty")
M.state_file = M.dir .. "/current-theme.ghostty"
local builtin_dir = "/Applications/Ghostty.app/Contents/Resources/ghostty/themes"

local function read_lines(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local lines = {}
	for line in f:lines() do
		lines[#lines + 1] = line
	end
	f:close()
	return lines
end

-- `theme = "..."` value from a Ghostty config file (quotes optional).
local function theme_setting(path)
	for _, line in ipairs(read_lines(path) or {}) do
		local v = line:match("^%s*theme%s*=%s*(.-)%s*$")
		if v and v ~= "" then
			return (v:gsub('^"(.*)"$', "%1"))
		end
	end
end

local function resolve(name)
	if name:sub(1, 2) == "~/" then
		name = vim.fn.expand("~") .. name:sub(2)
	end
	if name:sub(1, 1) == "/" then
		return vim.uv.fs_stat(name) and name or nil
	end
	for _, d in ipairs({ M.dir .. "/themes", builtin_dir }) do
		local p = d .. "/" .. name
		if vim.uv.fs_stat(p) then
			return p
		end
	end
end

function M.theme_path()
	local forced = vim.env.GHOSTTY_THEME_FILE
	if forced and forced ~= "" then
		return forced
	end
	local name = theme_setting(M.state_file) or theme_setting(M.dir .. "/config.ghostty")
	return name and resolve(name)
end

local function hex(v)
	v = v and v:match("^#?(%x%x%x%x%x%x)")
	return v and ("#" .. v:lower()) or nil
end

--- Parse a Ghostty theme file. Returns nil if it lacks bg/fg/palette.
function M.read()
	local path = M.theme_path()
	local lines = path and read_lines(path)
	if not lines then
		return nil
	end
	local t = { path = path, palette = {} }
	for _, line in ipairs(lines) do
		local key, val = line:match("^%s*([%w%-]+)%s*=%s*(.-)%s*$")
		if key == "palette" then
			local i, c = val:match("^(%d+)%s*=%s*(.+)$")
			if i and hex(c) then
				t.palette[tonumber(i)] = hex(c)
			end
		elseif key == "background" or key == "foreground" or key == "cursor-color" or key == "selection-background" then
			t[key] = hex(val)
		end
	end
	for i = 0, 15 do
		if not t.palette[i] then
			return nil
		end
	end
	if not (t.background and t.foreground) then
		return nil
	end
	return t
end

-- ── color math ────────────────────────────────────────────────────────
local function rgb(h)
	return tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16)
end

--- Mix a towards b by amount (0 = a, 1 = b).
local function mix(a, b, amount)
	local r1, g1, b1 = rgb(a)
	local r2, g2, b2 = rgb(b)
	local function ch(x, y)
		return math.floor(x + (y - x) * amount + 0.5)
	end
	return string.format("#%02x%02x%02x", ch(r1, r2), ch(g1, g2), ch(b1, b2))
end

-- 500 is the exact ANSI color; lighter tiers run to the bright variant then
-- white, darker tiers sink into the theme background (used as backgrounds).
local function ramp(colors, name, normal, bright, bg)
	colors[name] = normal
	colors[name .. "500"] = normal
	colors[name .. "400"] = mix(normal, bright, 0.5)
	colors[name .. "300"] = bright
	colors[name .. "200"] = mix(bright, "#ffffff", 0.25)
	colors[name .. "100"] = mix(bright, "#ffffff", 0.50)
	colors[name .. "50"] = mix(bright, "#ffffff", 0.75)
	colors[name .. "600"] = mix(normal, bg, 0.15)
	colors[name .. "700"] = mix(normal, bg, 0.35)
	colors[name .. "800"] = mix(normal, bg, 0.55)
	colors[name .. "900"] = mix(normal, bg, 0.75)
	colors[name .. "950"] = mix(normal, bg, 0.88)
end

--- solarized-osaka `on_colors` hook: repaint the palette from Ghostty.
function M.apply_colors(colors)
	local t = M.read()
	M.current = t
	if not t then
		return -- no readable Ghostty theme: keep stock solarized-osaka
	end
	local p, bg, fg = t.palette, t.background, t.foreground

	ramp(colors, "red", p[1], p[9], bg)
	ramp(colors, "green", p[2], p[10], bg)
	ramp(colors, "orange", p[3], mix(p[3], p[11], 0.5), bg)
	ramp(colors, "yellow", p[11], mix(p[11], "#ffffff", 0.3), bg)
	ramp(colors, "blue", p[4], p[12], bg)
	ramp(colors, "magenta", p[5], p[13], bg)
	ramp(colors, "violet", mix(p[4], p[5], 0.5), mix(p[12], p[13], 0.5), bg)
	ramp(colors, "cyan", p[6], p[14], bg)

	-- Base tones: dark ones are tints of the background, light ones of the text.
	colors.base04 = bg
	colors.base03 = mix(bg, fg, 0.07)
	colors.base02 = mix(bg, fg, 0.16) -- borders, popup menus (selection stays exact in Visual)
	colors.base01 = p[8] -- comments, line numbers: Ghostty's "bright black"
	colors.base00 = mix(p[8], fg, 0.35)
	colors.base0 = fg
	colors.base1 = mix(fg, p[15], 0.5)
	colors.base2 = p[7]
	colors.base3 = p[15]
	colors.base4 = "#ffffff"

	colors.bg = bg
	colors.fg = fg
	colors.bg_highlight = colors.base03

	-- Derived keys osaka computed before this hook ran.
	colors.border = colors.base02
	colors.bg_popup = mix(bg, fg, 0.04)
	colors.bg_statusline = colors.base03
	colors.bg_sidebar = colors.bg_popup
	colors.bg_float = colors.bg_popup
	colors.fg_float = fg
	colors.error = colors.red500
	colors.warning = colors.yellow500
	colors.info = colors.blue500
	colors.hint = colors.cyan500
	colors.todo = colors.violet500
end

--- solarized-osaka `on_highlights` hook: exact cursor/selection + :terminal colors.
function M.apply_highlights(hl, colors)
	local t = M.current
	if not t then
		return
	end
	if t["cursor-color"] then
		hl.Cursor = { fg = t.background, bg = t["cursor-color"] }
		hl.lCursor = hl.Cursor
		hl.CursorIM = hl.Cursor
		hl.TermCursor = hl.Cursor
		-- Yank flash (LazyVim's on_yank uses IncSearch) and the live search
		-- match: the cursor color (pink in GTA VI, signal yellow in Gotham).
		hl.IncSearch = { fg = t.background, bg = t["cursor-color"] }
	end
	if t["selection-background"] then
		hl.Visual = { bg = t["selection-background"] }
		hl.VisualNOS = hl.Visual
	end
	for i = 0, 15 do
		vim.g["terminal_color_" .. i] = t.palette[i]
	end
end

-- ── live sync ─────────────────────────────────────────────────────────
local last_path
local function reapply()
	local path = M.theme_path()
	if path == last_path or vim.g.colors_name ~= "solarized-osaka" then
		return
	end
	last_path = path
	vim.cmd.colorscheme("solarized-osaka")
end

--- Re-theme when `ghostty_theme` switches (watching the Ghostty dir, since
--- the state file is rewritten), with FocusGained as a fallback.
function M.watch()
	last_path = M.theme_path()
	local timer = vim.uv.new_timer()
	local handle = vim.uv.new_fs_event()
	if handle then
		handle:start(M.dir, {}, function(_, fname)
			if fname == "current-theme.ghostty" then
				timer:stop()
				timer:start(150, 0, vim.schedule_wrap(reapply))
			end
		end)
	end
	vim.api.nvim_create_autocmd("FocusGained", {
		group = vim.api.nvim_create_augroup("ghostty_theme_sync", { clear = true }),
		callback = reapply,
	})
end

return M
