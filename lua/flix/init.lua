local M = {}

function M.setup(user_config)
	local config = vim.tbl_deep_extend("force", {
		flix_jar_path = "flix.jar", -- Default path to flix.jar
		enable_codelens = true,
	}, user_config or {})

	local lspconfig = require("lspconfig")
	local configs = require("lspconfig.configs")
	local start_cmd = { "java", "-jar", config.flix_jar_path, "lsp" }

	vim.filetype.add({ extension = { flix = "flix" } })

	-- Register the Flix LSP configuration
	if not configs.flix then
		configs.flix = {
			default_config = {
				cmd = start_cmd,
				filetypes = { "flix" },
				root_dir = function(fname)
				  local current_dir = vim.loop.cwd()
					-- Use the current directory if flix.jar is found here
					if vim.loop.fs_stat(vim.fs.joinpath(current_dir, config.flix_jar_path)) then
						return current_dir
					end
					-- Otherwise, search for flix.toml in the parent directories, with a fallback to the current directory
					local root_dir = vim.fs.dirname(vim.fs.find("flix.toml", { path = fname, upward = true })[1])
						or vim.loop.cwd()
					local flix_jar_path = vim.fs.joinpath(root_dir, config.flix_jar_path)
					-- Make sure flix.jar is found in the root directory, otherwise return nil to prevent the LSP server from starting
					if vim.loop.fs_stat(flix_jar_path) == nil then
						print(
							"Failed to start the LSP server: flix.jar not found in project root (" .. root_dir .. ")!"
						)
						return nil
					end
					return root_dir
				end,
				settings = {},
			},
		}
	end

	-- Setup the Flix server
	lspconfig.flix.setup({
		capabilities = vim.lsp.protocol.make_client_capabilities(),
		on_attach = function(client, bufnr)
			if config.enable_codelens then
				-- Register the Flix run command
				client.commands["flix.runMain"] = function(_, _)
					vim.cmd("split | terminal java -jar " .. config.flix_jar_path .. " run")
				end
			end
		end,
		flags = {},
	})
end

return M
