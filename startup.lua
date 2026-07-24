-- Startup script. Runs automatically when turtle boots.
-- Adds /lib to require path and prints status.

local libPath = "/" .. fs.getDir(shell.getRunningProgram()) .. "/lib"
if not fs.isDir(libPath) then
    -- Fallback: assume programs live in root
    libPath = "/lib"
end

package.path = package.path .. ";" .. libPath .. "/?.lua"

print("CC:T Turtle Automator")
print("Fuel: " .. tostring(turtle.getFuelLevel()))
print("Programs: mine, farm, fell, stairdive, aedisplay")
print("Type: <program> --help  (coming soon)")
