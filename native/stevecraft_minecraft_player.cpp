#include "stevecraft_minecraft_player.h"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace {

const float kPi = 3.14159265358979323846f;
const float kDegToRad = kPi / 180.0f;

struct Vec3 {
    float x, y, z;
};

struct Matrix4 {
    float m[16]; /* row-major internally */
};

struct PartTransform {
    Vec3 pivot;
    Vec3 rotation;
};

struct Pose {
    PartTransform part[STEVE_MC_PART_COUNT];
};

Matrix4 identity() {
    Matrix4 out = {};
    out.m[0] = out.m[5] = out.m[10] = out.m[15] = 1.0f;
    return out;
}

Matrix4 multiply(const Matrix4 &a, const Matrix4 &b) {
    Matrix4 out = {};
    for (int row = 0; row < 4; ++row) {
        for (int col = 0; col < 4; ++col) {
            for (int k = 0; k < 4; ++k) {
                out.m[row * 4 + col] += a.m[row * 4 + k] * b.m[k * 4 + col];
            }
        }
    }
    return out;
}

Matrix4 translation(const Vec3 &p) {
    Matrix4 out = identity();
    out.m[3] = p.x / 16.0f;
    out.m[7] = p.y / 16.0f;
    out.m[11] = p.z / 16.0f;
    return out;
}

Matrix4 rotation_x(float angle) {
    Matrix4 out = identity();
    const float c = std::cos(angle);
    const float s = std::sin(angle);
    out.m[5] = c;  out.m[6] = -s;
    out.m[9] = s;  out.m[10] = c;
    return out;
}

Matrix4 rotation_y(float angle) {
    Matrix4 out = identity();
    const float c = std::cos(angle);
    const float s = std::sin(angle);
    out.m[0] = c;  out.m[2] = s;
    out.m[8] = -s; out.m[10] = c;
    return out;
}

Matrix4 rotation_z(float angle) {
    Matrix4 out = identity();
    const float c = std::cos(angle);
    const float s = std::sin(angle);
    out.m[0] = c;  out.m[1] = -s;
    out.m[4] = s;  out.m[5] = c;
    return out;
}

Matrix4 local_matrix(const PartTransform &part) {
    /* ModelPart.translateAndRotate: translate, then rotationZYX(z, y, x). */
    Matrix4 result = translation(part.pivot);
    result = multiply(result, rotation_z(part.rotation.z));
    result = multiply(result, rotation_y(part.rotation.y));
    result = multiply(result, rotation_x(part.rotation.x));
    return result;
}

float clampf(float value, float minimum, float maximum) {
    return std::max(minimum, std::min(maximum, value));
}

float lerp(float amount, float start, float end) {
    return start + amount * (end - start);
}

float wrap_radians(float value) {
    while (value < -kPi) value += 2.0f * kPi;
    while (value >= kPi) value -= 2.0f * kPi;
    return value;
}

float rot_lerp(float amount, float start, float end) {
    return start + amount * wrap_radians(end - start);
}

void set_rotation(PartTransform &part, float x, float y, float z) {
    part.rotation.x = x;
    part.rotation.y = y;
    part.rotation.z = z;
}

