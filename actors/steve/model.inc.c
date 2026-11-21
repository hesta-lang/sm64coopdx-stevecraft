// Generated directly from Mojang Bedrock Geometry JSON.
// Do not hand-edit; run tools/build_steve_dynos.py.
// Small per-face RGBA PNGs keep texture loads below the N64 TMEM limit.

Texture steve_body_0_0_north_texture[] = { "steve/steve_body_0_0_north.png" };
Texture steve_body_0_0_south_texture[] = { "steve/steve_body_0_0_south.png" };
Texture steve_body_0_0_east_texture[] = { "steve/steve_body_0_0_east.png" };
Texture steve_body_0_0_west_texture[] = { "steve/steve_body_0_0_west.png" };
Texture steve_body_0_0_up_texture[] = { "steve/steve_body_0_0_up.png" };
Texture steve_body_0_0_down_texture[] = { "steve/steve_body_0_0_down.png" };

Vtx steve_body_0_0_vtx[24] = {
    {{{-7, -25, 12}, 0, {224, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{68, -25, 12}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{68, 25, 12}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-7, 25, 12}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-7, 25, -12}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{68, 25, -12}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{68, -25, -12}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-7, -25, -12}, 0, {224, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-7, -25, -12}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{68, -25, -12}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{68, -25, 12}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-7, -25, 12}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-7, 25, 12}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{68, 25, 12}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{68, 25, -12}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-7, 25, -12}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{68, -25, 12}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{68, -25, -12}, 0, {224, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{68, 25, -12}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{68, 25, 12}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-7, -25, -12}, 0, {224, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-7, -25, 12}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-7, 25, 12}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-7, 25, -12}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
};

