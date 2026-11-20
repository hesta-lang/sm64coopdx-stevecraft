package.path = "build/transpiled/?.lua;" .. package.path

local PlayerMath = require("net/minecraft/demo/PlayerMath")
local PlayerEntry = require("net/minecraft/demo/PlayerEntry")

assert(PlayerMath.LIMIT == 8.0)
assert(math.abs(PlayerMath.step(4.0) - 6.5) < 0.000001)
assert(PlayerMath.squareRoot(9.0) == 3.0)
assert(PlayerMath.isNotZero(1) == true)
assert(PlayerMath.isNotZero(0) == false)
assert(PlayerEntry.calculate(4.0) == 8.0)

print("SteveCraft Java-to-Lua generated module assertions passed")
