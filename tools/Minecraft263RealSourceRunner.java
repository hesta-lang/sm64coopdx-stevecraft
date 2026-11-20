import net.minecraft.util.Mth;
public final class Minecraft263RealSourceRunner {
 private static void number(final String key,final double value){System.out.println(key+"="+Double.toString(value));}
 public static void main(final String[] args){
  number("clamp.normal",Mth.clamp(2.0,0.0,4.0));
  number("clamp.inverted",Mth.clamp(5.0,6.0,3.0));
  number("lerp",Mth.lerp(0.25,2.0,6.0));
  number("clampedLerp.low",Mth.clampedLerp(-1.0,3.0,7.0));
  number("clampedLerp.middle",Mth.clampedLerp(0.5,3.0,7.0));
  number("clampedLerp.high",Mth.clampedLerp(2.0,3.0,7.0));
  number("absMax",Mth.absMax(-7.0,3.0));
  number("square",Mth.square(-3.0));
  number("inverseLerp",Mth.inverseLerp(5.0,0.0,10.0));
  number("clampedMap",Mth.clampedMap(15.0,0.0,10.0,20.0,40.0));
  number("map",Mth.map(15.0,0.0,10.0,20.0,40.0));
  number("lengthSquared3",Mth.lengthSquared(2.0,3.0,6.0));
  number("length3",Mth.length(2.0,3.0,6.0));
  System.out.println("sign.negative="+Mth.sign(-4.0));
  System.out.println("sign.zero="+Mth.sign(-0.0));
  System.out.println("sign.nan="+Mth.sign(Double.NaN));
  System.out.println("equal.near="+Mth.equal(1.0,1.000001));
  System.out.println("equal.far="+Mth.equal(1.0,1.00002));
 }
}
