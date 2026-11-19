#ifndef STEVECRAFT_MINECRAFT_PLAYER_H
#define STEVECRAFT_MINECRAFT_PLAYER_H

#ifdef __cplusplus
extern "C" {
#endif

#define STEVE_MC_PART_COUNT 13

typedef enum SteveMcPart {
    STEVE_MC_ROOT = 0,
    STEVE_MC_HEAD,
    STEVE_MC_HAT,
    STEVE_MC_BODY,
    STEVE_MC_JACKET,
    STEVE_MC_RIGHT_ARM,
    STEVE_MC_RIGHT_SLEEVE,
    STEVE_MC_LEFT_ARM,
    STEVE_MC_LEFT_SLEEVE,
    STEVE_MC_RIGHT_LEG,
    STEVE_MC_RIGHT_PANTS,
    STEVE_MC_LEFT_LEG,
    STEVE_MC_LEFT_PANTS
} SteveMcPart;

typedef enum SteveMcArmPose {
    STEVE_MC_ARM_EMPTY = 0,
    STEVE_MC_ARM_ITEM = 1,
    STEVE_MC_ARM_BLOCK = 2,
    STEVE_MC_ARM_BOW_AND_ARROW = 3,
    STEVE_MC_ARM_THROW_TRIDENT = 4,
    STEVE_MC_ARM_CROSSBOW_CHARGE = 5,
    STEVE_MC_ARM_CROSSBOW_HOLD = 6,
    STEVE_MC_ARM_SPYGLASS = 7,
    STEVE_MC_ARM_TOOT_HORN = 8,
    STEVE_MC_ARM_BRUSH = 9,
    STEVE_MC_ARM_SPEAR = 10
} SteveMcArmPose;

typedef struct SteveMcHumanoidState {
    float head_pitch_degrees;
    float head_yaw_degrees;
    float walk_animation_position;
    float walk_animation_speed;
    float speed_value;
    float age_in_ticks;
    float swim_amount;
    float attack_time;
    float age_scale;
    float y_offset;

    int is_passenger;
    int is_fall_flying;
    int is_crouching;
    int is_using_item;
    int main_arm_is_right;
    int use_item_hand_is_main;
    int attack_arm_is_right;
    int swing_animation_is_whack;

    SteveMcArmPose left_arm_pose;
    SteveMcArmPose right_arm_pose;
} SteveMcHumanoidState;

/*
 * Fills 13 column-major 4x4 matrices in SM64 actor-local coordinates.
 * The index order is SteveMcPart. Each overlay matrix inherits its base
 * body-part transform (hat/head, jacket/body, sleeves/arms, pants/legs).
 */
void steve_mc_build_sm64_matrices(
    const SteveMcHumanoidState *state,
    float output[STEVE_MC_PART_COUNT][16]
);

/* Minecraft model pixels -> the coordinate convention used by SteveCraft. */
void steve_mc_to_sm64_point(const float minecraft_xyz[3], float sm64_xyz[3]);

#ifdef __cplusplus
}
#endif

#endif
