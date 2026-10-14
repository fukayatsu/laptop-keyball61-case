// v4 組立ビュー(プレビュー/ドキュメント画像用)。
// openscad scad/v4/v4_assembly.scad で確認、-D explode=40 で分解図
include <v4_plate.scad>
use <v4_bottom_plate.scad>
use <v4_center_spine.scad>
use <v4_top_cover.scad>

explode = 0;

module side(m) mirror([m, 0, 0]) {
    translate([-explode, 0, explode/2]) {
        color("lightsteelblue") v4_place_plate_left() v4_plate_left();
        color("burlywood") translate([0, 0, explode/2])
            v4_place_plate_left() translate([0, 0, v4_pt]) v4_bottom_plate_left();
    }
}
side(0);
side(1);
color("dimgray") translate([0, 0, -explode/2]) v4_center_spine();
color("seagreen", 0.85) translate([0, 0, explode * 1.5]) v4_top_cover();
