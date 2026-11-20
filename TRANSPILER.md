# SteveCraft Java to Lua transpilation

This pipeline belongs to the independent repository hesta-lang/sm64coopdx-stevecraft. It does not add SteveCraft code to the SM64CoopDX source tree and does not build or patch an APK.

## Source provenance

CI resolves NeoForm Runtime 2.0.31 and runs net.neoforged:neoform:26.3-1@zip for the joined distribution, writing the gameSources result. NeoForm generates mapped source from Mojang's version artifacts and official mappings. CI builds the exact InstallerTools 4.0.17 Maven module with its declared runtime dependencies into the fatjar classifier required by the 26.3 NeoForm graph, then supplies that artifact through NFRT's artifact manifest; it does not substitute an older tool version. The full source archive is temporary; only selected method excerpts and a structured analysis report are uploaded. No full Minecraft source tree, client JAR, textures, or APK changes are committed. The public MC 26.x source browser is a secondary cross-check, not the source input.

## Selected classes and coverage

| Class | Translated methods | Public API coverage |
| --- | --- | ---: |
| HumanoidModel | getHead; private quadraticArmUpdate | 1/13 |
| PlayerModel | getRandomBodyPart | 1/5 |

Across the two listed public API surfaces, 2/18 methods are translated (11.1%). The private quadraticArmUpdate helper is counted separately. This is selected-method coverage, not full-class translation.

HumanoidModel<T> extends EntityModel<T>, implements ArmedModel<T> and HeadedModel, and is bounded by HumanoidRenderState. Its constructor and model-part fields are inventoried. Its wider API depends on ModelPart, PoseStack, geometry builders, render types, equipment/arm enums, animation helpers and render-state classes.

PlayerModel extends HumanoidModel<AvatarRenderState>. Its methods cover geometry creation, armor mesh mapping, animation state, hand transforms and random body-part selection. Only getRandomBodyPart is currently translated. It calls Util.getRandom(List, RandomSource), handled by an explicit adapter that preserves zero-based RandomSource selection and maps it to Lua's one-based arrays (or a Java-list-shaped size/get adapter).

The CI source report records exact imports, class declarations, inheritance, implemented interfaces, fields, constructors, method names and identified engine API calls from the NeoForm archive.

## Converter rules and adapters

The converter fails closed on super calls, object construction, ternary expressions, lambdas/method references, primitive casts and identified engine APIs without an adapter. Unsupported methods are omitted and reported rather than approximated. It also normalizes Java floating-point suffixes and supports package-qualified class filters.

The explicit compatibility layer contains 20 named Mth helpers, including the 65,536-entry sine/cosine lookup table, float sqrt and rotLerpRad, plus the float/double Mth.clamp overload and Util.getRandom. Mth.clamp has distinct int/long and float/double overloads; overload resolution is not implemented, so int/long calls are not covered. fastFloor was removed because it is not in the 26.3 Mth API surface. Lua cannot preserve all Java long precision, overflow or every float rounding boundary.

There are no adapters yet for ModelPart, PoseStack, geometry builders, render types, entity state or the SteveCraft runtime.

## Validation boundary

CI runs Python tests, compiles a Java reference harness, compares numeric and method behavior, generates the real 26.3 joined-distribution sources through NeoForm, extracts selected methods, transpiles those excerpts, validates Lua 5.4 syntax, and executes Lua assertions.

Passing CI validates only this subset and its explicit adapters. It does not prove full HumanoidModel/PlayerModel translation, constructor/inheritance behavior, or compatibility inside SteveCraft/SM64CoopDX. PR #6 must remain Draft until runtime adapter validation is complete.
