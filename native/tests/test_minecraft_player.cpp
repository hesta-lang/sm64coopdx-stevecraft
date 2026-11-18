#include "../stevecraft_minecraft_player.h"

#include <cassert>
#include <cmath>
#include <cstdio>

static float at(const float matrix[16], int row, int col) {
    return matrix[col * 4 + row];
}

static void identity_state(SteveMcHumanoidState &state) {
    state = {};
    state.speed_value = 1.0f;
    state.age_scale = 1.0f;
    state.left_arm_pose = STEVE_MC_ARM_EMPTY;
    state.right_arm_pose = STEVE_MC_ARM_EMPTY;
}

int main() {
    SteveMcHumanoidState state;
    float matrices[STEVE_MC_PART_COUNT][16];
    identity_state(state);

    steve_mc_build_sm64_matrices(&state, matrices);

    /* Rest pose: overlays inherit the exact matrix of their parent part. */
    const int overlays[][2] = {
        {STEVE_MC_HEAD, STEVE_MC_HAT},
        {STEVE_MC_BODY, STEVE_MC_JACKET},
        {STEVE_MC_RIGHT_ARM, STEVE_MC_RIGHT_SLEEVE},
        {STEVE_MC_LEFT_ARM, STEVE_MC_LEFT_SLEEVE},
        {STEVE_MC_RIGHT_LEG, STEVE_MC_RIGHT_PANTS},
        {STEVE_MC_LEFT_LEG, STEVE_MC_LEFT_PANTS}
    };
    for (unsigned i = 0; i < sizeof(overlays) / sizeof(overlays[0]); ++i) {
        const float *parent = matrices[overlays[i][0]];
        const float *child = matrices[overlays[i][1]];
        for (int k = 0; k < 16; ++k) assert(std::fabs(parent[k] - child[k]) < 0.00001f);
    }

    /* Minecraft-to-SM64 basis uses the same vertical/side/depth mapping as the actor exporter. */
    const float source[3] = {16.0f, 8.0f, -4.0f};
    float converted[3] = {};
    steve_mc_to_sm64_point(source, converted);
    assert(std::fabs(converted[0] - 0.5f) < 0.00001f);
    assert(std::fabs(converted[1] + 1.0f) < 0.00001f);
    assert(std::fabs(converted[2] - 0.25f) < 0.00001f);

    /* Head pitch is inherited by the hat; the overlay must not stay in world axes. */
    state.head_pitch_degrees = 35.0f;
    steve_mc_build_sm64_matrices(&state, matrices);
    for (int k = 0; k < 16; ++k) {
        assert(std::fabs(matrices[STEVE_MC_HEAD][k] - matrices[STEVE_MC_HAT][k]) < 0.00001f);
    }

    /* Opposite legs swing in opposite directions under the source walk equations. */
    identity_state(state);
    state.walk_animation_position = 0.7f;
    state.walk_animation_speed = 0.8f;
    steve_mc_build_sm64_matrices(&state, matrices);
    assert(std::fabs(at(matrices[STEVE_MC_LEFT_LEG], 1, 2)
                   - at(matrices[STEVE_MC_RIGHT_LEG], 1, 2)) > 0.0001f);

    /* Crouch changes the torso and shifts the head/limb pivots. */
    identity_state(state);
    state.is_crouching = 1;
    steve_mc_build_sm64_matrices(&state, matrices);
    assert(std::fabs(at(matrices[STEVE_MC_BODY], 0, 0) - 1.0f) > 0.01f);

    std::puts("SteveCraft native Minecraft pose tests passed");
    return 0;
}
