local fig = 1

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

    local svg_data = pandoc.pipe("curl", args, "")

    if FORMAT:match 'latex' or FORMAT:match 'beamer' then
        return InsertSvgLatex(svg_data)
    else
        return pandoc.Para({ pandoc.RawInline("html", svg_data) })
    end
end


function InsertSvgLatex(svg_data)
	if not os.exists("assets/") then
		os.mkdir("assets/")
	end
	local file_name = "assets/fig_" .. tostring(fig)
	local file = io.open(file_name .. ".svg",'w')
	file:write(svg_data)
	file:close()
	pandoc.pipe("inkscape", { "--export-type=png", "--export-dpi=300", file_name  .. ".svg" }, "")
	fig = fig + 1
	return pandoc.Para({pandoc.Image({}, file_name  .. ".png")})
end

-- Function taken from: github.com/mokeyish/obsidian-enhancing-export/lua/polyfill.lua
-- https://github.com/mokeyish/obsidian-enhancing-export/blob/16cdb17ef673e822e03e6d270aa33b28079774cc/lua/polyfill.lua
os.mkdir = function(dir)
	if os.exists(dir) then
	  return
	end
	if os.platform == "Windows" then
	  dir = os.text.toencoding(dir)
	  os.execute('mkdir "' .. dir .. '"')
	else
	  os.execute('mkdir -p "' .. dir .. '"')
	end
  end

-- Function taken from: github.com/mokeyish/obsidian-enhancing-export/lua/polyfill.lua
-- https://github.com/mokeyish/obsidian-enhancing-export/blob/16cdb17ef673e822e03e6d270aa33b28079774cc/lua/polyfill.lua
os.exists = function(path)
	if os.platform == "Windows" then
		path = string.gsub(path, "/", "\\")
		path = os.text.toencoding(path)
		local _, _, code = os.execute('if exist "' .. path .. '" (exit 0) else (exit 1)')
		return code == 0
	else
		local _, _, code = os.execute('test -e "' .. path .. '"')
		return code == 0
	end
end