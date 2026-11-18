#include "stevecraft_minecraft_camera.h"

#include <algorithm>
#include <cmath>
#include <cstring>

namespace {
const float kPi = 3.14159265358979323846f;
const float kDegreesToRadians = kPi / 180.0f;

float lerp(float amount, float start, float end) {
    return start + (end - start) * amount;
}

void subtract_scaled(
    const float origin[3],
    const float direction[3],
    float distance,
    float output[3]
) {
    for (int i = 0; i < 3; ++i) {
        output[i] = origin[i] - direction[i] * distance;
    }
}

float resolve_max_zoom(
    const float camera_origin[3],
    const float forward[3],
    float camera_distance,
    SteveMcCameraRaycastFn raycast,
    void *user_data,
    int *rays_tested
) {
    if (rays_tested) *rays_tested = 0;
    if (!raycast || camera_distance <= 0.0f) {
        return camera_distance;
    }

    /*
     * Minecraft Camera.getMaxZoom samples all eight corners of a 0.1-unit
     * cube around the eye. The closest hit shortens the camera arm.
     */
    for (int i = 0; i < 8; ++i) {
        const float offset_x = ((i & 1) ? 1.0f : -1.0f) * 0.1f;
        const float offset_y = ((i & 2) ? 1.0f : -1.0f) * 0.1f;
        const float offset_z = ((i & 4) ? 1.0f : -1.0f) * 0.1f;

        float from[3] = {
            camera_origin[0] + offset_x,
            camera_origin[1] + offset_y,
            camera_origin[2] + offset_z
        };
        float to[3];
        subtract_scaled(from, forward, camera_distance, to);

        float hit[3] = {};
        if (rays_tested) ++(*rays_tested);
        if (raycast(user_data, from, to, hit)) {
            const float dx = hit[0] - camera_origin[0];
            const float dy = hit[1] - camera_origin[1];
            const float dz = hit[2] - camera_origin[2];
            const float hit_distance = std::sqrt(dx * dx + dy * dy + dz * dz);
            if (hit_distance < camera_distance) {
                camera_distance = hit_distance;
            }
        }
    }

    return camera_distance;
}

} // namespace

extern "C" void steve_mc_camera_tick_eye_height(
    float target_eye_height,
    float *previous_eye_height,
    float *current_eye_height
) {
    if (!previous_eye_height || !current_eye_height) return;
    *previous_eye_height = *current_eye_height;
    *current_eye_height += (target_eye_height - *current_eye_height) * 0.5f;
}

extern "C" void steve_mc_camera_apply_look(
    float *yaw_degrees,
    float *pitch_degrees,
    float delta_x,
    float delta_y,
    float sensitivity_x,
    float sensitivity_y
) {
    if (!yaw_degrees || !pitch_degrees) return;
    *yaw_degrees += delta_x * sensitivity_x;
    *pitch_degrees = std::max(
        -90.0f,
        std::min(90.0f, *pitch_degrees - delta_y * sensitivity_y)
    );
}

extern "C" void steve_mc_camera_build(
    const SteveMcCameraInput *input,
    SteveMcCameraRaycastFn raycast,
    void *raycast_user_data,
    SteveMcCameraOutput *output
) {
    if (!input || !output) return;
    std::memset(output, 0, sizeof(*output));

    const float alpha = input->partial_tick;
    for (int axis = 0; axis < 3; ++axis) {
        output->focus[axis] = lerp(
            alpha, input->previous_position[axis], input->current_position[axis]
        );
    }
    output->focus[1] += lerp(
        alpha, input->previous_eye_height, input->current_eye_height
    );

    float yaw = input->yaw_degrees;
    float pitch = input->pitch_degrees;
    if (input->perspective == STEVE_MC_CAMERA_THIRD_PERSON_FRONT) {
        yaw += 180.0f;
        pitch = -pitch;
    }

    output->yaw_degrees = yaw;
    output->pitch_degrees = pitch;

    const float yaw_radians = yaw * kDegreesToRadians;
    const float pitch_radians = pitch * kDegreesToRadians;
    const float sin_yaw = std::sin(yaw_radians);
    const float cos_yaw = std::cos(yaw_radians);
    const float sin_pitch = std::sin(pitch_radians);
    const float cos_pitch = std::cos(pitch_radians);

    /*
     * Camera.setRotation() rotates FORWARDS=(0,0,-1) using a Y-X-Z
     * quaternion with angles (PI-yaw, -pitch, 0).
     */
    output->forward[0] = -sin_yaw * cos_pitch;
    output->forward[1] = -sin_pitch;
    output->forward[2] = cos_yaw * cos_pitch;

    output->up[0] = -sin_yaw * sin_pitch;
    output->up[1] = cos_pitch;
    output->up[2] = cos_yaw * sin_pitch;

    if (input->perspective == STEVE_MC_CAMERA_FIRST_PERSON) {
        for (int axis = 0; axis < 3; ++axis) {
            output->position[axis] = output->focus[axis];
        }
        output->requested_distance = 0.0f;
        output->actual_distance = 0.0f;
        return;
    }

    const float entity_scale = input->camera_scale > 0.0f
        ? input->camera_scale : 1.0f;
    float distance = entity_scale * input->camera_distance;
    if (input->has_living_mount) {
        const float mount_scale = input->mount_scale > 0.0f
            ? input->mount_scale : 1.0f;
        const float mount_distance = mount_scale * input->mount_camera_distance;
        distance = std::max(distance, mount_distance);
    }

    output->requested_distance = distance;
    int ray_count = 0;
    output->actual_distance = resolve_max_zoom(
        output->focus, output->forward, distance,
        raycast, raycast_user_data, &ray_count
    );
    output->ray_count = ray_count;
    output->collision_shortened = output->actual_distance + 0.00001f < distance;

    subtract_scaled(
        output->focus, output->forward, output->actual_distance, output->position
    );
}
