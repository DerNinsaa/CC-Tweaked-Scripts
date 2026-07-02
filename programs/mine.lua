-- Strip miner.
-- Digs parallel tunnels from the starting position.
-- Uses Weak Automata digBlock() if equipped, falls back to turtle.dig().
--
-- Usage: mine <length> [tunnels] [spacing]
--   length  - blocks per tunnel (default 16)
--   tunnels - parallel tunnel count (default 3)
--   spacing - blocks between tunnel centers (default 3)
--
-- Setup:
--   1. Chest directly IN FRONT of turtle (turtle faces chest at start).
--   2. Turtle steps back 1 block before running so chest is at z=-1.
--      OR: place turtle 1 block in front of chest, facing it, then run.
--   3. Fuel in any slot (coal, lava bucket, etc.).
--   4. Optional: torches in any slot for lighting.
--   5. Optional: Weak Automata upgrade equipped on left or right.

package.path = "/?.lua;/?/init.lua;" .. package.path

local nav = require("lib.nav")
local inv = require("lib.inv")
local ap  = require("lib.ap")

local args    = { ... }
local LENGTH  = tonumber(args[1]) or 16
local TUNNELS = tonumber(args[2]) or 3
local SPACING = tonumber(args[3]) or 3

local weak = ap.weakAutomata()
if weak then
    print("Weak Automata detected.")
else
    print("No Weak Automata - using vanilla dig.")
end

-- Dig forward: AP first, fall back to vanilla if AP fails
local function digFwd()
    if weak then
        local ok = weak.digBlock()
        ap.waitCooldown(weak, "dig")
        if ok then return true end
    end
    return turtle.dig()
end

-- Collect nearby dropped items (AP only, no-op otherwise)
local function collectDrops()
    if weak then
        weak.collectItems()
        ap.waitCooldown(weak, "suck")
    end
end

-- Deposit into chest in front at origin, then face away (south) so
-- the next run won't dig into the chest.
local function deposit()
    nav.face(0)  -- face north = face chest
    inv.dropAll({ "minecraft:coal", "minecraft:charcoal", "minecraft:torch" })
    nav.face(2)  -- face south = away from chest, ready to mine
end

local function dumpInventory()
    local savedPos  = nav.getPos()
    local savedHead = nav.getHeading()

    nav.goto(0, 0, 0)
    deposit()

    nav.goto(savedPos.x, savedPos.y, savedPos.z)
    nav.face(savedHead)
end

local function mineTunnel(length)
    for i = 1, length do
        -- Check fuel and inventory BEFORE moving
        inv.ensureFuel(length * 3)
        if inv.isFull() then
            dumpInventory()
        end

        -- 2-tall shaft: dig forward + above
        while turtle.detect() do
            digFwd()
            os.sleep(0.3)
        end
        turtle.digUp()

        local ok = nav.forward()
        if not ok then
            digFwd()
            nav.forward()
        end

        collectDrops()

        -- Torch every 8 blocks
        if i % 8 == 0 then
            if inv.selectItem("torch") then
                turtle.placeDown()
                turtle.select(1)
            end
        end
    end
end

local function run()
    nav.init()

    local fuelNeeded = LENGTH * TUNNELS * SPACING * 2 + LENGTH * TUNNELS
    inv.ensureFuel(fuelNeeded)

    print(string.format("Strip miner: %d tunnels x %d blocks, spacing %d", TUNNELS, LENGTH, SPACING))

    for t = 1, TUNNELS do
        print(string.format("Tunnel %d/%d", t, TUNNELS))

        local startX = (t - 1) * SPACING
        nav.goto(startX, 0, 0)
        nav.face(0)  -- north

        mineTunnel(LENGTH)
    end

    print("Returning to origin...")
    nav.goto(0, 0, 0)
    deposit()
    print("Done.")
end

run()
