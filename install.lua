-- One-shot installer.
-- Edit BASE_URL to your GitHub raw content base, then:
--   1. Upload this file to pastebin
--   2. In-game: wget <pastebin_url> install.lua
--   3. In-game: lua install.lua
--
local BASE_URL = "https://raw.githubusercontent.com/DerNinsaa/CC-Tweaked-Scripts/main/"

local FILES = {
    "lib/nav.lua",
    "lib/inv.lua",
    "lib/ap.lua",
    "lib/ae.lua",
    "programs/mine.lua",
    "programs/farm.lua",
    "programs/fell.lua",
    "programs/stairdive.lua",
    "programs/aedisplay.lua",
    "startup.lua",
}

local function download(path)
    local url = BASE_URL .. path
    local dir = fs.getDir(path)
    if dir ~= "" and not fs.isDir(dir) then
        fs.makeDir(dir)
    end
    if fs.exists(path) then fs.delete(path) end

    local res = http.get(url)
    if not res then
        print("[FAIL] " .. path)
        return false
    end
    local f = fs.open(path, "w")
    f.write(res.readAll())
    f.close()
    res.close()
    print("[OK]   " .. path)
    return true
end

print("Installing CC:T Turtle Automator...")
print("Base: " .. BASE_URL)
print()

local ok, fail = 0, 0
for _, path in ipairs(FILES) do
    if download(path) then ok = ok + 1 else fail = fail + 1 end
end

print()
print(string.format("Done. %d ok, %d failed.", ok, fail))
if fail == 0 then
    print("Run: startup")
end
