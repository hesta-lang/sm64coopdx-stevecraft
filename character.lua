-- SteveCraft 64 - Character registration
--
-- The player model must be exported to the DynOS geometry format before it
-- can be registered with smlua_model_util_get_id().
-- See MODEL_PIPELINE.md. The OBJ in assets/steve is source geometry only.

SteveCraft = SteveCraft or {}

SteveCraft.character = {
    geoName = "steve_geo",
    actorBinary = "actors/steve_geo.bin",
    registered = false,
    ready = false,
}

-- Deliberately do not assign a model ID yet: the compiled actor binary is not
-- in this repository. Calling the model lookup before the asset exists would
-- risk assigning an invalid extended model ID to player objects.
