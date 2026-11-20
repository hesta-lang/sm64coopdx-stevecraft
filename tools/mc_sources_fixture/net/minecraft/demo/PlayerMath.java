package net.minecraft.demo;

import net.minecraft.util.Mth;

public class PlayerMath {
    public static final double LIMIT = 8.0;

    public static double step(double input) {
        double value = Mth.clamp(input, 0.0, LIMIT);
        for (int i = 0; i < 2; i++) {
            value += 0.5;
        }
        if (value > 3.0) {
            value = Mth.lerp(0.5, value, LIMIT);
        }
        return value;
    }

    public static double squareRoot(double input) {
        return Math.sqrt(input);
    }

    public static int unsupportedSwitch(int value) {
        switch (value) {
            case 0: return 1;
            default: return 2;
        }
    }
}
