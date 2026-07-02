-- Tree feller. Chops a single tree from the base up, then replants sapling.
-- Detects logs above and follows the trunk regardless of height.
-- Usage: fell
--
-- Turtle must be facing the tree. Sapling in slot 2, fuel in slot 16.

local nav = require("lib.nav")
local inv = require("lib.inv")

local LOG_PATTERNS = { "log", "wood" }  -- matches most modded wood too

local function isLog(blockData)
    if not blockData then return false end
    for _, pat in ipairs(LOG_PATTERNS) do
        if blockData.name:find(pat, 1, true) then return true end
    end
    return false
end

local function run()
    nav.init()
    inv.ensureFuel(80)

    local ok, blockData = turtle.inspect()
    if not ok or not isLog(blockData) then
        print("No tree detected in front.")
        return
    end

    -- Dig into tree base
    nav.forceForward()
    local height = 1

    -- Climb and chop
    while true do
        local hasAbove, above = turtle.inspectUp()
        if hasAbove and isLog(above) then
            nav.forceUp()
            height = height + 1
        else
            break
        end
    end

    -- Dig any leaves / side logs at top (simple: just chop what's above)
    turtle.digUp()

    -- Descend back to ground
    for _ = 1, height - 1 do
        nav.down()
    end

    -- Replant sapling at base
    turtle.select(2)
    turtle.placeDown()
    turtle.select(1)

    -- Step back to origin
    nav.back()

    print(string.format("Chopped %d-block tree.", height))
end

run()