void apply_arm_pose(Pose &pose, const SteveMcHumanoidState &state, bool right) {
    const SteveMcPart arm_id = right ? STEVE_MC_RIGHT_ARM : STEVE_MC_LEFT_ARM;
    PartTransform &arm = pose.part[arm_id];
    const SteveMcArmPose arm_pose = right ? state.right_arm_pose : state.left_arm_pose;
    const float head_x = pose.part[STEVE_MC_HEAD].rotation.x;
    const float head_y = pose.part[STEVE_MC_HEAD].rotation.y;

    switch (arm_pose) {
        case STEVE_MC_ARM_EMPTY:
            arm.rotation.y = 0.0f;
            break;
        case STEVE_MC_ARM_ITEM:
            arm.rotation.x = arm.rotation.x * 0.5f - kPi / 10.0f;
            arm.rotation.y = 0.0f;
            break;
        case STEVE_MC_ARM_BLOCK:
            arm.rotation.x = arm.rotation.x * 0.5f - 0.9424779f
                + clampf(head_x, -1.3962634f, 0.43633232f);
            arm.rotation.y = (right ? -30.0f : 30.0f) * kDegToRad
                + clampf(head_y, -kPi / 6.0f, kPi / 6.0f);
            break;
        case STEVE_MC_ARM_BOW_AND_ARROW:
            if (right) {
                arm.rotation.y = -0.1f + head_y;
                pose.part[STEVE_MC_LEFT_ARM].rotation.y = 0.1f + head_y + 0.4f;
            } else {
                arm.rotation.y = 0.1f + head_y;
                pose.part[STEVE_MC_RIGHT_ARM].rotation.y = -0.1f + head_y - 0.4f;
            }
            arm.rotation.x = -kPi / 2.0f + head_x;
            pose.part[right ? STEVE_MC_LEFT_ARM : STEVE_MC_RIGHT_ARM].rotation.x
                = -kPi / 2.0f + head_x;
            break;
        case STEVE_MC_ARM_THROW_TRIDENT:
        case STEVE_MC_ARM_SPEAR:
            arm.rotation.x = arm.rotation.x * 0.5f - kPi;
            arm.rotation.y = 0.0f;
            break;
        case STEVE_MC_ARM_SPYGLASS:
            arm.rotation.x = clampf(head_x, -1.2f, 1.2f) - 1.4835298f;
            arm.rotation.y = head_y + (right ? -kPi / 6.0f : kPi / 6.0f);
            break;
        case STEVE_MC_ARM_TOOT_HORN:
            arm.rotation.x = clampf(head_x, -1.2f, 1.2f) - 1.4835298f;
            arm.rotation.y = head_y + (right ? -kPi / 6.0f : kPi / 6.0f);
            break;
        case STEVE_MC_ARM_BRUSH:
            arm.rotation.x = arm.rotation.x * 0.5f - kPi / 5.0f;
            arm.rotation.y = 0.0f;
            break;
        case STEVE_MC_ARM_CROSSBOW_CHARGE:
        case STEVE_MC_ARM_CROSSBOW_HOLD:
        default:
            /* Kept at the locomotion pose until their item-specific state is ported. */
            break;
    }
}

