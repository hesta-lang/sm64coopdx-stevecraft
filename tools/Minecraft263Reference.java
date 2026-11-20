import java.util.List;
public final class Minecraft263Reference {
 enum HumanoidArm { LEFT, RIGHT }
 public static String getArm(final HumanoidArm arm){return arm==HumanoidArm.LEFT?"leftArm":"rightArm";}
 private static final float[] SIN=new float[65536];
 static { for(int i=0;i<SIN.length;i++) SIN[i]=(float)Math.sin(i/10430.378350470453); }
 public static float sin(final double i){return SIN[(int)((long)(i*10430.378350470453)&65535L)];}
 public static float cos(final double i){return SIN[(int)((long)(i*10430.378350470453+16384.0)&65535L)];}
 public static float sqrt(final float x){return (float)Math.sqrt(x);}
 public static float rotLerpRad(final float a,final float from,final float to){
  float diff=to-from;
  while(diff<(float)-Math.PI) diff+=(float)(Math.PI*2);
  while(diff>=(float)Math.PI) diff-=(float)(Math.PI*2);
  return from+a*diff;
 }
 public static float quadraticArmUpdate(final float x){return -65.0F*x+x*x;}
 public static float clampFloat(final float value,final float min,final float max){return value<min?min:Math.min(value,max);}
 interface RandomSource{int nextInt(int bound);}
 static final class FixedRandom implements RandomSource{
  private final int index; FixedRandom(final int index){this.index=index;}
  @Override public int nextInt(final int bound){
   if(bound<=0||index<0||index>=bound)throw new IllegalArgumentException("bound/index"); return index;
  }
 }
 static final class Util{
  static <T>T getRandom(final List<T> list,final RandomSource random){return list.get(random.nextInt(list.size()));}
 }
 static String getRandomBodyPart(final List<String> parts,final RandomSource random){return Util.getRandom(parts,random);}
 private static void emit(final String key,final float value){System.out.println(key+"="+Float.toString(value));}
 public static void main(final String[] args){
  final double[] angles={0.0,Math.PI/2,-Math.PI/2,1.23456789,123.456789};
  for(int i=0;i<angles.length;i++){emit("sin."+i,sin(angles[i]));emit("cos."+i,cos(angles[i]));}
  final float[] roots={0.25F,2.0F,9.0F}; for(int i=0;i<roots.length;i++)emit("sqrt."+i,sqrt(roots[i]));
  final float[][] rotations={{0.5F,3.0F,-3.0F},{1.0F,0.0F,7.0F},{0.25F,-2.9F,2.9F}};
  for(int i=0;i<rotations.length;i++)emit("rot."+i,rotLerpRad(rotations[i][0],rotations[i][1],rotations[i][2]));
  final float[] xs={-2.0F,0.0F,0.3F,1.0F,5.0F}; for(int i=0;i<xs.length;i++)emit("quadratic."+i,quadraticArmUpdate(xs[i]));
  emit("clamp.0",clampFloat(5.0F,6.0F,3.0F)); emit("clamp.1",clampFloat(7.0F,6.0F,3.0F)); emit("clamp.2",clampFloat(5.0F,0.0F,4.0F));
  System.out.println("arm.0="+getArm(HumanoidArm.LEFT)); System.out.println("arm.1="+getArm(HumanoidArm.RIGHT));
  final List<String> parts=List.of("head","body","leftArm","rightArm","leftLeg","rightLeg");
  final int[] indexes={0,3,5}; for(int i=0;i<indexes.length;i++)System.out.println("random."+i+"="+getRandomBodyPart(parts,new FixedRandom(indexes[i])));
 }
}
