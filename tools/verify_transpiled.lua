package.path = "build/transpiled/?.lua;" .. package.path

local PlayerMath = require("net/minecraft/demo/PlayerMath")
local PlayerEntry = require("net/minecraft/demo/PlayerEntry")
local MC = require("mc_compat")
local Mth = MC.Mth

assert(PlayerMath.LIMIT == 8.0)
assert(math.abs(PlayerMath.step(4.0) - 6.5) < 0.000001)
assert(PlayerMath.squareRoot(9.0) == 3.0)
assert(PlayerMath.isNotZero(1) == true)
assert(PlayerMath.isNotZero(0) == false)
assert(PlayerEntry.calculate(4.0) == 8.0)

-- Minecraft 26.3 Mth parity checks.
assert(Mth.clamp(5, 0, 4) == 4)
assert(Mth.clamp(5, 6, 3) == 3)
assert(Mth.lerp(0.5, 2, 6) == 4)
assert(Mth.sign(-4) == -1 and Mth.sign(0) == 0 and Mth.sign(4) == 1)
assert(Mth.sign(0 / 0) == -1)
assert(Mth.wrapDegrees(190) == -170)
assert(Mth.wrapDegrees(-190) == 170)
assert(Mth.degreesDifference(350, 10) == 20)
assert(Mth.degreesDifferenceAbs(350, 10) == 20)
assert(Mth.rotateIfNecessary(0, 90, 30) == 60)
assert(Mth.approach(2, 10, 3) == 5)
assert(Mth.approach(10, 2, 3) == 7)
assert(Mth.approachDegrees(350, 10, 5) == 355)
assert(Mth.positiveModulo(-3, 2) == 1)
assert(Mth.frac(-1.25) == 0.75)
assert(Mth.square(3) == 9 and Mth.cube(3) == 27)
assert(Mth.equal(1.0, 1.000001))
assert(Mth.clampedLerp(-1, 3, 7) == 3)
assert(Mth.clampedLerp(2, 3, 7) == 7)
assert(Mth.clampedLerp(0.5, 3, 7) == 5)

print("SteveCraft generated modules and Minecraft 26.3 Mth parity assertions passed")
