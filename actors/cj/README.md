# CJ DynOS actor

Expected runtime GeoLayout name: \`cj_geo\`.

Place the CJ actor's SM64CoopDX DynOS source in this folder. The model must be built for the **native SM64 player armature**, not exported as a free-standing object.

## Required structure

The CJ mesh must be attached to the same animated player hierarchy as the base SM64CoopDX character:
- root / player transform
- torso and head branches
- left and right arm branches
- left and right leg branches
- the expected animated-part ordering used by the player animation table

The model swap does not create or animate a new physical entity. SM64CoopDX continues to drive the player armature with its normal animation states, movement, collision and interactions.

## Resource naming

The Lua module looks up the model with:

\`smlua_model_util_get_id("cj_geo")\`

The exported GeoLayout must therefore be registered under \`cj_geo\`. Keep textures/materials referenced by the DynOS model inside this actor folder or in a documented adjacent resource folder.

## Asset status

No CJ model, DFF, TXD, or converted DynOS geometry is included yet. Do not place a placeholder Mario model here and rename it CJ: it would only disguise the missing asset. Add a legally obtained model that you have permission to use, then export/rig it for the native player armature.