Gfx steve_body_0_0_dl[] = {
    gsDPPipeSync(),
    gsDPSetTextureFilter(G_TF_POINT),
    gsSPClearGeometryMode(G_LIGHTING),
    gsDPSetCombineMode(G_CC_DECALRGBA, G_CC_DECALRGBA),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_ON),
    gsSPVertex(steve_body_0_0_vtx, 24, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_body_0_0_north_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(0, 1, 2, 0, 0, 2, 3, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_body_0_0_south_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(4, 5, 6, 0, 4, 6, 7, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_body_0_0_east_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(8, 9, 10, 0, 8, 10, 11, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_body_0_0_west_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(12, 13, 14, 0, 12, 14, 15, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_body_0_0_up_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(16, 17, 18, 0, 16, 18, 19, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_body_0_0_down_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(20, 21, 22, 0, 20, 22, 23, 0),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_OFF),
    gsDPPipeSync(),
    gsSPEndDisplayList(),
};

Texture steve_head_0_1_north_texture[] = { "steve/steve_head_0_1_north.png" };
Texture steve_head_0_1_south_texture[] = { "steve/steve_head_0_1_south.png" };
Texture steve_head_0_1_east_texture[] = { "steve/steve_head_0_1_east.png" };
Texture steve_head_0_1_west_texture[] = { "steve/steve_head_0_1_west.png" };
Texture steve_head_0_1_up_texture[] = { "steve/steve_head_0_1_up.png" };
Texture steve_head_0_1_down_texture[] = { "steve/steve_head_0_1_down.png" };

Vtx steve_head_0_1_vtx[24] = {
    {{{27, -25, 25}, 0, {224, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{77, -25, 25}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{77, 25, 25}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{27, 25, 25}, 0, {0, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{27, 25, -25}, 0, {0, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{77, 25, -25}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{77, -25, -25}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{27, -25, -25}, 0, {224, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{27, -25, -25}, 0, {224, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{77, -25, -25}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{77, -25, 25}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{27, -25, 25}, 0, {0, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{27, 25, 25}, 0, {0, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{77, 25, 25}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{77, 25, -25}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{27, 25, -25}, 0, {224, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{77, -25, 25}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{77, -25, -25}, 0, {224, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{77, 25, -25}, 0, {0, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{77, 25, 25}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{27, -25, -25}, 0, {224, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{27, -25, 25}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{27, 25, 25}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{27, 25, -25}, 0, {0, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
};

Gfx steve_head_0_1_dl[] = {
    gsDPPipeSync(),
    gsDPSetTextureFilter(G_TF_POINT),
    gsSPClearGeometryMode(G_LIGHTING),
    gsDPSetCombineMode(G_CC_DECALRGBA, G_CC_DECALRGBA),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_ON),
    gsSPVertex(steve_head_0_1_vtx, 24, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_head_0_1_north_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 8, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(0, 1, 2, 0, 0, 2, 3, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_head_0_1_south_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 8, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(4, 5, 6, 0, 4, 6, 7, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_head_0_1_east_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 8, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(8, 9, 10, 0, 8, 10, 11, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_head_0_1_west_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 8, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(12, 13, 14, 0, 12, 14, 15, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_head_0_1_up_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 8, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(16, 17, 18, 0, 16, 18, 19, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_head_0_1_down_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 8, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(20, 21, 22, 0, 20, 22, 23, 0),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_OFF),
    gsDPPipeSync(),
    gsSPEndDisplayList(),
};

Texture steve_hat_0_2_north_texture[] = { "steve/steve_hat_0_2_north.png" };
Texture steve_hat_0_2_south_texture[] = { "steve/steve_hat_0_2_south.png" };
Texture steve_hat_0_2_east_texture[] = { "steve/steve_hat_0_2_east.png" };
Texture steve_hat_0_2_west_texture[] = { "steve/steve_hat_0_2_west.png" };
Texture steve_hat_0_2_up_texture[] = { "steve/steve_hat_0_2_up.png" };
Texture steve_hat_0_2_down_texture[] = { "steve/steve_hat_0_2_down.png" };

Vtx steve_hat_0_2_vtx[24] = {
    {{{24, -28, 28}, 0, {224, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{80, -28, 28}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{80, 28, 28}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{24, 28, 28}, 0, {0, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{24, 28, -28}, 0, {0, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{80, 28, -28}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{80, -28, -28}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{24, -28, -28}, 0, {224, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{24, -28, -28}, 0, {224, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{80, -28, -28}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{80, -28, 28}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{24, -28, 28}, 0, {0, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{24, 28, 28}, 0, {0, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{80, 28, 28}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{80, 28, -28}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{24, 28, -28}, 0, {224, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{80, -28, 28}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{80, -28, -28}, 0, {224, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{80, 28, -28}, 0, {0, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{80, 28, 28}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{24, -28, -28}, 0, {224, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{24, -28, 28}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{24, 28, 28}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{24, 28, -28}, 0, {0, 224}, {0xFF, 0xFF, 0xFF, 0xFF}}},
};

Gfx steve_hat_0_2_dl[] = {
    gsDPPipeSync(),
    gsDPSetTextureFilter(G_TF_POINT),
    gsSPClearGeometryMode(G_LIGHTING),
    gsDPSetCombineMode(G_CC_DECALRGBA, G_CC_DECALRGBA),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_ON),
    gsSPVertex(steve_hat_0_2_vtx, 24, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_hat_0_2_north_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 8, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(0, 1, 2, 0, 0, 2, 3, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_hat_0_2_south_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 8, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(4, 5, 6, 0, 4, 6, 7, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_hat_0_2_east_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 8, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(8, 9, 10, 0, 8, 10, 11, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_hat_0_2_west_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 8, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(12, 13, 14, 0, 12, 14, 15, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_hat_0_2_up_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 8, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(16, 17, 18, 0, 16, 18, 19, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_hat_0_2_down_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 8, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(20, 21, 22, 0, 20, 22, 23, 0),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_OFF),
    gsDPPipeSync(),
    gsSPEndDisplayList(),
};

Texture steve_leftArm_0_3_north_texture[] = { "steve/steve_leftArm_0_3_north.png" };
Texture steve_leftArm_0_3_south_texture[] = { "steve/steve_leftArm_0_3_south.png" };
Texture steve_leftArm_0_3_east_texture[] = { "steve/steve_leftArm_0_3_east.png" };
Texture steve_leftArm_0_3_west_texture[] = { "steve/steve_leftArm_0_3_west.png" };
Texture steve_leftArm_0_3_up_texture[] = { "steve/steve_leftArm_0_3_up.png" };
Texture steve_leftArm_0_3_down_texture[] = { "steve/steve_leftArm_0_3_down.png" };

Vtx steve_leftArm_0_3_vtx[24] = {
    {{{-38, -45, -24}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{37, -45, -24}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{37, -20, -24}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-38, -20, -24}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-38, -20, -50}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{37, -20, -50}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{37, -45, -50}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-38, -45, -50}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-38, -45, -50}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{37, -45, -50}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{37, -45, -24}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-38, -45, -24}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-38, -20, -24}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{37, -20, -24}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{37, -20, -50}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-38, -20, -50}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{37, -45, -24}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{37, -45, -50}, 0, {96, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{37, -20, -50}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{37, -20, -24}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-38, -45, -50}, 0, {96, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-38, -45, -24}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-38, -20, -24}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-38, -20, -50}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
};

Gfx steve_leftArm_0_3_dl[] = {
    gsDPPipeSync(),
    gsDPSetTextureFilter(G_TF_POINT),
    gsSPClearGeometryMode(G_LIGHTING),
    gsDPSetCombineMode(G_CC_DECALRGBA, G_CC_DECALRGBA),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_ON),
    gsSPVertex(steve_leftArm_0_3_vtx, 24, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftArm_0_3_north_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(0, 1, 2, 0, 0, 2, 3, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftArm_0_3_south_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(4, 5, 6, 0, 4, 6, 7, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftArm_0_3_east_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(8, 9, 10, 0, 8, 10, 11, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftArm_0_3_west_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(12, 13, 14, 0, 12, 14, 15, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftArm_0_3_up_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(16, 17, 18, 0, 16, 18, 19, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftArm_0_3_down_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(20, 21, 22, 0, 20, 22, 23, 0),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_OFF),
    gsDPPipeSync(),
    gsSPEndDisplayList(),
};

Texture steve_leftSleeve_0_4_north_texture[] = { "steve/steve_leftSleeve_0_4_north.png" };
Texture steve_leftSleeve_0_4_south_texture[] = { "steve/steve_leftSleeve_0_4_south.png" };
Texture steve_leftSleeve_0_4_east_texture[] = { "steve/steve_leftSleeve_0_4_east.png" };
Texture steve_leftSleeve_0_4_west_texture[] = { "steve/steve_leftSleeve_0_4_west.png" };
Texture steve_leftSleeve_0_4_up_texture[] = { "steve/steve_leftSleeve_0_4_up.png" };
Texture steve_leftSleeve_0_4_down_texture[] = { "steve/steve_leftSleeve_0_4_down.png" };

Vtx steve_leftSleeve_0_4_vtx[24] = {
    {{{-40, -47, -23}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{39, -47, -23}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{39, -18, -23}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-40, -18, -23}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-40, -18, -51}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{39, -18, -51}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{39, -47, -51}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-40, -47, -51}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-40, -47, -51}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{39, -47, -51}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{39, -47, -23}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-40, -47, -23}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-40, -18, -23}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{39, -18, -23}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{39, -18, -51}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-40, -18, -51}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{39, -47, -23}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{39, -47, -51}, 0, {96, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{39, -18, -51}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{39, -18, -23}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-40, -47, -51}, 0, {96, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-40, -47, -23}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-40, -18, -23}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-40, -18, -51}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
};

Gfx steve_leftSleeve_0_4_dl[] = {
    gsDPPipeSync(),
    gsDPSetTextureFilter(G_TF_POINT),
    gsSPClearGeometryMode(G_LIGHTING),
    gsDPSetCombineMode(G_CC_DECALRGBA, G_CC_DECALRGBA),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_ON),
    gsSPVertex(steve_leftSleeve_0_4_vtx, 24, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftSleeve_0_4_north_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(0, 1, 2, 0, 0, 2, 3, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftSleeve_0_4_south_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(4, 5, 6, 0, 4, 6, 7, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftSleeve_0_4_east_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(8, 9, 10, 0, 8, 10, 11, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftSleeve_0_4_west_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(12, 13, 14, 0, 12, 14, 15, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftSleeve_0_4_up_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(16, 17, 18, 0, 16, 18, 19, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftSleeve_0_4_down_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(20, 21, 22, 0, 20, 22, 23, 0),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_OFF),
    gsDPPipeSync(),
    gsSPEndDisplayList(),
};

Texture steve_rightArm_0_5_north_texture[] = { "steve/steve_rightArm_0_5_north.png" };
Texture steve_rightArm_0_5_south_texture[] = { "steve/steve_rightArm_0_5_south.png" };
Texture steve_rightArm_0_5_east_texture[] = { "steve/steve_rightArm_0_5_east.png" };
Texture steve_rightArm_0_5_west_texture[] = { "steve/steve_rightArm_0_5_west.png" };
Texture steve_rightArm_0_5_up_texture[] = { "steve/steve_rightArm_0_5_up.png" };
Texture steve_rightArm_0_5_down_texture[] = { "steve/steve_rightArm_0_5_down.png" };

Vtx steve_rightArm_0_5_vtx[24] = {
    {{{-39, 30, 50}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{36, 30, 50}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{36, 55, 50}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-39, 55, 50}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-39, 55, 24}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{36, 55, 24}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{36, 30, 24}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-39, 30, 24}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-39, 30, 24}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{36, 30, 24}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{36, 30, 50}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-39, 30, 50}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-39, 55, 50}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{36, 55, 50}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{36, 55, 24}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-39, 55, 24}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{36, 30, 50}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{36, 30, 24}, 0, {96, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{36, 55, 24}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{36, 55, 50}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-39, 30, 24}, 0, {96, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-39, 30, 50}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-39, 55, 50}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-39, 55, 24}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
};

Gfx steve_rightArm_0_5_dl[] = {
    gsDPPipeSync(),
    gsDPSetTextureFilter(G_TF_POINT),
    gsSPClearGeometryMode(G_LIGHTING),
    gsDPSetCombineMode(G_CC_DECALRGBA, G_CC_DECALRGBA),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_ON),
    gsSPVertex(steve_rightArm_0_5_vtx, 24, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightArm_0_5_north_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(0, 1, 2, 0, 0, 2, 3, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightArm_0_5_south_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(4, 5, 6, 0, 4, 6, 7, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightArm_0_5_east_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(8, 9, 10, 0, 8, 10, 11, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightArm_0_5_west_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(12, 13, 14, 0, 12, 14, 15, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightArm_0_5_up_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(16, 17, 18, 0, 16, 18, 19, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightArm_0_5_down_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(20, 21, 22, 0, 20, 22, 23, 0),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_OFF),
    gsDPPipeSync(),
    gsSPEndDisplayList(),
};

Texture steve_rightSleeve_0_6_north_texture[] = { "steve/steve_rightSleeve_0_6_north.png" };
Texture steve_rightSleeve_0_6_south_texture[] = { "steve/steve_rightSleeve_0_6_south.png" };
Texture steve_rightSleeve_0_6_east_texture[] = { "steve/steve_rightSleeve_0_6_east.png" };
Texture steve_rightSleeve_0_6_west_texture[] = { "steve/steve_rightSleeve_0_6_west.png" };
Texture steve_rightSleeve_0_6_up_texture[] = { "steve/steve_rightSleeve_0_6_up.png" };
Texture steve_rightSleeve_0_6_down_texture[] = { "steve/steve_rightSleeve_0_6_down.png" };

Vtx steve_rightSleeve_0_6_vtx[24] = {
    {{{-41, 28, 51}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{38, 28, 51}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{38, 57, 51}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-41, 57, 51}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-41, 57, 23}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{38, 57, 23}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{38, 28, 23}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-41, 28, 23}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-41, 28, 23}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{38, 28, 23}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{38, 28, 51}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-41, 28, 51}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-41, 57, 51}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{38, 57, 51}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{38, 57, 23}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-41, 57, 23}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{38, 28, 51}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{38, 28, 23}, 0, {96, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{38, 57, 23}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{38, 57, 51}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-41, 28, 23}, 0, {96, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-41, 28, 51}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-41, 57, 51}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-41, 57, 23}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
};

Gfx steve_rightSleeve_0_6_dl[] = {
    gsDPPipeSync(),
    gsDPSetTextureFilter(G_TF_POINT),
    gsSPClearGeometryMode(G_LIGHTING),
    gsDPSetCombineMode(G_CC_DECALRGBA, G_CC_DECALRGBA),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_ON),
    gsSPVertex(steve_rightSleeve_0_6_vtx, 24, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightSleeve_0_6_north_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(0, 1, 2, 0, 0, 2, 3, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightSleeve_0_6_south_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(4, 5, 6, 0, 4, 6, 7, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightSleeve_0_6_east_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(8, 9, 10, 0, 8, 10, 11, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightSleeve_0_6_west_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(12, 13, 14, 0, 12, 14, 15, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightSleeve_0_6_up_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(16, 17, 18, 0, 16, 18, 19, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightSleeve_0_6_down_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(20, 21, 22, 0, 20, 22, 23, 0),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_OFF),
    gsDPPipeSync(),
    gsSPEndDisplayList(),
};

Texture steve_leftLeg_0_7_north_texture[] = { "steve/steve_leftLeg_0_7_north.png" };
Texture steve_leftLeg_0_7_south_texture[] = { "steve/steve_leftLeg_0_7_south.png" };
Texture steve_leftLeg_0_7_east_texture[] = { "steve/steve_leftLeg_0_7_east.png" };
Texture steve_leftLeg_0_7_west_texture[] = { "steve/steve_leftLeg_0_7_west.png" };
Texture steve_leftLeg_0_7_up_texture[] = { "steve/steve_leftLeg_0_7_up.png" };
Texture steve_leftLeg_0_7_down_texture[] = { "steve/steve_leftLeg_0_7_down.png" };

Vtx steve_leftLeg_0_7_vtx[24] = {
    {{{-56, -20, -8}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, -20, -8}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, 5, -8}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, 5, -8}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, 5, -32}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, 5, -32}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, -20, -32}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, -20, -32}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, -20, -32}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, -20, -32}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, -20, -8}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, -20, -8}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, 5, -8}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, 5, -8}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, 5, -32}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, 5, -32}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, -20, -8}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, -20, -32}, 0, {96, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, 5, -32}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, 5, -8}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, -20, -32}, 0, {96, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, -20, -8}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, 5, -8}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, 5, -32}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
};

Gfx steve_leftLeg_0_7_dl[] = {
    gsDPPipeSync(),
    gsDPSetTextureFilter(G_TF_POINT),
    gsSPClearGeometryMode(G_LIGHTING),
    gsDPSetCombineMode(G_CC_DECALRGBA, G_CC_DECALRGBA),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_ON),
    gsSPVertex(steve_leftLeg_0_7_vtx, 24, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftLeg_0_7_north_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(0, 1, 2, 0, 0, 2, 3, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftLeg_0_7_south_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(4, 5, 6, 0, 4, 6, 7, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftLeg_0_7_east_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(8, 9, 10, 0, 8, 10, 11, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftLeg_0_7_west_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(12, 13, 14, 0, 12, 14, 15, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftLeg_0_7_up_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(16, 17, 18, 0, 16, 18, 19, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftLeg_0_7_down_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(20, 21, 22, 0, 20, 22, 23, 0),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_OFF),
    gsDPPipeSync(),
    gsSPEndDisplayList(),
};

Texture steve_leftPants_0_8_north_texture[] = { "steve/steve_leftPants_0_8_north.png" };
Texture steve_leftPants_0_8_south_texture[] = { "steve/steve_leftPants_0_8_south.png" };
Texture steve_leftPants_0_8_east_texture[] = { "steve/steve_leftPants_0_8_east.png" };
Texture steve_leftPants_0_8_west_texture[] = { "steve/steve_leftPants_0_8_west.png" };
Texture steve_leftPants_0_8_up_texture[] = { "steve/steve_leftPants_0_8_up.png" };
Texture steve_leftPants_0_8_down_texture[] = { "steve/steve_leftPants_0_8_down.png" };

Vtx steve_leftPants_0_8_vtx[24] = {
    {{{-58, -22, -6}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, -22, -6}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, 6, -6}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, 6, -6}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, 6, -34}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, 6, -34}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, -22, -34}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, -22, -34}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, -22, -34}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, -22, -34}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, -22, -6}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, -22, -6}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, 6, -6}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, 6, -6}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, 6, -34}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, 6, -34}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, -22, -6}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, -22, -34}, 0, {96, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, 6, -34}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, 6, -6}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, -22, -34}, 0, {96, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, -22, -6}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, 6, -6}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, 6, -34}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
};

