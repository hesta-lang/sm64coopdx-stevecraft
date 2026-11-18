// Classic Minecraft Steve right arm viewmodel.
// 4x12x4 geometry; six face textures use original classic-skin UV regions.
Texture steve_arm_top[] = { "actors/steve_hand/arm_top.png" };
Texture steve_arm_bottom[] = { "actors/steve_hand/arm_bottom.png" };
Texture steve_arm_right[] = { "actors/steve_hand/arm_right.png" };
Texture steve_arm_front[] = { "actors/steve_hand/arm_front.png" };
Texture steve_arm_left[] = { "actors/steve_hand/arm_left.png" };
Texture steve_arm_back[] = { "actors/steve_hand/arm_back.png" };

const Vtx steve_hand_vertices[] = {
    {{12, -2, -2}, 0, {0, 0}, {255, 255, 255, 255}},
    {{12, 2, -2}, 0, {96, 0}, {255, 255, 255, 255}},
    {{12, 2, 2}, 0, {96, 96}, {255, 255, 255, 255}},
    {{12, -2, 2}, 0, {0, 96}, {255, 255, 255, 255}},
    {{0, -2, 2}, 0, {0, 0}, {255, 255, 255, 255}},
    {{0, 2, 2}, 0, {96, 0}, {255, 255, 255, 255}},
    {{0, 2, -2}, 0, {96, 96}, {255, 255, 255, 255}},
    {{0, -2, -2}, 0, {0, 96}, {255, 255, 255, 255}},
    {{12, -2, -2}, 0, {0, 0}, {255, 255, 255, 255}},
    {{12, -2, 2}, 0, {96, 0}, {255, 255, 255, 255}},
    {{0, -2, 2}, 0, {96, 352}, {255, 255, 255, 255}},
    {{0, -2, -2}, 0, {0, 352}, {255, 255, 255, 255}},
    {{12, -2, 2}, 0, {0, 0}, {255, 255, 255, 255}},
    {{12, 2, 2}, 0, {96, 0}, {255, 255, 255, 255}},
    {{0, 2, 2}, 0, {96, 352}, {255, 255, 255, 255}},
    {{0, -2, 2}, 0, {0, 352}, {255, 255, 255, 255}},
    {{12, 2, 2}, 0, {0, 0}, {255, 255, 255, 255}},
    {{12, 2, -2}, 0, {96, 0}, {255, 255, 255, 255}},
    {{0, 2, -2}, 0, {96, 352}, {255, 255, 255, 255}},
    {{0, 2, 2}, 0, {0, 352}, {255, 255, 255, 255}},
    {{12, 2, -2}, 0, {0, 0}, {255, 255, 255, 255}},
    {{12, -2, -2}, 0, {96, 0}, {255, 255, 255, 255}},
    {{0, -2, -2}, 0, {96, 352}, {255, 255, 255, 255}},
    {{0, 2, -2}, 0, {0, 352}, {255, 255, 255, 255}},
};

const Gfx steve_hand_dl[] = {
    gsDPPipeSync(),
    gsSPClearGeometryMode(G_LIGHTING | G_CULL_BACK),
    gsDPSetCombineMode(G_CC_DECALRGBA, G_CC_DECALRGBA),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_ON),
    gsSPVertex(steve_hand_vertices, 24, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_arm_top, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(0, 1, 2, 0, 0, 2, 3, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_arm_bottom, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(4, 5, 6, 0, 4, 6, 7, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_arm_right, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(8, 9, 10, 0, 8, 10, 11, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_arm_front, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(12, 13, 14, 0, 12, 14, 15, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_arm_left, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(16, 17, 18, 0, 16, 18, 19, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_arm_back, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(20, 21, 22, 0, 20, 22, 23, 0),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_OFF),
    gsDPPipeSync(),
    gsSPEndDisplayList(),
};
