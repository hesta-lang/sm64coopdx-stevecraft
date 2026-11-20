import java.util.List;
public final class Minecraft263Reference {
 enum HumanoidArm { LEFT, RIGHT }
 public static String getArm(final HumanoidArm arm){return arm==HumanoidArm.LEFT?"leftArm":"rightArm";}
 private static final float[] SIN=new float[65536];
 static { for(int i=0;i<SIN.length;i++) SIN[i]=(float)Math.sin(i/10430.378350470453); }
 public static float sin(final double i){return SIN[(int)((long)(i*10430.378350470453)&65535L)];}
 public static float cos(final double i){return SIN[(int)((long)(i*10430.378350470453+16384.0)&65535L)];}
 public static float sqrt(final float x){return (float)Math.sqrt(x);}
 public static float rotLerpRad(final float a,final float from,final float to){float diff=to-from;while(diff<(float)-Math.PI)diff+=(float)(Math.PI*2);while(diff>=(float)Math.PI)diff-=(float)(Math.PI*2);return from+a*diff;}
 public static float quadraticArmUpdate(final float x){return -65.0F*x+x*x;}
 public static float clampFloat(final float value,final float min,final float max){return value<min?min:Math.min(value,max);}
 // Source-shaped Java reference for the selected Minecraft 26.3 Mth double overloads.
 public static double mthClamp(final double value,final double min,final double max){return value<min?min:Math.min(value,max);}
 public static double mthLerp(final double alpha1,final double p0,final double p1){return p0+alpha1*(p1-p0);}
 public static double mthClampedLerp(final double factor,final double min,final double max){if(factor<0.0){return min;}else{return factor>1.0?max:mthLerp(factor,min,max);}}
 public static double mthAbsMax(final double a,final double b){return Math.max(Math.abs(a),Math.abs(b));}
 public static boolean mthEqual(final double a,final double b){return Math.abs(b-a)<1.0E-5F;}
 public static int mthSign(final double number){if(number==0.0){return 0;}else{return number>0.0?1:-1;}}
 public static double mthSquare(final double x){return x*x;}
 public static double mthInverseLerp(final double value,final double min,final double max){return (value-min)/(max-min);}
 public static double mthClampedMap(final double value,final double fromMin,final double fromMax,final double toMin,final double toMax){return mthClampedLerp(mthInverseLerp(value,fromMin,fromMax),toMin,toMax);}
 public static double mthMap(final double value,final double fromMin,final double fromMax,final double toMin,final double toMax){return mthLerp(mthInverseLerp(value,fromMin,fromMax),toMin,toMax);}
 public static double mthLengthSquared(final double x,final double y,final double z){return x*x+y*y+z*z;}
 public static double mthLength(final double x,final double y,final double z){return Math.sqrt(mthLengthSquared(x,y,z));}
 public static double mthCube(final double x){return x*x*x;}
 public static double mthFrac(final double number){return number-Math.floor(number);}
 public static double mthApproach(final double current,final double target,final double maxChange){return current+mthClamp(target-current,-maxChange,maxChange);}
 interface RandomSource{int nextInt(int bound);}
 static final class FixedRandom implements RandomSource{private final int index;FixedRandom(final int index){this.index=index;}@Override public int nextInt(final int bound){if(bound<=0||index<0||index>=bound)throw new IllegalArgumentException("bound/index");return index;}}
 static final class Util{static <T>T getRandom(final List<T> list,final RandomSource random){return list.get(random.nextInt(list.size()));}}
 static String getRandomBodyPart(final List<String> parts,final RandomSource random){return Util.getRandom(parts,random);}
 private static void emit(final String key,final float value){System.out.println(key+"="+Float.toString(value));}
 private static void emitDouble(final String key,final double value){System.out.println(key+"="+Double.toString(value));}
 public static void main(final String[] args){
  final double[] angles={0.0,Math.PI/2,-Math.PI/2,1.23456789,123.456789};for(int i=0;i<angles.length;i++){emit("sin."+i,sin(angles[i]));emit("cos."+i,cos(angles[i]));}
  final float[] roots={0.25F,2.0F,9.0F};for(int i=0;i<roots.length;i++)emit("sqrt."+i,sqrt(roots[i]));
  final float[][] rotations={{0.5F,3.0F,-3.0F},{1.0F,0.0F,7.0F},{0.25F,-2.9F,2.9F}};for(int i=0;i<rotations.length;i++)emit("rot."+i,rotLerpRad(rotations[i][0],rotations[i][1],rotations[i][2]));
  final float[] xs={-2.0F,0.0F,0.3F,1.0F,5.0F};for(int i=0;i<xs.length;i++)emit("quadratic."+i,quadraticArmUpdate(xs[i]));
  emit("clamp.0",clampFloat(5.0F,6.0F,3.0F));emit("clamp.1",clampFloat(7.0F,6.0F,3.0F));emit("clamp.2",clampFloat(5.0F,0.0F,4.0F));
  emitDouble("real.clamp.normal",mthClamp(2.0,0.0,4.0));emitDouble("real.clamp.inverted",mthClamp(5.0,6.0,3.0));emitDouble("real.clamp.inverted.high",mthClamp(7.0,6.0,3.0));emitDouble("real.lerp",mthLerp(0.25,2.0,6.0));
  emitDouble("real.clampedLerp.low",mthClampedLerp(-1.0,3.0,7.0));emitDouble("real.clampedLerp.middle",mthClampedLerp(0.5,3.0,7.0));emitDouble("real.clampedLerp.high",mthClampedLerp(2.0,3.0,7.0));
  emitDouble("real.absMax",mthAbsMax(-7.0,3.0));emitDouble("real.square",mthSquare(-3.0));emitDouble("real.inverseLerp",mthInverseLerp(5.0,0.0,10.0));
  emitDouble("real.clampedMap",mthClampedMap(15.0,0.0,10.0,20.0,40.0));emitDouble("real.map",mthMap(15.0,0.0,10.0,20.0,40.0));emitDouble("real.lengthSquared3",mthLengthSquared(2.0,3.0,6.0));emitDouble("real.length3",mthLength(2.0,3.0,6.0));
  emitDouble("real.cube.negative",mthCube(-2.0));emitDouble("real.cube.positive",mthCube(3.0));emitDouble("real.frac.negative",mthFrac(-1.25));emitDouble("real.frac.positive",mthFrac(2.25));
  emitDouble("real.approach.up",mthApproach(2.0,10.0,3.0));emitDouble("real.approach.down",mthApproach(10.0,2.0,3.0));emitDouble("real.approach.reach",mthApproach(2.0,4.0,10.0));
  System.out.println("real.sign.negative="+mthSign(-4.0));System.out.println("real.sign.zero="+mthSign(-0.0));System.out.println("real.sign.nan="+mthSign(Double.NaN));
  System.out.println("real.equal.near="+mthEqual(1.0,1.000001));System.out.println("real.equal.far="+mthEqual(1.0,1.00002));
  System.out.println("arm.0="+getArm(HumanoidArm.LEFT));System.out.println("arm.1="+getArm(HumanoidArm.RIGHT));
  final List<String> parts=List.of("head","body","leftArm","rightArm","leftLeg","rightLeg");final int[] indexes={0,3,5};for(int i=0;i<indexes.length;i++)System.out.println("random."+i+"="+getRandomBodyPart(parts,new FixedRandom(indexes[i])));
 }
}
