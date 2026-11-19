#ifndef STEVECRAFT_MINECRAFT_PHYSICS_H
#define STEVECRAFT_MINECRAFT_PHYSICS_H

#ifdef __cplusplus
extern "C" {
#endif

typedef enum SteveMcMovementMedium {
    STEVE_MC_MEDIUM_AIR = 0,
    STEVE_MC_MEDIUM_WATER = 1,
    STEVE_MC_MEDIUM_LAVA = 2
} SteveMcMovementMedium;

typedef struct SteveMcPhysicsState {
    float velocity[3];
    int was_falling;
} SteveMcPhysicsState;

typedef struct SteveMcPhysicsInput {
    /* Normalized movement intent: strafe right, forward, and vertical input. */
    float strafe;
    float forward;
    float vertical;
    float yaw_degrees;

    /* Effective attributes supplied by the engine/player adapter. */
    float movement_speed;
    float air_control_speed;
    float jump_strength;
    float jump_boost;
    float block_jump_factor;
    float gravity;
    float block_friction;
    float block_speed_factor;
    float water_movement_efficiency;
    float water_slowdown_override;

    SteveMcMovementMedium medium;
    int on_ground;
    int sprinting;
    int jump_pressed;
    int jump_in_fluid;
    int go_down_in_fluid;
    int lava_is_deep;
} SteveMcPhysicsInput;

typedef struct SteveMcPhysicsCollision {
    /* Requested displacement from begin_step and actual displacement from SM64. */
    float requested_delta[3];
    float actual_delta[3];
    int collided_x;
    int collided_y;
    int collided_z;
    int on_ground_after_move;
} SteveMcPhysicsCollision;

/*
 * Adds Minecraft-style moveRelative acceleration/jump impulse and returns
 * the displacement to pass into SM64's existing ground/air/water step solver.
 */
void steve_mc_physics_begin_step(
    SteveMcPhysicsState *state,
    const SteveMcPhysicsInput *input,
    float desired_displacement[3]
);

/*
 * Apply the clipped movement result, Entity.move horizontal collision response,
 * block speed factor, gravity and medium-specific drag.
 *
 * Vertical velocity is deliberately not forced to zero on a floor/ceiling
 * contact: the inspected 1.21.11 Entity.move path sets onGround/collision
 * state separately and explicitly zeroes the clipped horizontal axes.
 */
void steve_mc_physics_end_step(
    SteveMcPhysicsState *state,
    const SteveMcPhysicsInput *input,
    const SteveMcPhysicsCollision *collision
);

#ifdef __cplusplus
}
#endif

#endif
