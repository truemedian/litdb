  return {
    name = "LuauProgrammer/Bloxed",
    version = "0.0.2",
    description = "ROBLOX API Wrapper for the Luvit Runtime Enviroment.",
    tags = { "roblox", "api", "wrapper" },
    license = "MIT",
    author = { name = "LuauProgrammer" },
    homepage = "https://github.com/LuauProgrammer/Bloxed",
    dependencies = {
      'creationix/coro-channel', 
      'creationix/coro-http',    
      'creationix/coro-net',      
      'creationix/coro-wrapper',  
      'creationix/pathjoin',      
      'luvit/http-codec',         
      'luvit/json',              
      'luvit/resource',          
      'luvit/secure-socket'      
    },
    files = {
      "**.lua"
    }
  }
  