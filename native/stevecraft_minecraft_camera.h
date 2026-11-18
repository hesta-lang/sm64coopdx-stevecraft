#ifndef STEVECRAFT_MINECRAFT_CAMERA_H
#define STEVECRAFT_MINECRAFT_CAMERA_H

#ifdef __cplusplus
extern "C" {
#endif

typedef enum SteveMcCameraPerspective {
    STEVE_MC_CAMERA_FIRST_PERSON = 0,
    STEVE_MC_CAMERA_THIRD_PERSON_BACK = 1,
    STEVE_MC_CAMERA_THIRD_PERSON_FRONT = 2
} SteveMcCameraPerspective;

/*
 * Return non-zero when the ray intersects visible level geometry.
 * hit_position must be written in Minecraft world-axis coordinates:
 * X east/right, Y up, Z south/forward.
 *
 * SM64's renderer/level adapter should implement this callback with its
 * surface-ray query or camera collision routines. Fluids are not camera
 * blockers in the Minecraft Camera.getMaxZoom algorithm.
 */
typedef int (*SteveMcCameraRaycastFn)(
    void *user_data,
    const float ray_start[3],
    const float ray_end[3],
    float hit_position[3]
);

typedef struct SteveMcCameraInput {
    float previous_position[3];
    float current_position[3];
    float previous_eye_height;
    float current_eye_height;
    float partial_tick;

    float yaw_degrees;
    float pitch_degrees;

    float camera_scale;
    float camera_distance;

    int has_living_mount;
    float mount_scale;
    float mount_camera_distance;

    SteveMcCameraPerspective perspective;
} SteveMcCameraInput;

typedef struct SteveMcCameraOutput {
    float focus[3];
    float position[3];
    float forward[3];
    float up[3];
    float yaw_degrees;
    float pitch_degrees;
    float requested_distance;
    float actual_distance;
    int collision_shortened;
    int ray_count;
} SteveMcCameraOutput;

/* Mirrors Camera.tick(): retain old eye height, then approach target by 0.5. */
void steve_mc_camera_tick_eye_height(
    float target_eye_height,
    float *previous_eye_height,
    float *current_eye_height
);

/* Apply pointer deltas already converted to configured sensitivity units. */
void steve_mc_camera_apply_look(
    float *yaw_degrees,
    float *pitch_degrees,
    float delta_x,
    float delta_y,
    float sensitivity_x,
    float sensitivity_y
);

/*
 * Reproduces Camera.setup() and getMaxZoom() for first/rear/front perspective.
 * A null raycast callback leaves the requested third-person distance unchanged.
 */
void steve_mc_camera_build(
    const SteveMcCameraInput *input,
    SteveMcCameraRaycastFn raycast,
    void *raycast_user_data,
    SteveMcCameraOutput *output
);

#ifdef __cplusplus
}
#endif

#endif
