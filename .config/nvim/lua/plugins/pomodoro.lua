return {
	"epwalsh/pomo.nvim",
	version = "*", -- Recommended, use latest release instead of latest commit
	lazy = true,
	cmd = { "TimerStart", "TimerRepeat", "TimerSession" },
	dependencies = {
		-- Optional, but highly recommended if you want to use the "Default" timer
		"rcarriga/nvim-notify",
	},
	opts = {
		-- See below for full list of options 👇
		notifiers = {
			-- The "Default" notifier uses 'vim.notify' and works best when you have 'nvim-notify' installed.
			{
				name = "Default",
				opts = {
					-- With 'nvim-notify', when 'sticky = true' you'll have a live timer pop-up
					-- continuously displayed. If you only want a pop-up notification when the timer starts
					-- and finishes, set this to false.
					sticky = false,

					-- Configure the display icons:
					title_icon = "⏳",
					text_icon = "⏱️",
				},
			},

			-- You can also define custom notifiers by providing an "init" function instead of a name.
			-- See "Defining custom notifiers" below for an example 👇
			-- { init = function(timer) ... end }
		},
		sessions = {
			pomodoro = {
				{ name = "Focus Session", duration = "45m" },
				{ name = "Short Focus Session", duration = "25m" },
				{ name = "Short Break", duration = "5m" },
				{ name = "Long Break", duration = "8m" },
			},
		},
	},
}
