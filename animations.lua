-- SteveCraft 64 - Animation system
--
-- Planned clips:
--   idle, walk, run, jump, fall, land, hurt, death
--
-- The character must use a SM64-compatible player armature. The engine's
-- standard player animation set can then animate that armature. Custom
-- Minecraft-style clips will be added after the exported Steve rig is tested.

SteveCraft = SteveCraft or {}

SteveCraft.animations = {
    ready = false,
    rig = "SM64 player-compatible armature",
    clips = {
        "idle",
        "walk",
        "run",
        "jump",
        "fall",
        "land",
        "hurt",
        "death",
    },
}
