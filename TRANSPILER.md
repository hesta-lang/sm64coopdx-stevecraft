# SteveCraft Java to Lua transpilation

This pipeline belongs to the independent repository hesta-lang/sm64coopdx-stevecraft. It does not add SteveCraft code to the SM64CoopDX source tree and does not build or patch an APK.

## Source provenance

CI resolves NeoForm Runtime 2.0.31 and runs `net.neoforged:neoform:26.3-1@zip` for the joined distribution, writing the `gameSources` result. NeoForm generates Mojang-mapped source from the Minecraft version artifacts and official mappings. CI builds the exact InstallerTools 4.0.17 Maven module with its declared runtime dependencies into the fatjar classifier required by the 26.3 NeoForm graph, then supplies that artifact through NFRT's artifact manifest; it does not substitute an older tool version. The full source archive is temporary; only selected method excerpts and a structured analysis report are uploaded. No full Minecraft source tree, client JAR, textures, or APK changes are committed. The public MC 26.x source browser is a secondary cross-check, not the source input.

## Selected classes and measured coverage

| Class | Source-transpiled methods | Public API coverage |
| --- | --- | ---: |
| `Mth` | 12 selected double-signature methods (listed below) | 12/114 (10.5%) |
| `HumanoidModel` | `getHead`; `getArm`; private `quadraticArmUpdate` | 2/13 |
| `PlayerModel` | `getRandomBodyPart` | 1/5 |

Across the three public API surfaces, 15/132 signatures are source-transpiled (11.4%). The private `quadraticArmUpdate` helper is one additional translated method. This is selected-signature coverage, not full-class translation. The 20 named functions in the manual `MC.Mth` compatibility layer are separate hand-written adapters and are not counted as source-transpiled methods.

The 12 exact Minecraft 26.3 `Mth` signatures selected for extraction are:

- `clamp(double,double,double)`
- `clampedLerp(double,double,double)`
- `absMax(double,double)`
- `equal(double,double)`
- `sign(double)`
- `lerp(double,double,double)`
- `square(double)`
- `inverseLerp(double,double,double)`
- `clampedMap(double,double,double,double,double)`
- `map(double,double,double,double,double)`
- `lengthSquared(double,double,double)`
- `length(double,double,double)`

The extractor selects overloads by parameter types. It emits only one overload for each generated Lua function name; this does not implement general Java overload resolution. The selected double methods avoid pretending Lua numbers preserve Java 32-bit integer overflow or 64-bit long precision. Float-suffixed Java literals are lowered through `MC.java_float` to preserve their IEEE-754 binary32 value before promotion.

`HumanoidModel<T>` extends `EntityModel<T>`, implements `ArmedModel<T>` and `HeadedModel`, and is bounded by `HumanoidRenderState`. Its constructor and model-part fields are inventoried. Its wider API depends on `ModelPart`, `PoseStack`, geometry builders, render types, equipment/arm enums, animation helpers and render-state classes.

`PlayerModel` extends `HumanoidModel<AvatarRenderState>`. Its methods cover geometry creation, armor mesh mapping, animation state, hand transforms and random body-part selection. Only `getRandomBodyPart` is translated. It calls `Util.getRandom(List, RandomSource)`, handled by an explicit adapter that preserves zero-based `RandomSource` selection and maps it to Lua's one-based arrays (or a Java-list-shaped `size/get` adapter).

The CI source report records exact imports, class declarations, inheritance, implemented interfaces, fields, constructors, method names, selected overload signatures and identified engine API calls from the NeoForm archive.

## Converter rules and adapters

The converter fails closed on super calls, object construction, ternary expressions outside one top-level return expression per return statement, lambdas/method references, primitive casts and identified engine APIs without an adapter. A top-level return ternary is lowered to lazy Lua `if/else` branches. Unqualified calls to methods declared in the same extracted class are qualified to that class, which preserves the selected `Mth` dependency chain. It normalizes Java numeric suffixes, preserves `F` literal rounding with `MC.java_float`, and supports package-qualified class filters.

The separate manual compatibility layer contains 20 named `MC.Mth` helpers, including the 65,536-entry sine/cosine lookup table, float sqrt and `rotLerpRad`, plus the float/double `Mth.clamp` helper and `Util.getRandom`. The integer/long overloads of `Mth.clamp` are not covered by that helper. Lua cannot preserve all Java long precision, overflow or every float operation boundary.

There are no adapters yet for `ModelPart`, `PoseStack`, geometry builders, render types, entity state or the SteveCraft runtime. The only Minecraft API adapters used by the selected model methods are the source-identified `Util.getRandom` call and `HumanoidArm.LEFT/RIGHT` enum values; `MC.java_float` is a Java numeric compatibility helper, not an engine adapter.

## Validation boundary

CI runs Python tests, compiles a Java reference harness, compares numeric and method behavior, generates the real 26.3 joined-distribution sources through NeoForm, extracts selected methods, transpiles the excerpts, validates Lua 5.4 syntax, and executes Lua assertions against the Java reference output.

Passing CI validates only this subset and its explicit adapters. It does not prove full `Mth`, `HumanoidModel` or `PlayerModel` translation, constructor/inheritance behavior, or compatibility inside SteveCraft/SM64CoopDX. PR #6 must remain Draft until runtime adapter validation is complete.
