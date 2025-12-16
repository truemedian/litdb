--[[lit-meta
    name = "code-nuage/evasive-page"
    version = "0.0.1"
    homepage = "https://github.com/code-nuage/evasive/blob/main/evasive-page.lua"
    dependencies = {
        "luvit/coro-fs",
        "code-nuage/lustache",
        "code-nuage/direct-mime"
    }
    description = "Page of evasive framework, running on top of direct."
    tags = { "evasive" }
    license = "MIT"
    author = { name = "code-nuage" }
]]

--+              +--
--  evasive-page  --
--  @code-nuage   --
--+              +--

--+ Dependencies +--
local fs = require("coro-fs")
local lu = require("lustache")

local mime = require("direct-mime")

local M = {}

M._NAME = "evasive-page"

--+ direct-router plugin +--
function M.on_load(app)
    app.set_page = function(self, route, component)
        assert(getmetatable(component) == M.component,
            "Argument <component>: Must be a component.")
        self:add_route(route, "GET", function(_, res)
            res
            :set_code(200)
            :set_header("Content-Type", mime["html"])
            :set_body(component:build())
        end)
        return self
    end
end

--+ Component +--
M.base = [[<!DOCTYPE html>
<html lang="{{lang}}">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>{{title}}</title>
        {{styles}}
    </head>
    <body>
        {{templates}}
        {{scripts}}
    </body>
</html>
]]

M.component = {}
M.component.__index = M.component

function M.component.new()
    local i = setmetatable({}, M.component)

    i.lang = "en"
    i.title = "New component"
    i.templates = {}
    i.styles = {}
    i.scripts = {}

    return i
end

--+ Setters +--
function M.component:set_lang(lang)
    assert(type(lang) == "string",
        "Argument <lang>: Must be a string.")
    self.lang = lang
    return self
end

function M.component:set_title(title)
    assert(type(title) == "string",
        "Argument <title>: Must be a string.")
    self.title = title
    return self
end

function M.component:add_style(path)
    assert(type(path) == "string",
        "Argument <path>: Must be a string.")
    table.insert(self.styles, path)
    return self
end

function M.component:add_template(template_path)
    assert(type(template_path) == "string",
        "Argument <template>: Must be a string.")
    local template, err = fs.readFile(template_path)
    if err then
        error(err)
    end
    table.insert(self.templates, template)
    return self
end

function M.component:add_script(path)
    assert(type(path) == "string",
        "Argument <path>: Must be a string.")
    table.insert(self.scripts, path)
    return self
end

--+ Getters +--
function M.component:get_lang()
    return self.lang
end

function M.component:get_title()
    return self.title
end

function M.component:get_styles()
    return self.styles
end

function M.component:get_templates()
    return self.templates
end

function M.component:get_scripts()
    return self.scripts
end

--+ Renderers +--
function M.component:render_styles()
    local styles = ""

    for _, s in ipairs(self:get_styles()) do
        styles = string.format("%s\n<link rel=\"stylesheet\" href=\"%s\">", styles, s)
    end

    return styles
end

function M.component:render_templates()
    local templates = table.concat(self:get_templates())

    return templates
end

function M.component:render_scripts()
    local scripts = ""

    for _, s in ipairs(self:get_scripts()) do
        scripts = string.format("%s\n<script src=\"%s\"></script>", scripts, s)
    end

    return scripts
end

--+ Utils +--
function M.component:add_component(component)
    assert(type(component) == "table" and
        getmetatable(component) == M.component,
        "Argument <component>: Must be a component.")

    for _, style in ipairs(component:get_styles()) do
        table.insert(self.styles, style)
    end

    for _, template in ipairs(component:get_templates()) do
        table.insert(self.templates, template)
    end

    for _, script in ipairs(component:get_scripts()) do
        table.insert(self.scripts, script)
    end

    return self
end

function M.component:build()
    local model = {
        lang = self:get_lang(),
        title = self:get_title(),
        styles = self:render_styles(),
        templates = self:render_templates(),
        scripts = self:render_scripts(),
    }

    return lu.render(M.base, model)
end

return M