Gfx steve_leftPants_0_8_dl[] = {
    gsDPPipeSync(),
    gsDPSetTextureFilter(G_TF_POINT),
    gsSPClearGeometryMode(G_LIGHTING),
    gsDPSetCombineMode(G_CC_DECALRGBA, G_CC_DECALRGBA),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_ON),
    gsSPVertex(steve_leftPants_0_8_vtx, 24, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftPants_0_8_north_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(0, 1, 2, 0, 0, 2, 3, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftPants_0_8_south_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(4, 5, 6, 0, 4, 6, 7, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftPants_0_8_east_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(8, 9, 10, 0, 8, 10, 11, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftPants_0_8_west_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(12, 13, 14, 0, 12, 14, 15, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftPants_0_8_up_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(16, 17, 18, 0, 16, 18, 19, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_leftPants_0_8_down_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(20, 21, 22, 0, 20, 22, 23, 0),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_OFF),
    gsDPPipeSync(),
    gsSPEndDisplayList(),
};

Texture steve_rightLeg_0_9_north_texture[] = { "steve/steve_rightLeg_0_9_north.png" };
Texture steve_rightLeg_0_9_south_texture[] = { "steve/steve_rightLeg_0_9_south.png" };
Texture steve_rightLeg_0_9_east_texture[] = { "steve/steve_rightLeg_0_9_east.png" };
Texture steve_rightLeg_0_9_west_texture[] = { "steve/steve_rightLeg_0_9_west.png" };
Texture steve_rightLeg_0_9_up_texture[] = { "steve/steve_rightLeg_0_9_up.png" };
Texture steve_rightLeg_0_9_down_texture[] = { "steve/steve_rightLeg_0_9_down.png" };

Vtx steve_rightLeg_0_9_vtx[24] = {
    {{{-56, 3, 32}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, 3, 32}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, 28, 32}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, 28, 32}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, 28, 8}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, 28, 8}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, 3, 8}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, 3, 8}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, 3, 8}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, 3, 8}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, 3, 32}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, 3, 32}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, 28, 32}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, 28, 32}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, 28, 8}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, 28, 8}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, 3, 32}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, 3, 8}, 0, {96, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, 28, 8}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{19, 28, 32}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, 3, 8}, 0, {96, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, 3, 32}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, 28, 32}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-56, 28, 8}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
};