void setup_pose(const SteveMcHumanoidState &state, Pose &pose) {
    std::memset(&pose, 0, sizeof(pose));

    const float speed_value = std::fabs(state.speed_value) < 0.0001f
        ? 1.0f : state.speed_value;
    const float animation_position = state.walk_animation_position;
    const float animation_speed = state.walk_animation_speed / speed_value;

    /* HumanoidModel.createMesh part pivots, in Minecraft model pixels. */
    pose.part[STEVE_MC_HEAD].pivot = {0.0f, state.y_offset, 0.0f};
    pose.part[STEVE_MC_HAT].pivot = {0.0f, 0.0f, 0.0f};
    pose.part[STEVE_MC_BODY].pivot = {0.0f, state.y_offset, 0.0f};
    pose.part[STEVE_MC_JACKET].pivot = {0.0f, 0.0f, 0.0f};

    pose.part[STEVE_MC_RIGHT_ARM].pivot = {-5.0f, 2.0f + state.y_offset, 0.0f};
    pose.part[STEVE_MC_RIGHT_SLEEVE].pivot = {0.0f, 0.0f, 0.0f};
    pose.part[STEVE_MC_LEFT_ARM].pivot = {5.0f, 2.0f + state.y_offset, 0.0f};
    pose.part[STEVE_MC_LEFT_SLEEVE].pivot = {0.0f, 0.0f, 0.0f};

    pose.part[STEVE_MC_RIGHT_LEG].pivot = {-1.9f, 12.0f + state.y_offset, 0.0f};
    pose.part[STEVE_MC_RIGHT_PANTS].pivot = {0.0f, 0.0f, 0.0f};
    pose.part[STEVE_MC_LEFT_LEG].pivot = {1.9f, 12.0f + state.y_offset, 0.0f};
    pose.part[STEVE_MC_LEFT_PANTS].pivot = {0.0f, 0.0f, 0.0f};

    pose.part[STEVE_MC_HEAD].rotation.x = state.head_pitch_degrees * kDegToRad;
    pose.part[STEVE_MC_HEAD].rotation.y = state.head_yaw_degrees * kDegToRad;

    if (state.is_fall_flying) {
        pose.part[STEVE_MC_HEAD].rotation.x = -kPi / 4.0f;
    } else if (state.swim_amount > 0.0f) {
        pose.part[STEVE_MC_HEAD].rotation.x = rot_lerp(
            state.swim_amount, pose.part[STEVE_MC_HEAD].rotation.x, -kPi / 4.0f);
    }

    pose.part[STEVE_MC_RIGHT_ARM].rotation.x
        = std::cos(animation_position * 0.6662f + kPi) * animation_speed;
    pose.part[STEVE_MC_LEFT_ARM].rotation.x
        = std::cos(animation_position * 0.6662f) * animation_speed;
    pose.part[STEVE_MC_RIGHT_LEG].rotation.x
        = std::cos(animation_position * 0.6662f) * 1.4f * animation_speed;
    pose.part[STEVE_MC_LEFT_LEG].rotation.x
        = std::cos(animation_position * 0.6662f + kPi) * 1.4f * animation_speed;

    pose.part[STEVE_MC_RIGHT_LEG].rotation.y = 0.005f;
    pose.part[STEVE_MC_LEFT_LEG].rotation.y = -0.005f;
    pose.part[STEVE_MC_RIGHT_LEG].rotation.z = 0.005f;
    pose.part[STEVE_MC_LEFT_LEG].rotation.z = -0.005f;

    if (state.is_passenger) {
        pose.part[STEVE_MC_RIGHT_ARM].rotation.x -= kPi / 5.0f;
        pose.part[STEVE_MC_LEFT_ARM].rotation.x -= kPi / 5.0f;

        set_rotation(pose.part[STEVE_MC_RIGHT_LEG], -1.4137167f, kPi / 10.0f, 0.07853982f);
        set_rotation(pose.part[STEVE_MC_LEFT_LEG], -1.4137167f, -kPi / 10.0f, -0.07853982f);
    }

    if (state.is_using_item || state.left_arm_pose != STEVE_MC_ARM_EMPTY
        || state.right_arm_pose != STEVE_MC_ARM_EMPTY) {
        apply_arm_pose(pose, state, true);
        apply_arm_pose(pose, state, false);
    }

    if (state.attack_time > 0.0f) {
        const float body_yaw = std::sin(std::sqrt(state.attack_time) * (2.0f * kPi)) * 0.2f
            * (state.attack_arm_is_right ? 1.0f : -1.0f);
        pose.part[STEVE_MC_BODY].rotation.y = body_yaw;
        pose.part[STEVE_MC_RIGHT_ARM].pivot.z = std::sin(body_yaw) * 5.0f * state.age_scale;
        pose.part[STEVE_MC_RIGHT_ARM].pivot.x = -std::cos(body_yaw) * 5.0f * state.age_scale;
        pose.part[STEVE_MC_LEFT_ARM].pivot.z = -std::sin(body_yaw) * 5.0f * state.age_scale;
        pose.part[STEVE_MC_LEFT_ARM].pivot.x = std::cos(body_yaw) * 5.0f * state.age_scale;
        pose.part[STEVE_MC_RIGHT_ARM].rotation.y += body_yaw;
        pose.part[STEVE_MC_LEFT_ARM].rotation.y += body_yaw;
        pose.part[STEVE_MC_LEFT_ARM].rotation.x += body_yaw;

        if (state.swing_animation_is_whack) {
            const float inverse = 1.0f - clampf(state.attack_time, 0.0f, 1.0f);
            const float eased = 1.0f - inverse * inverse * inverse * inverse;
            const float aa = std::sin(eased * kPi);
            const float bb = std::sin(state.attack_time * kPi)
                * -(pose.part[STEVE_MC_HEAD].rotation.x - 0.7f) * 0.75f;
            PartTransform &attack_arm = pose.part[
                state.attack_arm_is_right ? STEVE_MC_RIGHT_ARM : STEVE_MC_LEFT_ARM];
            attack_arm.rotation.x -= aa * 1.2f + bb;
            attack_arm.rotation.y += body_yaw * 2.0f;
            attack_arm.rotation.z += std::sin(state.attack_time * kPi) * -0.4f;
        }
    }

    if (state.is_crouching) {
        pose.part[STEVE_MC_BODY].rotation.x = 0.5f;
        pose.part[STEVE_MC_RIGHT_ARM].rotation.x += 0.4f;
        pose.part[STEVE_MC_LEFT_ARM].rotation.x += 0.4f;
        pose.part[STEVE_MC_RIGHT_LEG].pivot.z += 4.0f;
        pose.part[STEVE_MC_LEFT_LEG].pivot.z += 4.0f;
        pose.part[STEVE_MC_HEAD].pivot.y += 4.2f;
        pose.part[STEVE_MC_BODY].pivot.y += 3.2f;
        pose.part[STEVE_MC_LEFT_ARM].pivot.y += 3.2f;
        pose.part[STEVE_MC_RIGHT_ARM].pivot.y += 3.2f;
    }

    /* HumanoidModel's swimming uses a 26-tick stroke cycle. */
    if (state.swim_amount > 0.0f && !state.is_using_item) {
        float swim_position = std::fmod(animation_position, 26.0f);
        if (swim_position < 0.0f) swim_position += 26.0f;

        float phase = 0.0f;
        float target_left_x = 0.0f, target_right_x = 0.0f;
        float target_left_y = kPi, target_right_y = kPi;
        float target_left_z = kPi, target_right_z = kPi;

        if (swim_position < 14.0f) {
            const float q = -65.0f * swim_position + swim_position * swim_position;
            const float q14 = -65.0f * 14.0f + 14.0f * 14.0f;
            phase = q14 == 0.0f ? 0.0f : q / q14;
            target_left_z = kPi + 1.8707964f * phase;
            target_right_z = kPi - 1.8707964f * phase;
        } else if (swim_position < 22.0f) {
            phase = (swim_position - 14.0f) / 8.0f;
            target_left_x = (kPi / 2.0f) * phase;
            target_right_x = target_left_x;
            target_left_z = 5.012389f - 1.8707964f * phase;
            target_right_z = 1.2707963f + 1.8707964f * phase;
        } else {
            phase = (swim_position - 22.0f) / 4.0f;
            target_left_x = (kPi / 2.0f) - (kPi / 2.0f) * phase;
            target_right_x = target_left_x;
        }

        const float amount = clampf(state.swim_amount, 0.0f, 1.0f);
        PartTransform &left_arm = pose.part[STEVE_MC_LEFT_ARM];
        PartTransform &right_arm = pose.part[STEVE_MC_RIGHT_ARM];
        left_arm.rotation.x = rot_lerp(amount, left_arm.rotation.x, target_left_x);
        right_arm.rotation.x = lerp(amount, right_arm.rotation.x, target_right_x);
        left_arm.rotation.y = rot_lerp(amount, left_arm.rotation.y, target_left_y);
        right_arm.rotation.y = lerp(amount, right_arm.rotation.y, target_right_y);
        left_arm.rotation.z = rot_lerp(amount, left_arm.rotation.z, target_left_z);
        right_arm.rotation.z = lerp(amount, right_arm.rotation.z, target_right_z);

        pose.part[STEVE_MC_LEFT_LEG].rotation.x = lerp(
            amount, pose.part[STEVE_MC_LEFT_LEG].rotation.x,
            0.3f * std::cos(animation_position * 0.33333334f + kPi));
        pose.part[STEVE_MC_RIGHT_LEG].rotation.x = lerp(
            amount, pose.part[STEVE_MC_RIGHT_LEG].rotation.x,
            0.3f * std::cos(animation_position * 0.33333334f));
    }

    /* AnimationUtils.bobModelPart from Minecraft 1.21.11. */
    const float right_bob = 1.0f;
    const float left_bob = -1.0f;
    pose.part[STEVE_MC_RIGHT_ARM].rotation.z += right_bob
        * (std::cos(state.age_in_ticks * 0.09f) * 0.05f + 0.05f);
    pose.part[STEVE_MC_RIGHT_ARM].rotation.x += right_bob
        * std::sin(state.age_in_ticks * 0.067f) * 0.05f;
    pose.part[STEVE_MC_LEFT_ARM].rotation.z += left_bob
        * (std::cos(state.age_in_ticks * 0.09f) * 0.05f + 0.05f);
    pose.part[STEVE_MC_LEFT_ARM].rotation.x += left_bob
        * std::sin(state.age_in_ticks * 0.067f) * 0.05f;
}

