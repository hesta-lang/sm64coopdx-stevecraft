package net.minecraft.util;
public class Mth {
 public static final float PI=3.14F, HALF_PI=1.57F, TWO_PI=6.28F, DEG_TO_RAD=0.017F, RAD_TO_DEG=57.29F;
 private static final int SIN_QUANTIZATION=65536, SIN_MASK=65535, COS_OFFSET=16384;
 private static final double SIN_SCALE=10430.378350470453;
 private static final float[] SIN=new float[65536];
 public static float clamp(float value,float min,float max){return value;}
 public static double lerp(double delta,double start,double end){return start;}
 public static int sign(double value){return 0;}
 public static float wrapDegrees(float value){return value;}
 public static float absMax(float a,float b){return a;}
 public static float degreesDifference(float a,float b){return a;}
 public static float degreesDifferenceAbs(float a,float b){return a;}
 public static float rotateIfNecessary(float base,float target,float max){return base;}
 public static float approach(float current,float target,float increment){return current;}
 public static float approachDegrees(float current,float target,float increment){return current;}
 public static float positiveModulo(float input,float mod){return input;}
 public static double frac(double value){return value;}
 public static float square(float value){return value;}
 public static float cube(float value){return value;}
 public static boolean equal(double a,double b){return false;}
 public static float clampedLerp(float factor,float min,float max){return min;}
 public static float sin(double value){return 0.0F;}
 public static float cos(double value){return 0.0F;}
 public static float sqrt(float value){return 0.0F;}
 public static float rotLerpRad(float alpha,float from,float to){return from;}
}
