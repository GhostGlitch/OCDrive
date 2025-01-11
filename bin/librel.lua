local loaded = package.loaded
local defaultPacksList = {
    "_G", "buffer", "text", "transforms", "math", "table", 
    "sh", "process", "serialization", "term", "os", 
    "keyboard", "computer", "vt100", "package", "event", 
    "unicode", "core/cursor", "string", "rc", "shell", 
    "filesystem", "coroutine", "component", "tty"
}

local defaultPacks = {}
for _, key in ipairs(defaultPacksList) do
    defaultPacks[key] = true
end
local keysToReload = {}

for key in pairs(loaded) do
    if not defaultPacks[key] then
        table.insert(keysToReload, key)
    end
end

for _, key in ipairs(keysToReload) do
    loaded[key] = nil
    local _, _, _ = pcall(require, key)
end