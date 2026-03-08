Texture spritesheet3d_rgba16[] = {
	#include "actors/spritesheet3d/spritesheet3d.rgba16.inc.c"
};

Vtx spritesheet3d_vtx[4] = {
	{{{-100, -100, 0}, 0, { -15, 8177}, {0x00, 0x00, 0x81, 0xFF}}},
	{{{-100,  100, 0}, 0, { -15,  -15}, {0x00, 0x00, 0x81, 0xFF}}},
	{{{ 100,  100, 0}, 0, {8177,  -15}, {0x00, 0x00, 0x81, 0xFF}}},
	{{{ 100, -100, 0}, 0, {8177, 8177}, {0x00, 0x00, 0x81, 0xFF}}},
};

Gfx spritesheet3d_color_dl[] = {
    gsDPSetEnvColor(255, 255, 255, 255),
    gsSPEndDisplayList(),
};

Gfx spritesheet3d_dl[] = {
	gsSPSetGeometryMode(G_LIGHTING),

	// material
	gsSPClearGeometryMode(G_CULL_BACK),
	gsDPPipeSync(),
	gsDPSetCombineLERP(TEXEL0, 0, ENVIRONMENT, 0, TEXEL0, 0, ENVIRONMENT, 0, TEXEL0, 0, ENVIRONMENT, 0, TEXEL0, 0, ENVIRONMENT, 0),
	gsDPSetAlphaDither(G_AD_NOISE),
	gsSPTexture(65535, 65535, 0, 0, 1),
	gsDPSetTextureImage(G_IM_FMT_RGBA, G_IM_SIZ_16b_LOAD_BLOCK, 1, spritesheet3d_rgba16),
	gsDPSetTile(G_IM_FMT_RGBA, G_IM_SIZ_16b_LOAD_BLOCK, 0, 0, 7, 0, G_TX_WRAP | G_TX_NOMIRROR, 0, 0, G_TX_WRAP | G_TX_NOMIRROR, 0, 0),
	gsDPLoadBlock(7, 0, 0, 65535, 32),
	gsDPSetTile(G_IM_FMT_RGBA, G_IM_SIZ_16b, 64, 0, 0, 0, G_TX_WRAP | G_TX_NOMIRROR, 8, 0, G_TX_WRAP | G_TX_NOMIRROR, 8, 0),
	gsDPSetTileSize(0, 0, 0, 1020, 1020),

	// quad
	gsSPVertex(spritesheet3d_vtx + 0, 4, 0),
	gsSP2Triangles(0, 1, 2, 0, 0, 2, 3, 0),

	// material revert
	gsSPSetGeometryMode(G_CULL_BACK),
	gsDPPipeSync(),
	gsDPSetAlphaDither(G_AD_DISABLE),

	// more revert
	gsDPPipeSync(),
	gsSPSetGeometryMode(G_LIGHTING),
	gsSPClearGeometryMode(G_TEXTURE_GEN),
	gsDPSetCombineLERP(0, 0, 0, SHADE, 0, 0, 0, ENVIRONMENT, 0, 0, 0, SHADE, 0, 0, 0, ENVIRONMENT),
	gsSPTexture(65535, 65535, 0, 0, 0),
	gsDPSetEnvColor(255, 255, 255, 255),
	gsDPSetAlphaCompare(G_AC_NONE),
	gsSPEndDisplayList(),
};