Gfx steve_rightLeg_0_9_dl[] = {
    gsDPPipeSync(),
    gsDPSetTextureFilter(G_TF_POINT),
    gsSPClearGeometryMode(G_LIGHTING),
    gsDPSetCombineMode(G_CC_DECALRGBA, G_CC_DECALRGBA),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_ON),
    gsSPVertex(steve_rightLeg_0_9_vtx, 24, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightLeg_0_9_north_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(0, 1, 2, 0, 0, 2, 3, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightLeg_0_9_south_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(4, 5, 6, 0, 4, 6, 7, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightLeg_0_9_east_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(8, 9, 10, 0, 8, 10, 11, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightLeg_0_9_west_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(12, 13, 14, 0, 12, 14, 15, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightLeg_0_9_up_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(16, 17, 18, 0, 16, 18, 19, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightLeg_0_9_down_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(20, 21, 22, 0, 20, 22, 23, 0),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_OFF),
    gsDPPipeSync(),
    gsSPEndDisplayList(),
};

Texture steve_rightPants_0_10_north_texture[] = { "steve/steve_rightPants_0_10_north.png" };
Texture steve_rightPants_0_10_south_texture[] = { "steve/steve_rightPants_0_10_south.png" };
Texture steve_rightPants_0_10_east_texture[] = { "steve/steve_rightPants_0_10_east.png" };
Texture steve_rightPants_0_10_west_texture[] = { "steve/steve_rightPants_0_10_west.png" };
Texture steve_rightPants_0_10_up_texture[] = { "steve/steve_rightPants_0_10_up.png" };
Texture steve_rightPants_0_10_down_texture[] = { "steve/steve_rightPants_0_10_down.png" };

Vtx steve_rightPants_0_10_vtx[24] = {
    {{{-58, 2, 34}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, 2, 34}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, 30, 34}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, 30, 34}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, 30, 6}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, 30, 6}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, 2, 6}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, 2, 6}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, 2, 6}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, 2, 6}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, 2, 34}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, 2, 34}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, 30, 34}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, 30, 34}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, 30, 6}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, 30, 6}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, 2, 34}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, 2, 6}, 0, {96, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, 30, 6}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{21, 30, 34}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, 2, 6}, 0, {96, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, 2, 34}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, 30, 34}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-58, 30, 6}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
};

