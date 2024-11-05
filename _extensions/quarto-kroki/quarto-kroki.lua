-- local http = require("socket.http")
-- local fig = 1

function CodeBlock(el)
    -- Obtiene el lenguaje del bloque de código
    local language = el.classes[1] or "plaintext" -- "plaintext" if no language defined
    local text = el.text
    local diagram_kind = "none"

    -- separate the kind of diagram from the codeblock's language name
    if string.sub(language, 1, 6) == "kroki-" then
        diagram_kind = string.sub(language, 7)
    end     

    local args = {
        "https://kroki.io/" .. diagram_kind .. "/svg",
        "--data-raw",
        text
    }

    local output = pandoc.pipe("curl", args, "")
    
    -- os.execute('echo "' .. output .. '" > diagram_1' .. tostring(counter) .. '.svg')
    -- fig = fig + 1
    return pandoc.Para({ pandoc.RawInline("html", output) })
end