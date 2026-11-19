#include "stevecraft_minecraft_physics.h"

#include <algorithm>
#include <cmath>

namespace {
const float kPi = 3.14159265358979323846f;
const float kDegreesToRadians = kPi / 180.0f;
const float kGroundSpeedFactor = 0.21600002f;

float clampf(float value, float minimum, float maximum) {
    return std::max(minimum, std::min(maximum, value));
}

float safe_friction(float friction) {
    return std::max(0.0001f, friction);
}

void get_input_vector(
    const SteveMcPhysicsInput &input,
    float speed,
    float output[3]
) {
    float x = input.strafe;
    float y = input.vertical;
    float z = input.forward;
    const float magnitude_squared = x * x + y * y + z * z;

    if (magnitude_squared < 1.0e-7f) {
        output[0] = output[1] = output[2] = 0.0f;
        return;
    }

    if (magnitude_squared > 1.0f) {
        const float inverse_magnitude = 1.0f / std::sqrt(magnitude_squared);
        x *= inverse_magnitude;
        y *= inverse_magnitude;
        z *= inverse_magnitude;
    }

    x *= speed;
    y *= speed;
    z *= speed;

    const float yaw = input.yaw_degrees * kDegreesToRadians;
    const float sin_yaw = std::sin(yaw);
    const float cos_yaw = std::cos(yaw);

    /* Exact Entity.getInputVector() X/Z yaw transform. */
    output[0] = x * cos_yaw - z * sin_yaw;
    output[1] = y;
    output[2] = z * cos_yaw + x * sin_yaw;
}

float movement_speed_for(const SteveMcPhysicsInput &input) {
    if (input.medium == STEVE_MC_MEDIUM_WATER) {
        float efficiency = input.water_movement_efficiency;
        if (!input.on_ground) efficiency *= 0.5f;
        efficiency = clampf(efficiency, 0.0f, 1.0f);
        return 0.02f + (input.movement_speed - 0.02f) * efficiency;
    }
    if (input.medium == STEVE_MC_MEDIUM_LAVA) {
        return 0.02f;
    }
    if (input.on_ground) {
        const float friction = safe_friction(input.block_friction);
        return input.movement_speed * (
            kGroundSpeedFactor / (friction * friction * friction)
        );
    }
    return input.air_control_speed;
}

void add_movement_input(
    SteveMcPhysicsState &state,
    const SteveMcPhysicsInput &input
) {
    float acceleration[3];
    get_input_vector(input, movement_speed_for(input), acceleration);
    for (int axis = 0; axis < 3; ++axis) {
        state.velocity[axis] += acceleration[axis];
    }
}

void jump_from_ground(
    SteveMcPhysicsState &state,
    const SteveMcPhysicsInput &input
) {
    if (!input.jump_pressed || !input.on_ground) return;

    const float jump_power =
        input.jump_strength * input.block_jump_factor + input.jump_boost;
    if (jump_power <= 1.0e-5f) return;

    state.velocity[1] = std::max(state.velocity[1], jump_power);
    if (input.sprinting) {
        const float yaw = input.yaw_degrees * kDegreesToRadians;
        state.velocity[0] += -std::sin(yaw) * 0.2f;
        state.velocity[2] += std::cos(yaw) * 0.2f;
    }
}

void apply_fluid_fall_adjustment(
    float gravity,
    bool is_falling,
    bool sprinting,
    float *vertical_velocity
) {
    if (!vertical_velocity || gravity == 0.0f || sprinting) return;

    const float movement_y = *vertical_velocity;
    if (is_falling
        && std::fabs(movement_y - 0.005f) >= 0.003f
        && std::fabs(movement_y - gravity / 16.0f) < 0.003f) {
        *vertical_velocity = -0.003f;
    } else {
        *vertical_velocity = movement_y - gravity / 16.0f;
    }
}

} // namespace

extern "C" void steve_mc_physics_begin_step(
    SteveMcPhysicsState *state,
    const SteveMcPhysicsInput *input,
    float desired_displacement[3]
) {
    if (!state || !input || !desired_displacement) return;

    if (input->medium == STEVE_MC_MEDIUM_WATER && input->jump_in_fluid) {
        state->velocity[1] += 0.04f;
    }
    if (input->medium == STEVE_MC_MEDIUM_WATER && input->go_down_in_fluid) {
        state->velocity[1] -= 0.04f;
    }

    jump_from_ground(*state, *input);
    /* LivingEntity.travelInFluid captures this before movement/drag. */
    state->was_falling = state->velocity[1] <= 0.0f;
    add_movement_input(*state, *input);

    for (int axis = 0; axis < 3; ++axis) {
        desired_displacement[axis] = state->velocity[axis];
    }
}

extern "C" void steve_mc_physics_end_step(
    SteveMcPhysicsState *state,
    const SteveMcPhysicsInput *input,
    const SteveMcPhysicsCollision *collision
) {
    if (!state || !input || !collision) return;

    /*
     * Entity.move() removes velocity only along clipped horizontal axes.
     * Keep the vertical component intact and let the next travel step apply
     * gravity, matching the inspected Java 1.21.11 behavior.
     */
    if (collision->collided_x
        || std::fabs(collision->requested_delta[0] - collision->actual_delta[0]) > 1.0e-5f) {
        state->velocity[0] = 0.0f;
    }
    if (collision->collided_z
        || std::fabs(collision->requested_delta[2] - collision->actual_delta[2]) > 1.0e-5f) {
        state->velocity[2] = 0.0f;
    }

    const float block_speed_factor = input->block_speed_factor > 0.0f
        ? input->block_speed_factor : 1.0f;
    state->velocity[0] *= block_speed_factor;
    state->velocity[2] *= block_speed_factor;

    if (input->medium == STEVE_MC_MEDIUM_WATER) {
        float slowdown = input->water_slowdown_override > 0.0f
            ? input->water_slowdown_override
            : (input->sprinting ? 0.9f : 0.8f);
        float efficiency = clampf(
            input->water_movement_efficiency * (input->on_ground ? 1.0f : 0.5f),
            0.0f, 1.0f
        );
        slowdown += (0.54600006f - slowdown) * efficiency;

        state->velocity[0] *= slowdown;
        state->velocity[2] *= slowdown;
        state->velocity[1] *= 0.8f;
        apply_fluid_fall_adjustment(
            input->gravity,
            state->was_falling != 0,
            input->sprinting,
            &state->velocity[1]
        );
        return;
    }

    if (input->medium == STEVE_MC_MEDIUM_LAVA) {
        if (input->lava_is_deep) {
            state->velocity[0] *= 0.5f;
            state->velocity[1] *= 0.5f;
            state->velocity[2] *= 0.5f;
        } else {
            state->velocity[0] *= 0.5f;
            state->velocity[1] *= 0.8f;
            state->velocity[2] *= 0.5f;
            apply_fluid_fall_adjustment(
                input->gravity,
                state->was_falling != 0,
                input->sprinting,
                &state->velocity[1]
            );
        }
        state->velocity[1] -= input->gravity / 4.0f;
        return;
    }

    const float block_friction = input->on_ground
        ? safe_friction(input->block_friction) : 1.0f;
    const float horizontal_friction = block_friction * 0.91f;
    const float vertical_friction = 0.98f;

    state->velocity[1] -= input->gravity;
    state->velocity[0] *= horizontal_friction;
    state->velocity[2] *= horizontal_friction;
    state->velocity[1] *= vertical_friction;
}
