return {
	config = function()
		local presence = require("presence")
		presence:setup({
			-- Enable debug logs.
			log_level = nil,
			-- function(buffer: string, repo_url: string | nil): table
			buttons = function(_buffer, repo_url)
				local button = {
					label = "GitHub Profile",
					url = "https://github.com/bryan-hoang",
				}

				if repo_url ~= nil and repo_url:match("dotfiles") then
					button.label = "Workflow/Ricing"
					button.url = "https://www.reddit.com/r/unixporn/"
				end

				return { button }
			end,
		})
	end,
}
