#!/usr/bin/env python3
"""Build a Java reference harness from the selected, source-extracted model methods."""
from __future__ import annotations
import argparse
from pathlib import Path
from extract_minecraft_26_3 import find_method

METHODS = {
    "HumanoidModel": ("getHead", "getArm", "quadraticArmUpdate"),
    "PlayerModel": ("getRandomBodyPart",),
}

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    extracted = {}
    for class_name, names in METHODS.items():
        if class_name == "HumanoidModel":
            path = args.input / "net/minecraft/client/model/HumanoidModel.java"
        else:
            path = args.input / "net/minecraft/client/model/player/PlayerModel.java"
        if not path.is_file():
            parser.error("missing extracted source wrapper: " + str(path))
        source = path.read_text(encoding="utf-8")
        extracted[class_name] = [find_method(source, name)[0] for name in names]

    humanoid_methods = "\n\n".join(
        "        " + method.replace("\n", "\n        ")
        for method in extracted["HumanoidModel"]
    )
    player_methods = "\n\n".join(
        "        " + method.replace("\n", "\n        ")
        for method in extracted["PlayerModel"]
    )
    output = """import java.util.List;

// Test shell only: method bodies below are copied from the NeoForm-extracted
// Minecraft 26.3 source wrappers. Engine dependencies are minimal test doubles.
public final class Minecraft263ModelReferenceRunner {
    enum HumanoidArm { LEFT, RIGHT }

    static final class ModelPart {
        final String id;
        ModelPart(String id) { this.id = id; }
    }

    interface RandomSource {
        int nextInt(int bound);
    }

    static final class FixedRandom implements RandomSource {
        private final int index;
        FixedRandom(int index) { this.index = index; }
        public int nextInt(int bound) {
            if (bound <= 0 || index < 0 || index >= bound) {
                throw new IllegalArgumentException("index outside bound");
            }
            return index;
        }
    }

    static final class Util {
        static <T> T getRandom(List<T> values, RandomSource random) {
            return values.get(random.nextInt(values.size()));
        }
    }

    static final class HumanoidModel {
        ModelPart head;
        ModelPart leftArm;
        ModelPart rightArm;

__HUMANOID_METHODS__
    }

    static final class PlayerModel {
        List<ModelPart> bodyParts;

__PLAYER_METHODS__
    }

    private static void emit(String key, Object value) {
        System.out.println(key + "=" + value);
    }

    public static void main(String[] args) {
        HumanoidModel humanoid = new HumanoidModel();
        humanoid.head = new ModelPart("head");
        humanoid.leftArm = new ModelPart("leftArm");
        humanoid.rightArm = new ModelPart("rightArm");
        emit("model.head", humanoid.getHead().id);
        emit("model.arm.left", humanoid.getArm(HumanoidArm.LEFT).id);
        emit("model.arm.right", humanoid.getArm(HumanoidArm.RIGHT).id);

        float[] values = {-2.0F, 0.0F, 0.3F, 1.0F, 5.0F};
        for (int i = 0; i < values.length; i++) {
            emit("model.quadratic." + i, humanoid.quadraticArmUpdate(values[i]));
        }

        PlayerModel player = new PlayerModel();
        player.bodyParts = List.of(
            new ModelPart("head"), new ModelPart("body"),
            new ModelPart("leftArm"), new ModelPart("rightArm"),
            new ModelPart("leftLeg"), new ModelPart("rightLeg")
        );
        int[] indexes = {0, 3, 5};
        for (int i = 0; i < indexes.length; i++) {
            emit("model.random." + i,
                player.getRandomBodyPart(new FixedRandom(indexes[i])).id);
        }
    }
}
"""
    output = output.replace("__HUMANOID_METHODS__", humanoid_methods)
    output = output.replace("__PLAYER_METHODS__", player_methods)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(output, encoding="utf-8")
    print("Generated Java model reference harness from extracted method bodies:", args.output)
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
