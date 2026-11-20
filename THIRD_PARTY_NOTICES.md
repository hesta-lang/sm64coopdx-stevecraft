# Third-party notices

## SkyCraft

The triangle collision implementation in `tri_collider.lua` is a Lua adaptation of
`SkyCraft/fabric/src/main/java/dev/skycraft/world/TriCollider.java` and
`SkyTri.java`, pinned at commit `bfcaf17`.

- Project: https://github.com/chasmlol/SkyCraft
- Copyright: chasmlol, 2026
- License: MIT (see [licenses/SkyCraft-LICENSE.txt](licenses/SkyCraft-LICENSE.txt))

## MarioCraft

The SteveCraft collision adapter and its integration are informed by MarioCraft's
SM64/SkyCraft bridge design. This repository does not copy MarioCraft's Windows-only
shared-memory bridge, SM64 core patches, Prism launcher, or Fabric client.

- Project: https://github.com/Boom64dude/MarioCraft
- Copyright: the MarioCraft contributors, 2026
- License: MIT (see [licenses/MarioCraft-LICENSE.txt](licenses/MarioCraft-LICENSE.txt))

## SM64CoopDX

SteveCraft calls documented SM64CoopDX Lua APIs at runtime. It does not copy or modify
SM64CoopDX engine source. SM64CoopDX source code and game data remain under their own terms.
