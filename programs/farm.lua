-- Wheat/carrot/potato/beetroot farm harvester.
-- Turtle walks a grid, harvests mature crops, replants seeds.
-- Usage: farm <width> <depth>
--   width - number of columns (turtle moves along rows of this length)
--   depth - number of rows
--
-- Setup:
--   1. Place turtle at corner of farm, facing along width direction.
--   2. Put seeds in slot 1 (wheat seeds, carrots, or potatoes).
--   3. Put fuel in slot 16.
--   4. Optionally: chest directly behind turtle for output.
--
-- Turtle serpentines: row 1 forward, turn, row 2 back, turn, ...

local nav = require("lib.nav")
local inv = require("lib.inv")

local args = { ... }
local WIDTH = tonumber(args[1]) or 9
local DEPTH = tonumber(args[2]) or 9

-- Crop maturity detection by checking if block is a crop at max age
local MATURE_CROPS = {
    ["minecraft:wheat"]     = { maxAge = 7 },
    ["minecraft:carrots"]   = { maxAge = 7 },
    ["minecraft:potatoes"]  = { maxAge = 7 },
    ["minecraft:beetroots"] = { maxAge = 3 },
}

local function isMature(blockData)
    if not blockData then return false end
    local crop = MATURE_CROPS[blockData.name]
    if not crop then return false end
    local state = blockData.state
    return state and state.age ~= nil and state.age >= crop.maxAge
end

local function harvestAndReplant()
    local ok, blockData = turtle.inspectDown()
    if ok and isMature(blockData) then
        turtle.digDown()
        -- Replant: seed should be in slot 1
        turtle.select(1)
        turtle.placeDown()
    end
end

local function dumpToChest()
    -- Chest is behind origin; navigate home and drop
    local p = nav.getPos()
    local h = nav.getHeading()
    nav.goto(0, 0, 0)
    nav.face(2)
    -- Drop everything except slot 1 (seeds)
    for i = 2, 16 do
        if turtle.getItemCount(i) > 0 then
            turtle.select(i)
            turtle.drop()
        end
    end
    turtle.select(1)
    nav.goto(p.x, p.y, p.z)
    nav.face(h)
end

local function run()
    nav.init()
    inv.ensureFuel(WIDTH * DEPTH * 2 + DEPTH)

    print(string.format("Farming %dx%d plot", WIDTH, DEPTH))

    for row = 0, DEPTH - 1 do
        local forward = (row % 2 == 0)

        for col = 0, WIDTH - 1 do
            harvestAndReplant()

            if inv.freeSlots() < 2 then
                dumpToChest()
            end

            -- Move along row (except last cell)
            if col < WIDTH - 1 then
                nav.forceForward()
            end
        end

        -- Turn to next row (serpentine)
        if row < DEPTH - 1 then
            if forward then
                nav.turnRight()
                nav.forceForward()
                nav.turnRight()
            else
                nav.turnLeft()
                nav.forceForward()
                nav.turnLeft()
            end
        end
    end

    -- Return home
    print("Returning to origin...")
    nav.goto(0, 0, 0)
    nav.face(0)
    dumpToChest()
    print("Farm run complete.")
end

run()
