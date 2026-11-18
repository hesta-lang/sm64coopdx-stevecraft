-- SteveCraft 64 - Player animation support
--
-- The generated Steve actor keeps the SM64CoopDX player skeleton and bone
-- names. This lets the engine's existing player animation set drive Steve:
-- idle, walk, run, jump, fall, land, hurt and death.
--
-- Custom Minecraft-specific animation clips are not registered yet. They
-- will be introduced separately after the model is checked in Android.

SteveCraft = SteveCraft or {}

SteveCraft.animations = {
    ready = true,
    source = "SM64CoopDX built-in player animation set",
    customClipsReady = false,
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
