-- Staircase miner: 3 wide, 5 tall descending shaft.
-- Every 16 blocks of descent mines a 5x5x5 landing room.
-- Usage: stairdive [depth]
--   depth = blocks to descend from start (default 100)
--
-- Setup: chest directly in front of turtle (same as mine.lua).

package.path = "/?.lua;/?/init.lua;" .. package.path

local nav = require("lib.nav")
local inv = require("lib.inv")
local ap  = require("lib.ap")

local args          = { ... }
local DEPTH         = tonumber(args[1]) or 100
local ROOM_INTERVAL = 16
local ROOM_SIZE     = 5

-- Forward/right direction vectors by heading (north=0, east=1, south=2, west=3)
local FX = { 0, 1, 0, -1 }
local FZ = { -1, 0, 1, 0 }
local RX = { 1, 0, -1, 0 }
local RZ = { 0, 1, 0, -1 }

local weak = ap.weakAutomata()
if weak then print("Weak Automata detected.") else print("Vanilla dig.") end

local function digFwd()
    if weak then
        local ok = weak.digBlock()
        ap.waitCooldown(weak, "dig")
        if ok then return true end
    end
    return turtle.dig()
end

-- Clear 5-tall column at current position.
-- Physically moves up 4 blocks digging, then returns down.
local function clearColumn()
    for i = 1, 4 do nav.forceUp() end
    for i = 1, 4 do nav.forceDown() end
end

-- Mine 3-wide x 5-tall cross-section at current position.
-- Turtle at floor level, heading unchanged after call.
local function mineSection()
    clearColumn()

    nav.turnLeft()
    nav.forceForward()
    clearColumn()
    nav.back()
    nav.turnRight()

    nav.turnRight()
    nav.forceForward()
    clearColumn()
    nav.back()
    nav.turnLeft()
end

-- Single staircase step: mine cross-section, advance, descend.
local function staircaseStep()
    mineSection()
    nav.forceForward()
    nav.forceDown()
end

-- Mine a 5x5x5 room at current position.
-- Entry = turtle's current pos (floor, center). Exits at far wall, same Y, same heading.
local function mineRoom()
    print("Room at Y=" .. nav.getPos().y)
    inv.ensureFuel(ROOM_SIZE * ROOM_SIZE * ROOM_SIZE * 2)

    local entry = nav.getPos()
    local head  = nav.getHeading()
    local fx = FX[head + 1]; local fz = FZ[head + 1]
    local rx = RX[head + 1]; local rz = RZ[head + 1]

    -- Visit every cell: nav.goto digs its way to each position, clearing it.
    for dy = 0, ROOM_SIZE - 1 do
        for df = 0, ROOM_SIZE - 1 do
            for dr = -2, 2 do
                nav.goto(
                    entry.x + df * fx + dr * rx,
                    entry.y + dy,
                    entry.z + df * fz + dr * rz
                )
            end
        end
    end

    -- Return to far wall at floor level, facing original heading.
    nav.goto(
        entry.x + (ROOM_SIZE - 1) * fx,
        entry.y,
        entry.z + (ROOM_SIZE - 1) * fz
    )
    nav.face(head)
end

local function deposit()
    nav.face(0)
    inv.dropAll({ "minecraft:coal", "minecraft:charcoal", "minecraft:torch" })
    nav.face(2)
end

local function returnAndDeposit()
    local p = nav.getPos()
    local h = nav.getHeading()
    nav.goto(0, 0, 0)
    deposit()
    nav.goto(p.x, p.y, p.z)
    nav.face(h)
end

local function run()
    nav.init()
    inv.ensureFuel(DEPTH * 8)
    print(string.format("Staircase mine: %d blocks deep, room every %d", DEPTH, ROOM_INTERVAL))

    local depth = 0

    while depth < DEPTH do
        inv.ensureFuel(100)
        if inv.isFull() then returnAndDeposit() end

        if depth > 0 and depth % ROOM_INTERVAL == 0 then
            mineRoom()
        end

        staircaseStep()
        depth = depth + 1
    end

    print("Depth reached. Returning...")
    nav.goto(0, 0, 0)
    deposit()
    print("Done.")
end

run()
