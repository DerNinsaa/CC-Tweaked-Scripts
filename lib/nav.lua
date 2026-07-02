-- Turtle navigation with position + heading tracking.
-- Wraps turtle API so moves update internal state.
-- Origin (0,0,0) is wherever turtle is when nav.init() is called.
-- Heading: 0=north(+z), 1=east(+x), 2=south(-z), 3=west(-x) ... wait
-- CC axes: north = -z, south = +z, east = +x, west = -x
-- Heading: 0=north, 1=east, 2=south, 3=west

local nav = {}

local pos = { x = 0, y = 0, z = 0 }
local heading = 0  -- 0=north(-z), 1=east(+x), 2=south(+z), 3=west(-x)

local DX = { 0, 1, 0, -1 }
local DZ = { -1, 0, 1, 0 }

function nav.init()
    pos = { x = 0, y = 0, z = 0 }
    heading = 0
end

function nav.getPos()
    return { x = pos.x, y = pos.y, z = pos.z }
end

function nav.getHeading()
    return heading
end

local function step(dx, dz)
    pos.x = pos.x + dx
    pos.z = pos.z + dz
end

function nav.forward()
    local ok, err = turtle.forward()
    if ok then step(DX[heading + 1], DZ[heading + 1]) end
    return ok, err
end

function nav.back()
    local ok, err = turtle.back()
    if ok then step(-DX[heading + 1], -DZ[heading + 1]) end
    return ok, err
end

function nav.up()
    local ok, err = turtle.up()
    if ok then pos.y = pos.y + 1 end
    return ok, err
end

function nav.down()
    local ok, err = turtle.down()
    if ok then pos.y = pos.y - 1 end
    return ok, err
end

function nav.turnLeft()
    local ok, err = turtle.turnLeft()
    if ok then heading = (heading - 1) % 4 end
    return ok, err
end

function nav.turnRight()
    local ok, err = turtle.turnRight()
    if ok then heading = (heading + 1) % 4 end
    return ok, err
end

-- Turn to face absolute heading (0-3)
function nav.face(target)
    local diff = (target - heading) % 4
    if diff == 1 then
        nav.turnRight()
    elseif diff == 2 then
        nav.turnRight()
        nav.turnRight()
    elseif diff == 3 then
        nav.turnLeft()
    end
end

-- Dig forward, retrying if a mob is in the way
function nav.digForward()
    while turtle.detect() do
        if not turtle.dig() then return false end
        os.sleep(0.4)
    end
    return true
end

function nav.digUp()
    while turtle.detectUp() do
        if not turtle.digUp() then return false end
        os.sleep(0.4)
    end
    return true
end

function nav.digDown()
    while turtle.detectDown() do
        if not turtle.digDown() then return false end
        os.sleep(0.4)
    end
    return true
end

-- Move forward, digging if blocked
function nav.forceForward()
    nav.digForward()
    local ok, err = nav.forward()
    return ok, err
end

function nav.forceUp()
    nav.digUp()
    return nav.up()
end

function nav.forceDown()
    nav.digDown()
    return nav.down()
end

-- Go to position relative to init point. Digs through blocks.
-- Order: Y first (to avoid surface collision), then X, then Z.
function nav.goto(tx, ty, tz)
    -- Vertical
    while pos.y < ty do nav.forceUp() end
    while pos.y > ty do nav.forceDown() end

    -- East/West (X axis)
    if pos.x < tx then
        nav.face(1)  -- east
        while pos.x < tx do nav.forceForward() end
    elseif pos.x > tx then
        nav.face(3)  -- west
        while pos.x > tx do nav.forceForward() end
    end

    -- North/South (Z axis)
    if pos.z < tz then
        nav.face(2)  -- south
        while pos.z < tz do nav.forceForward() end
    elseif pos.z > tz then
        nav.face(0)  -- north
        while pos.z > tz do nav.forceForward() end
    end
end

return nav
