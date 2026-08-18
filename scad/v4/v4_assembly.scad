// v4 組立ビュー(プレビュー/ドキュメント画像用)。
// openscad scad/v4/v4_assembly.scad で確認、-D explode=40 で分解図
include <v4_plate.scad>
use <v4_center_spine.scad>
use <v4_center_cover.scad>

explode = 0;

module v4_place_plate_left() {
    translate([-v4_corner_x, kb_corner_y, 0]) rotate([0, 0, -splay])
        translate([-kbw, -kbd, 0]) rotate([0, -tent_angle, 0]) children();
}

translate([-explode, 0, explode/2]) color("lightsteelblue")
    v4_place_plate_left() v4_plate_left();
translate([explode, 0, explode/2]) color("lightsteelblue")
    mirror([1, 0, 0]) v4_place_plate_left() v4_plate_left();
color("dimgray") v4_center_spine();
color("slategray") translate([0, 0, -explode/2]) v4_center_cover();
