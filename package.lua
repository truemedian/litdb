return {
    name = "creationix/mpk-serve",
    version = "0.0.4",
    luvi = {
        -- Configure this section for the kind of `lit make` you wish to have.
        -- This first option embeds tiny luvi inside the binary
        flavor = "tiny"
        -- This second option embeds a shebang line pointing to the system luvi
        -- inline = "#!/usr/local/bin/luvi --\n"
    },
    files = {
        "*.lua",
        "libs/*.lua"
    },
    dependencies = {
        "luvit/pretty-print",
        "luvit/require",
        "creationix/coro-fs",
        "creationix/weblit-app",
        "creationix/weblit-logger",
        "creationix/weblit-auto-headers",
        "creationix/blake2s",
        "creationix/mime",
    }
}