Gfx steve_rightPants_0_10_dl[] = {
    gsDPPipeSync(),
    gsDPSetTextureFilter(G_TF_POINT),
    gsSPClearGeometryMode(G_LIGHTING),
    gsDPSetCombineMode(G_CC_DECALRGBA, G_CC_DECALRGBA),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_ON),
    gsSPVertex(steve_rightPants_0_10_vtx, 24, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightPants_0_10_north_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(0, 1, 2, 0, 0, 2, 3, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightPants_0_10_south_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(4, 5, 6, 0, 4, 6, 7, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightPants_0_10_east_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(8, 9, 10, 0, 8, 10, 11, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightPants_0_10_west_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(12, 13, 14, 0, 12, 14, 15, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightPants_0_10_up_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(16, 17, 18, 0, 16, 18, 19, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_rightPants_0_10_down_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(20, 21, 22, 0, 20, 22, 23, 0),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_OFF),
    gsDPPipeSync(),
    gsSPEndDisplayList(),
};

Texture steve_jacket_0_11_north_texture[] = { "steve/steve_jacket_0_11_north.png" };
Texture steve_jacket_0_11_south_texture[] = { "steve/steve_jacket_0_11_south.png" };
Texture steve_jacket_0_11_east_texture[] = { "steve/steve_jacket_0_11_east.png" };
Texture steve_jacket_0_11_west_texture[] = { "steve/steve_jacket_0_11_west.png" };
Texture steve_jacket_0_11_up_texture[] = { "steve/steve_jacket_0_11_up.png" };
Texture steve_jacket_0_11_down_texture[] = { "steve/steve_jacket_0_11_down.png" };

Vtx steve_jacket_0_11_vtx[24] = {
    {{{-9, -27, 14}, 0, {224, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{70, -27, 14}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{70, 27, 14}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-9, 27, 14}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-9, 27, -14}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{70, 27, -14}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{70, -27, -14}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-9, -27, -14}, 0, {224, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-9, -27, -14}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{70, -27, -14}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{70, -27, 14}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-9, -27, 14}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-9, 27, 14}, 0, {0, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{70, 27, 14}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{70, 27, -14}, 0, {96, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-9, 27, -14}, 0, {96, 352}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{70, -27, 14}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{70, -27, -14}, 0, {224, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{70, 27, -14}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{70, 27, 14}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-9, -27, -14}, 0, {224, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-9, -27, 14}, 0, {224, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-9, 27, 14}, 0, {0, 0}, {0xFF, 0xFF, 0xFF, 0xFF}}},
    {{{-9, 27, -14}, 0, {0, 96}, {0xFF, 0xFF, 0xFF, 0xFF}}},
};

Gfx steve_jacket_0_11_dl[] = {
    gsDPPipeSync(),
    gsDPSetTextureFilter(G_TF_POINT),
    gsSPClearGeometryMode(G_LIGHTING),
    gsDPSetCombineMode(G_CC_DECALRGBA, G_CC_DECALRGBA),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_ON),
    gsSPVertex(steve_jacket_0_11_vtx, 24, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_jacket_0_11_north_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(0, 1, 2, 0, 0, 2, 3, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_jacket_0_11_south_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(4, 5, 6, 0, 4, 6, 7, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_jacket_0_11_east_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(8, 9, 10, 0, 8, 10, 11, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_jacket_0_11_west_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 4, 12, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(12, 13, 14, 0, 12, 14, 15, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_jacket_0_11_up_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(16, 17, 18, 0, 16, 18, 19, 0),
    gsDPPipeSync(),
    gsDPLoadTextureBlock(steve_jacket_0_11_down_texture, G_IM_FMT_RGBA, G_IM_SIZ_16b, 8, 4, 0, G_TX_CLAMP, G_TX_CLAMP, G_TX_NOMASK, G_TX_NOMASK, G_TX_NOLOD, G_TX_NOLOD),
    gsSP2Triangles(20, 21, 22, 0, 20, 22, 23, 0),
    gsSPTexture(0xFFFF, 0xFFFF, 0, G_TX_RENDERTILE, G_OFF),
    gsDPPipeSync(),
    gsSPEndDisplayList(),
};

Gfx steve_Torso_mesh_layer_1[] = {
    gsDPPipeSync(),
    gsSPDisplayList(steve_body_0_0_dl),
    gsSPDisplayList(steve_jacket_0_11_dl),
    gsSPEndDisplayList(),
};

Gfx steve_Head_DL_mesh_layer_1[] = {
    gsDPPipeSync(),
    gsSPDisplayList(steve_head_0_1_dl),
    gsSPDisplayList(steve_hat_0_2_dl),
    gsSPEndDisplayList(),
};

Gfx steve_Left_Arm_Color_mesh_layer_1[] = {
    gsDPPipeSync(),
    gsSPDisplayList(steve_leftArm_0_3_dl),
    gsSPDisplayList(steve_leftSleeve_0_4_dl),
    gsSPEndDisplayList(),
};

Gfx steve_Right_Arm_Color_mesh_layer_1[] = {
    gsDPPipeSync(),
    gsSPDisplayList(steve_rightArm_0_5_dl),
    gsSPDisplayList(steve_rightSleeve_0_6_dl),
    gsSPEndDisplayList(),
};

Gfx steve_Left_Thigh_Color_mesh_layer_1[] = {
    gsDPPipeSync(),
    gsSPDisplayList(steve_leftLeg_0_7_dl),
    gsSPDisplayList(steve_leftPants_0_8_dl),
    gsSPEndDisplayList(),
};

Gfx steve_Right_Thigh_Color_mesh_layer_1_with_layer_1_revert[] = {
    gsDPPipeSync(),
    gsSPDisplayList(steve_rightLeg_0_9_dl),
    gsSPDisplayList(steve_rightPants_0_10_dl),
    gsSPEndDisplayList(),
};

Gfx steve_Capless_Head_Switch_Option_Capless_Head_mesh_layer_1[] = {
    gsDPPipeSync(),
    gsSPDisplayList(steve_head_0_1_dl),
    gsSPEndDisplayList(),
};

Gfx steve_Metal_Mario_Switch_Option_Torso_mesh_layer_1[] = {
    gsSPDisplayList(steve_Torso_mesh_layer_1),
    gsSPEndDisplayList(),
};

Gfx steve_Metal_Mario_Switch_Option_Head_DL_mesh_layer_1[] = {
    gsSPDisplayList(steve_Head_DL_mesh_layer_1),
    gsSPEndDisplayList(),
};

Gfx steve_Metal_Mario_Switch_Option_Capless_Head_Switch_Option_Capless_Head_mesh_layer_1[] = {
    gsSPDisplayList(steve_Capless_Head_Switch_Option_Capless_Head_mesh_layer_1),
    gsSPEndDisplayList(),
};

Gfx steve_Metal_Mario_Switch_Option_Left_Arm_Color_mesh_layer_1[] = {
    gsSPDisplayList(steve_Left_Arm_Color_mesh_layer_1),
    gsSPEndDisplayList(),
};

Gfx steve_Metal_Mario_Switch_Option_Right_Arm_Color_mesh_layer_1[] = {
    gsSPDisplayList(steve_Right_Arm_Color_mesh_layer_1),
    gsSPEndDisplayList(),
};

Gfx steve_Metal_Mario_Switch_Option_Left_Thigh_Color_mesh_layer_1[] = {
    gsSPDisplayList(steve_Left_Thigh_Color_mesh_layer_1),
    gsSPEndDisplayList(),
};

Gfx steve_Metal_Mario_Switch_Option_Right_Thigh_Color_mesh_layer_1_with_layer_1_revert_with_layer_1_revert[] = {
    gsSPDisplayList(steve_Right_Thigh_Color_mesh_layer_1_with_layer_1_revert),
    gsSPEndDisplayList(),
};

Gfx steve_Metal_Mario_Switch_Option_Right_Thigh_Color_mesh_layer_1_with_layer_5_revert_with_layer_5_revert[] = {
    gsSPDisplayList(steve_Right_Thigh_Color_mesh_layer_1_with_layer_1_revert),
    gsSPEndDisplayList(),
};

Gfx steve_Right_Thigh_Color_mesh_layer_1_with_layer_5_revert[] = {
    gsSPDisplayList(steve_Right_Thigh_Color_mesh_layer_1_with_layer_1_revert),
    gsSPEndDisplayList(),
};
