local color = require("pretty-print").colorize

return {
    STARTED = color("table", "(SUCCESS): ").."application started as %s",
    REPLY_BAD_REQUEST = "\n"..color("table", "(ERROR): ").."bad request at message:Reply(content).\nError status code: %s"
}
