#include "../stevecraft_minecraft_camera.h"
#include "../stevecraft_minecraft_physics.h"

#include <cassert>
#include <cmath>
#include <cstdio>

static bool near(float a, float b, float tolerance = 0.0001f) {
    return std::fabs(a - b) <= tolerance;
}

struct RayFixture {
    float hit_distance;
    int calls;
};

static int fixed_hit(
    void *user_data,
    const float from[3],
    const float to[3],
    float hit[3]
) {
    RayFixture *fixture = static_cast<RayFixture *>(user_data);
    ++fixture->calls;

    float direction[3] = {
        to[0] - from[0],
        to[1] - from[1],
        to[2] - from[2]
    };
    const float length = std::sqrt(
        direction[0] * direction[0]
      + direction[1] * direction[1]
      + direction[2] * direction[2]
    );
    if (length <= fixture->hit_distance) return 0;

    const float scale = fixture->hit_distance / length;
    for (int i = 0; i < 3; ++i) hit[i] = from[i] + direction[i] * scale;
    return 1;
}

static void test_camera() {
    SteveMcCameraInput input = {};
    input.previous_position[0] = 10.0f;
    input.previous_position[1] = 20.0f;
    input.previous_position[2] = 30.0f;
    input.current_position[0] = 12.0f;
    input.current_position[1] = 24.0f;
    input.current_position[2] = 34.0f;
    input.previous_eye_height = 1.5f;
    input.current_eye_height = 1.7f;
    input.partial_tick = 0.5f;
    input.yaw_degrees = 0.0f;
    input.pitch_degrees = 0.0f;
    input.camera_scale = 1.0f;
    input.camera_distance = 4.0f;
    input.perspective = STEVE_MC_CAMERA_THIRD_PERSON_BACK;

    SteveMcCameraOutput output = {};
    steve_mc_camera_build(&input, nullptr, nullptr, &output);

    assert(near(output.focus[0], 11.0f));
    assert(near(output.focus[1], 23.6f));
    assert(near(output.focus[2], 32.0f));
    assert(near(output.forward[0], 0.0f));
    assert(near(output.forward[1], 0.0f));
    assert(near(output.forward[2], 1.0f));
    assert(near(output.position[2], 28.0f));
    assert(near(output.actual_distance, 4.0f));

    input.perspective = STEVE_MC_CAMERA_THIRD_PERSON_FRONT;
    steve_mc_camera_build(&input, nullptr, nullptr, &output);
    assert(near(output.forward[2], -1.0f));
    assert(near(output.position[2], 36.0f));
    assert(near(output.yaw_degrees, 180.0f));

    input.perspective = STEVE_MC_CAMERA_FIRST_PERSON;
    steve_mc_camera_build(&input, nullptr, nullptr, &output);
    assert(near(output.position[0], output.focus[0]));
    assert(near(output.position[1], output.focus[1]));
    assert(near(output.position[2], output.focus[2]));
    assert(near(output.actual_distance, 0.0f));

    input.perspective = STEVE_MC_CAMERA_THIRD_PERSON_BACK;
    RayFixture fixture = { 2.5f, 0 };
    steve_mc_camera_build(&input, fixed_hit, &fixture, &output);
    assert(fixture.calls == 8);
    assert(output.ray_count == 8);
    assert(output.collision_shortened == 1);
    assert(near(output.actual_distance, 2.4f, 0.01f));
    assert(near(output.position[2], output.focus[2] - 2.4f, 0.01f));

    float old_eye = 1.0f;
    float eye = 1.0f;
    steve_mc_camera_tick_eye_height(2.0f, &old_eye, &eye);
    assert(near(old_eye, 1.0f));
    assert(near(eye, 1.5f));

    float yaw = 0.0f;
    float pitch = 0.0f;
    steve_mc_camera_apply_look(&yaw, &pitch, 2.0f, -1.0f, 3.0f, 4.0f);
    assert(near(yaw, 6.0f));
    assert(near(pitch, 4.0f));
}

