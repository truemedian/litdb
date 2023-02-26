return {
    name = "Corotyest/lua-extensions",
    version = "3.0.01-bw",
    description = "Useful functions for the Lua programming language.",
    tags = { "lua", "lit", "luvit" },
    license = "MIT",
    author = { name = "Corotyest", email = "Corotyest@users.noreply.github.com" },
    homepage = "https://github.com/Corotyest/lua-extensions",
    dependencies = {},
    files = {
      "**.lua"
    }
}


-- Please suggest me what more other functions to add!
-- Created utils module and passed all utils functions to it, more clean!
-- Reworked string.extract, and modified string.compare; but this last one isn't finished yet.
-- Plans:
	-- Create a "debugger" that automatically create an error message.
	-- If the function has not documentation manually do it, or somewhat..-
-- Fixed typo in lib `string` ('varag' to 'vararg').
-- Bug fixed and added features to existing functions.
-- Bug fixed invoke thrown an error.

-- Because I have a repository for this concrete package, maybe I'm going to pass this to a dedicated environment.