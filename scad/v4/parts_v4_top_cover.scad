include <v4_top_cover.scad>
// 天面をベッドに伏せて印刷(切欠き・逃げ・柱の斜面は上向き=サポート不要)
translate([0, 0, v4tc_top_z]) rotate([180, 0, 0]) v4_top_cover();
