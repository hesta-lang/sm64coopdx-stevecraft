# SteveCraft Java to Lua transpilation

This pipeline belongs to the independent repository hesta-lang/sm64coopdx-stevecraft. It does not add SteveCraft code to the SM64CoopDX source tree and does not build or patch an APK.

## Purpose

Translate a deliberately limited subset of Minecraft Java source into Lua 5.4 modules that can be adapted for the SteveCraft mod. The converter is conservative: if a method contains unsupported syntax, it omits that entire method and records the reason in transpile-report.json. It does not emit guessed code.

## Run

    python3 tools/java_to_lua.py \
      --input /path/to/minecraft-java-sources \
      --output build/minecraft-lua \
      --version 26.3

Select individual classes with repeatable --class fully.qualified.ClassName arguments. Use --strict in CI or review builds to fail when a selected class has skipped methods or files.

Generated package directories preserve Java package names. Imported project classes become Lua require() calls. mc_compat.lua contains only the small Minecraft Mth functions implemented so far; engine-facing classes still need explicit adapters to SM64CoopDX APIs.

## Current supported subset

- Top-level Java classes and primitive/simple-reference method signatures.
- Static final scalar constants and simple local declarations.
- Arithmetic, comparisons, boolean expressions, Math calls, and the listed Mth mappings.
- if/else, while, simple constant-bound numeric for loops, return, and break.
- Imports of other simple project classes and calls between generated modules.

## Not supported / not yet equivalent

Constructors and object lifecycle, inheritance and virtual dispatch, interfaces/generics, nested/anonymous classes, overload resolution, Java arrays and collections, lambdas/streams, switch, exceptions, reflection, synchronization, native methods, and engine rendering/entity/world systems are not translated. Unsupported methods are reported and omitted.

Lua 5.4 has one general numeric type; this pipeline does not preserve Java long precision, integer overflow, exact narrowing-cast behavior, or all Java integer-division edge cases. The report emits warnings for casts and division. Such operations need explicit adapters or hand-written ports, then semantic tests.

## Source and validation boundary

The repository does not bundle Minecraft source code, JARs, game assets, or generated Minecraft-derived modules. Provide a legally obtained source tree locally to the command. The committed Java files are synthetic fixtures only. GitHub Actions validates the converter against those fixtures; this is not yet evidence that an entire Minecraft 26.3 source tree can be translated or that generated modules work inside the game. Each translated subsystem must pass adapter-level tests before it is enabled in SteveCraft.
