-- CJ for SM64CoopDX
-- Version: 0.1.0-alpha
--
-- MarioState remains the only physical player entity. character.lua replaces
-- only the model rendered by marioObj when the CJ DynOS actor is available.

CJMod = CJMod or {}
CJMod.name = "CJ for SM64CoopDX"
CJMod.version = "0.1.0-alpha"

print("[CJ Mod] " .. CJMod.name .. " " .. CJMod.version .. " loaded.")
print("[CJ Mod] Native Mario physics/collision retained; waiting for cj_geo.")
