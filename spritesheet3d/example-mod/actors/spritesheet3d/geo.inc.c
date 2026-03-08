
const GeoLayout spritesheet3d_geo[] = {
	GEO_NODE_START(),
	GEO_OPEN_NODE(),
		GEO_ASM(0, geo_spritesheet3d_update),
		GEO_DISPLAY_LIST(LAYER_TRANSPARENT, spritesheet3d_color_dl),
		GEO_DISPLAY_LIST(LAYER_TRANSPARENT, spritesheet3d_dl),
	GEO_CLOSE_NODE(),
	GEO_END(),
};
