local fig = 1

function CodeBlock(el)
    -- Get the language of the code block
    local language = el.classes[1] or el.identifier or "plaintext" -- "plaintext" if no language defined
    -- Strip curly braces if present
    language = string.gsub(language, "^%{(.+)%}$", "%1")
    
    -- Only process blocks that start with kroki-
    if not string.match(language, "^kroki%-") then
        return el
    end
    
    local text = el.text
    local diagram_kind = string.sub(language, 7)

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

	if os.executable_exists("inkscape") then
		pandoc.pipe("inkscape", { "--export-type=png", "--export-dpi=300", file_name  .. ".svg" }, "")
		fig = fig + 1
		return pandoc.Para({pandoc.Image({}, file_name  .. ".png")})
	else
		print("\nError: Inkscape has to be installed and added to PATH.\n")
		return pandoc.Para({pandoc.Str("Error: Inkscape has to be installed and added to PATH.")})
	end

end


os.platform = function()
    local sep = package.config:sub(1, 1)
    if sep == '\\' then
        return "Windows"
    elseif sep == '/' then
        return "Unix/Linux"
    else
        return "Unknown OS"
    end
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


-- Function modified from: github.com/mokeyish/obsidian-enhancing-export/lua/polyfill.lua
-- https://github.com/mokeyish/obsidian-enhancing-export/blob/16cdb17ef673e822e03e6d270aa33b28079774cc/lua/polyfill.lua
os.exists = function(path)
    local command
	if os.platform == "Windows" then
		path = string.gsub(path, "/", "\\")
		path = os.text.toencoding(path)
		command = 'if exist "' .. path .. '" (exit 0) else (exit 1)'  -- For Windows
	else
		command = 'test -e "' .. path .. '"'  -- For Unix/Linux
	end

    local _, _, code = os.execute(command)
    return code == 0
end


os.executable_exists = function(name)
    local command
    if os.platform == "Windows" then
        command = "where " .. name .. " >nul 2>nul"  -- For Windows
    else
        command = "which " .. name .. " > /dev/null 2>&1"  -- For Unix/Linux
    end

    local _, _, code = os.execute(command)
    return code == 0
end
