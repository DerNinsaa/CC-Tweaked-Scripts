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
--   1. Chest directly behind turtle at origin.
--   2. Fuel in any slot (coal, lava bucket, etc.).
--   3. Optional: torches in any slot for lighting.
--   4. Optional: Weak Automata upgrade equipped on left or right.

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
    local feLevel = weak.getFuelLevel and weak.getFuelLevel() or "?"
    local feMax   = weak.getMaxFuelLevel and weak.getMaxFuelLevel() or "?"
    print("Weak Automata detected. FE: " .. tostring(feLevel) .. "/" .. tostring(feMax))
else
    print("No Weak Automata - using vanilla dig.")
end

-- Try to charge automata from energy cell in inventory
local function chargeAutomata()
    if not weak then return end
    local level = weak.getFuelLevel()
    local max   = weak.getMaxFuelLevel()
    if level < max * 0.2 then
        print("Low FE (" .. level .. "), charging...")
        weak.chargeTurtle()
    end
end

-- Dig forward: AP first, fall back to vanilla if AP fails or uncharged
local function digFwd()
    if weak then
        chargeAutomata()
        local ok, err = weak.digBlock()
        ap.waitCooldown(weak, "dig")
        if ok then return true end
        -- AP failed (out of FE or no tool) - fall back
    end
    return turtle.dig()
end

-- Dig up: vanilla only (digBlock only faces forward)
local function digUp()
    return turtle.digUp()
end

-- Collect nearby dropped items (AP only, no-op otherwise)
local function collectDrops()
    if weak then
        weak.collectItems()
        ap.waitCooldown(weak, "suck")
    end
end

local function dumpInventory()
    local savedPos  = nav.getPos()
    local savedHead = nav.getHeading()

    nav.goto(0, 0, 0)
    nav.face(2)  -- south: chest is placed behind turtle when facing north at origin
    inv.dropAll({ "minecraft:coal", "minecraft:charcoal", "minecraft:torch" })

    nav.goto(savedPos.x, savedPos.y, savedPos.z)
    nav.face(savedHead)
end

local function mineTunnel(length)
    for i = 1, length do
        inv.ensureFuel(length * 3)

        -- 2-tall shaft: dig forward + above
        while turtle.detect() do
            digFwd()
            os.sleep(0.3)
        end
        turtle.digUp()

        local ok = nav.forward()
        if not ok then
            -- Mob or gravity block fell; retry
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

        if inv.isFull() then
            dumpInventory()
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
    nav.face(2)
    inv.dropAll({ "minecraft:coal", "minecraft:charcoal", "minecraft:torch" })
    print("Done.")
end

run()
