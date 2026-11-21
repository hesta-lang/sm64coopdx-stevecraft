# Steve: Bedrock-style animation patch

This branch adds animation records to a compatible SM64CoopDX DYNOSBIN actor without rebuilding its geometry.

## What the patcher does

tools/patch_steve_dynos_animations.py:
- Reads the standard DYNOSBIN header (8-byte magic, uncompressed size, zlib payload).
- Preserves the entire decompressed geometry payload byte-for-byte.
- Appends DynOS animation records (DATA_TYPE_ANIMATION, type 8).
- Appends a 256-entry player animation table (DATA_TYPE_ANIMATION_TABLE, type 9).
- Maps Bedrock bone motion onto the 20 animated parts of the mario_geo player rig.

The animation curves are sampled from Mojang's bedrock-samples v1.26.60.5 at https://github.com/Mojang/bedrock-samples/tree/15701fa9c13923f12662984c32c124327e40e3d3, including player move, sneak, swim, crawl, attack, sleeping and riding definitions.

## Included animation mappings

The generated table overrides relevant Mario animation IDs for idle, walk, run, crouch, crawl, swim, attack, riding and sleep. All other IDs remain NULL in the custom table, allowing the model to keep the engine's ordinary animation for unmapped states.

## Run it in GitHub Actions

1. Upload your compatible source binary into this branch, for example assets/steve/minecraft_steve_geo.bin.
2. Open Actions → Patch Steve DynOSBIN with Bedrock-style animations → Run workflow.
3. Set source_path to the uploaded file path.
4. Download the steve-bedrock-dynos-animated artifact.

The workflow also runs the five portable binary-format tests.

## Important fidelity limits

This is not a complete Bedrock animation-controller port. The SM64 player model has 20 animation parts; Bedrock also has independent overlay/item bones and runtime variables. The current clips therefore:
- attach hat, jacket, sleeves and pants motion to their parent body parts;
- do not reproduce bow/crossbow/shield/item-use or first-person item controllers;
- sample query-driven motion into fixed clips instead of evaluating Bedrock queries live;
- keep root-translation channels at zero to avoid moving the rendered model away from Mario's collision/physics object;
- omit dynamic look-at and sleep-bed alignment.

The output is a structurally validated alpha. The model must still be loaded in the Android game to verify joint orientation, visible pose and transitions. Passing Python tests is not an in-game visual test.
