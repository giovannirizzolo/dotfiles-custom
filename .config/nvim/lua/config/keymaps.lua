local discipline = require("craftzdog.discipline")

discipline.cowboy()

local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- Do things without affecting the registers
keymap.set("n", "x", '"_x')
-- keymap.set("n", "<Leader>p", '"0p')
-- keymap.set("n", "<Leader>P", '"0P')
-- keymap.set("v", "<Leader>p", '"0p')
keymap.set("n", "<Leader>c", '"_c')
keymap.set("n", "<Leader>C", '"_C')
keymap.set("v", "<Leader>c", '"_c')
keymap.set("v", "<Leader>C", '"_C')
keymap.set("n", "<Leader>d", '"_d')
keymap.set("n", "<Leader>D", '"_D')
keymap.set("v", "<Leader>d", '"_d')
keymap.set("v", "<Leader>D", '"_D')

-- Increment/decrement
keymap.set("n", "+", "<C-a>")
keymap.set("n", "-", "<C-x>")

-- Delete a word backwards
keymap.set("n", "dw", 'vb"_d')

-- -- Select all
-- keymap.set("n", "<C-a>", "gg<S-v>G")

-- Save with root permission (not working for now)
--vim.api.nvim_create_user_command('W', 'w !sudo tee > /dev/null %', {})

-- Disable continuations
keymap.set("n", "<Leader>o", "o<Esc>^Da", opts)
keymap.set("n", "<Leader>O", "O<Esc>^Da", opts)

-- Jumplist forward (Tab below shadows the real <C-i>, so bypass mappings)
keymap.set("n", "<C-m>", function()
	vim.cmd("normal! " .. vim.v.count1 .. "\t")
end, opts)

-- New tab
keymap.set("n", "te", ":tabedit")
keymap.set("n", "<tab>", ":tabnext<Return>", opts)
keymap.set("n", "<s-tab>", ":tabprev<Return>", opts)
-- Split window
keymap.set("n", "ss", ":split<Return>", opts)
keymap.set("n", "sv", ":vsplit<Return>", opts)
-- Move window
keymap.set("n", "sh", "<C-w>h")
keymap.set("n", "sk", "<C-w>k")
keymap.set("n", "sj", "<C-w>j")
keymap.set("n", "sl", "<C-w>l")

-- Resize window
keymap.set("n", "<C-w><left>", "<C-w><")
keymap.set("n", "<C-w><right>", "<C-w>>")
keymap.set("n", "<C-w><up>", "<C-w>+")
keymap.set("n", "<C-w><down>", "<C-w>-")

-- Diagnostics
keymap.set("n", "<C-j>", function()
	vim.diagnostic.goto_next()
end, opts)

keymap.set("n", "<leader>r", function()
	require("craftzdog.hsl").replaceHexWithHSL()
end)

keymap.set("n", "<leader>i", function()
	require("craftzdog.lsp").toggleInlayHints()
end)

vim.api.nvim_create_user_command("ToggleAutoformat", function()
	require("craftzdog.lsp").toggleAutoformat()
end, {})

-- Comfortable ESC mode --
keymap.set("i", "jj", "<Esc>", opts)
keymap.set("i", "jk", "<Esc>", opts)

-- Inc Rename --
keymap.set("n", "<leader>rn", function()
	return ":IncRename " .. vim.fn.expand("<cword>")
end, { expr = true, noremap = true })

-- Pomodoro manager --
require("telescope").load_extension("pomodori")

keymap.set("n", "<leader>ptm", function()
	require("telescope").extensions.pomodori.timers()
end, { desc = "Pomodoro manager" })

keymap.set("n", "<Leader>ptx", function()
	vim.cmd("TimerStop")
end, { desc = "Stop Pomodoro timer" })

keymap.set("n", "<Leader>ptp", function()
	local pomo = require("pomo")
	local timer = pomo.get_latest()
	if timer then
		timer:pause()
		timer:show()
	end
end, { desc = "Pause Pomodoro timer" })

keymap.set("n", "<Leader>ptr", function()
	local pomo = require("pomo")
	local timer = pomo.get_latest()
	if timer then
		timer:resume()
		timer:show()
	end
end, { desc = "Resume Pomodoro timer" })

local pomo_sessions = require("lazy.core.config").plugins["pomo.nvim"].opts.sessions.pomodoro

keymap.set("n", "<Leader>pts", function()
	vim.api.nvim_cmd({ cmd = "TimerStart", args = { pomo_sessions[1].duration, pomo_sessions[1].name } }, {})
end, { desc = "Start " .. pomo_sessions[1].name })

keymap.set("n", "<Leader>ptS", function()
	vim.api.nvim_cmd({ cmd = "TimerStart", args = { pomo_sessions[2].duration, pomo_sessions[2].name } }, {})
end, { desc = "Start " .. pomo_sessions[2].name })

keymap.set("n", "<Leader>ptb", function()
	vim.api.nvim_cmd({ cmd = "TimerStart", args = { pomo_sessions[3].duration, pomo_sessions[3].name } }, {})
end, { desc = "Start " .. pomo_sessions[3].name })

keymap.set("n", "<Leader>ptB", function()
	vim.api.nvim_cmd({ cmd = "TimerStart", args = { pomo_sessions[4].duration, pomo_sessions[4].name } }, {})
end, { desc = "Start " .. pomo_sessions[4].name })

-- Yank --
keymap.set("n", "<Leader>y_", function()
	vim.fn.setreg("+", vim.fn.expand("%:."))
end, { desc = "Yank filename" })