Matrix4 sm64_basis() {
    Matrix4 out = {};
    out.m[1] = -1.0f / 16.0f;
    out.m[3] = 1.0f;
    out.m[4] = -1.0f / 16.0f;
    out.m[10] = -1.0f / 16.0f;
    out.m[15] = 1.0f;
    return out;
}

Matrix4 sm64_basis_inverse() {
    Matrix4 out = {};
    out.m[1] = -16.0f;
    out.m[4] = -16.0f;
    out.m[7] = 16.0f;
    out.m[10] = -16.0f;
    out.m[15] = 1.0f;
    return out;
}

void store_column_major(const Matrix4 &row_major, float output[16]) {
    for (int row = 0; row < 4; ++row) {
        for (int col = 0; col < 4; ++col) {
            output[col * 4 + row] = row_major.m[row * 4 + col];
        }
    }
}

} /* namespace */

extern "C" void steve_mc_to_sm64_point(const float minecraft_xyz[3], float sm64_xyz[3]) {
    if (!minecraft_xyz || !sm64_xyz) return;
    sm64_xyz[0] = 1.0f - minecraft_xyz[1] / 16.0f;
    sm64_xyz[1] = -minecraft_xyz[0] / 16.0f;
    sm64_xyz[2] = -minecraft_xyz[2] / 16.0f;
}

