include <v3_palm_box.scad>
// 天面をベッドに伏せて印刷(180°+tent 回転)
rotate([0, 180 + tent_angle, 0]) v3_palm_box_left();