static SteveMcPhysicsInput ground_input() {
    SteveMcPhysicsInput input = {};
    input.medium = STEVE_MC_MEDIUM_AIR;
    input.on_ground = 1;
    input.movement_speed = 0.1f;
    input.air_control_speed = 0.02f;
    input.jump_strength = 0.42f;
    input.block_jump_factor = 1.0f;
    input.gravity = 0.08f;
    input.block_friction = 0.6f;
    input.block_speed_factor = 1.0f;
    return input;
}

static void finish_no_collision(
    SteveMcPhysicsState &state,
    const SteveMcPhysicsInput &input,
    const float requested[3]
) {
    SteveMcPhysicsCollision collision = {};
    for (int i = 0; i < 3; ++i) {
        collision.requested_delta[i] = requested[i];
        collision.actual_delta[i] = requested[i];
    }
    collision.on_ground_after_move = input.on_ground;
    steve_mc_physics_end_step(&state, &input, &collision);
}

static void test_physics() {
    SteveMcPhysicsState state = {};
    SteveMcPhysicsInput input = ground_input();
    input.forward = 1.0f;

    float displacement[3] = {};
    steve_mc_physics_begin_step(&state, &input, displacement);
    assert(near(displacement[0], 0.0f));
    assert(near(displacement[1], 0.0f));
    assert(near(displacement[2], 0.1f));

    finish_no_collision(state, input, displacement);
    assert(near(state.velocity[2], 0.0546f));
    assert(near(state.velocity[1], -0.0784f));

    /* Diagonal input is normalized before applying movement speed. */
    state = {};
    input = ground_input();
    input.forward = 1.0f;
    input.strafe = 1.0f;
    steve_mc_physics_begin_step(&state, &input, displacement);
    assert(near(std::sqrt(displacement[0] * displacement[0]
                        + displacement[2] * displacement[2]), 0.1f));

    /* Air control uses the supplied flying-speed attribute, not ground speed. */
    state = {};
    input = ground_input();
    input.on_ground = 0;
    input.forward = 1.0f;
    steve_mc_physics_begin_step(&state, &input, displacement);
    assert(near(displacement[2], 0.02f));

    /* A sprint jump uses the jump-strength attribute and the 0.2 forward impulse. */
    state = {};
    input = ground_input();
    input.jump_pressed = 1;
    input.sprinting = 1;
    input.forward = 0.0f;
    steve_mc_physics_begin_step(&state, &input, displacement);
    assert(near(displacement[1], 0.42f));
    assert(near(displacement[2], 0.2f));

    /* Entity.move clips horizontal velocity but leaves vertical velocity separate. */
    state = {};
    input = ground_input();
    input.forward = 1.0f;
    steve_mc_physics_begin_step(&state, &input, displacement);
    SteveMcPhysicsCollision wall = {};
    for (int i = 0; i < 3; ++i) wall.requested_delta[i] = displacement[i];
    wall.actual_delta[2] = 0.0f;
    wall.collided_z = 1;
    steve_mc_physics_end_step(&state, &input, &wall);
    assert(near(state.velocity[2], 0.0f));
    assert(near(state.velocity[1], -0.0784f));

    /* Water uses the vanilla 0.02 input acceleration and 0.8 vertical drag. */
    state = {};
    input = ground_input();
    input.medium = STEVE_MC_MEDIUM_WATER;
    input.on_ground = 0;
    input.forward = 1.0f;
    input.gravity = 0.08f;
    steve_mc_physics_begin_step(&state, &input, displacement);
    assert(near(displacement[2], 0.02f));
    finish_no_collision(state, input, displacement);
    assert(near(state.velocity[2], 0.016f));
    assert(near(state.velocity[1], -0.005f));

    std::puts("SteveCraft camera and physics tests passed");
}

int main() {
    test_camera();
    test_physics();
    return 0;
}