extern "C" void steve_mc_build_sm64_matrices(
    const SteveMcHumanoidState *state,
    float output[STEVE_MC_PART_COUNT][16]
) {
    if (!state || !output) return;

    Pose pose;
    setup_pose(*state, pose);

    Matrix4 world[STEVE_MC_PART_COUNT];
    world[STEVE_MC_ROOT] = identity();

    const int parents[STEVE_MC_PART_COUNT] = {
        -1,                         /* root */
        STEVE_MC_ROOT, STEVE_MC_HEAD,
        STEVE_MC_ROOT, STEVE_MC_BODY,
        STEVE_MC_BODY, STEVE_MC_RIGHT_ARM,
        STEVE_MC_BODY, STEVE_MC_LEFT_ARM,
        STEVE_MC_ROOT, STEVE_MC_RIGHT_LEG,
        STEVE_MC_ROOT, STEVE_MC_LEFT_LEG
    };

    const Matrix4 basis = sm64_basis();
    const Matrix4 basis_inverse = sm64_basis_inverse();

    for (int part = 1; part < STEVE_MC_PART_COUNT; ++part) {
        const Matrix4 local = local_matrix(pose.part[part]);
        world[part] = multiply(world[parents[part]], local);
    }

    for (int part = 0; part < STEVE_MC_PART_COUNT; ++part) {
        const Matrix4 sm64_matrix = multiply(multiply(basis, world[part]), basis_inverse);
        store_column_major(sm64_matrix, output[part]);
    }
}
