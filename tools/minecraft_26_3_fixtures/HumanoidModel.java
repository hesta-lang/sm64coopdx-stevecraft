package net.minecraft.client.model;
import net.minecraft.world.entity.HumanoidArm;
// Minimal Minecraft 26.3 method fixtures; CI refreshes selected bodies from NeoForm gameSources.
public class HumanoidModel<T extends HumanoidRenderState> extends EntityModel<T> {
 public final ModelPart head;
 public final ModelPart leftArm;
 public final ModelPart rightArm;
 public ModelPart getHead() { return this.head; }
 private float quadraticArmUpdate(final float x) { return -65.0F*x+x*x; }
 public ModelPart getArm(final HumanoidArm arm) { return arm==HumanoidArm.LEFT?this.leftArm:this.rightArm; }
 public void setupAnim(final T state) { super.setupAnim(state); }
 public static MeshDefinition createMesh(final CubeDeformation g,final float yOffset) {
  MeshDefinition mesh=new MeshDefinition(); return mesh;
 }
}
