include <v4_center_cover.scad>
// 底をベッドに置いて印刷(サポート不要)
translate([0, 0, -v4_cover_z0]) v4_center_cover();
