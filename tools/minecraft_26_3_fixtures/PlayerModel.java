package net.minecraft.client.model.player;
import net.minecraft.util.Util;
// Minimal Minecraft 26.3 method fixtures; CI refreshes selected bodies from NeoForm gameSources.
public class PlayerModel extends HumanoidModel<AvatarRenderState> {
 private final List<ModelPart> bodyParts;
 private final boolean slim;
 public ModelPart getRandomBodyPart(final RandomSource random) { return Util.getRandom(this.bodyParts,random); }
 public void setupAnim(final AvatarRenderState state) {
  boolean showBody=!state.isSpectator; this.body.visible=showBody; super.setupAnim(state);
 }
 public void translateToHand(final AvatarRenderState state,final HumanoidArm arm,final PoseStack poseStack) {
  this.root().translateAndRotate(poseStack); ModelPart part=this.getArm(arm);
  if(this.slim) { float offset=0.5F*(arm==HumanoidArm.RIGHT?1:-1); part.x+=offset; part.translateAndRotate(poseStack); part.x-=offset; }
  else { part.translateAndRotate(poseStack); }
 }
 public static MeshDefinition createMesh(final CubeDeformation scale,final boolean slim) {
  MeshDefinition mesh=HumanoidModel.createMesh(scale,0.0F); return mesh;
 }
 public static ArmorModelSet<MeshDefinition> createArmorMeshSet(
  final CubeDeformation innerDeformation,final CubeDeformation outerDeformation
 ) {
  return HumanoidModel.createArmorMeshSet(innerDeformation,outerDeformation).map(mesh->{return mesh;});
 }
}
