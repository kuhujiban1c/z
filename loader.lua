-- loader.lua
local baseURL = "https://github.com/kuhujiban1c/z/blob/main"

local files = {
    "core.lua",
    "ui.lua",
    "movement.lua",
    "visual.lua",
    "world.lua",
    "utility.lua",
    -- tambahkan file lain
}

for _, file in ipairs(files) do
    local success, err = pcall(function()
        local code = game:HttpGet(baseURL .. file)
        loadstring(code)()
    end)
    if not success then
        warn("Gagal load " .. file .. ": " .. err)
    end
end
