package net.minecraft.util;
public class Mth {
 public static final float PI=3.1415927F, HALF_PI=1.5707964F, TWO_PI=6.2831855F, DEG_TO_RAD=0.017453292F, RAD_TO_DEG=57.295776F;
 private static final int SIN_QUANTIZATION=65536, SIN_MASK=65535, COS_OFFSET=16384;
 private static final double SIN_SCALE=10430.378350470453;
 private static final float[] SIN=new float[65536];
 public static double clamp(final double value,final double min,final double max) { return Math.max(min,Math.min(max,value)); }
 public static double clampedLerp(final double factor,final double min,final double max) { if(factor<0.0) { return min; } else { return factor>1.0 ? max : lerp(factor,min,max); } }
 public static double absMax(final double a,final double b) { return Math.max(Math.abs(a),Math.abs(b)); }
 public static boolean equal(final double a,final double b) { return Math.abs(b-a)<1.0E-5F; }
 public static int sign(final double number) { if(number==0.0) { return 0; } else { return number>0.0 ? 1 : -1; } }
 public static double lerp(final double alpha1,final double p0,final double p1) { return p0+alpha1*(p1-p0); }
 public static double square(final double x) { return x*x; }
 public static double inverseLerp(final double value,final double min,final double max) { return (value-min)/(max-min); }
 public static double clampedMap(final double value,final double fromMin,final double fromMax,final double toMin,final double toMax) { return clampedLerp(inverseLerp(value,fromMin,fromMax),toMin,toMax); }
 public static double map(final double value,final double fromMin,final double fromMax,final double toMin,final double toMax) { return lerp(inverseLerp(value,fromMin,fromMax),toMin,toMax); }
 public static double lengthSquared(final double x,final double y,final double z) { return x*x+y*y+z*z; }
 public static double length(final double x,final double y,final double z) { return Math.sqrt(lengthSquared(x,y,z)); }
}
