// v3 組立プレビュー
include <v3_params.scad>
use <v3_kb_box.scad>
use <v3_palm_box.scad>
use <v3_center_box.scad>
use <../touchid_pod.scad>

demo_explode = 0;

module v3_place_left() {
    translate([-kb_corner_x, kb_corner_y, 0])
        rotate([0, 0, -splay])
            translate([-kbw, -kbd, 0])
                children();
}

color("slategray") {
    translate([-demo_explode, 0, 0]) v3_place_left() v3_kb_box_left();
    translate([ demo_explode, 0, 0]) mirror([1,0,0]) v3_place_left() v3_kb_box_left();
}
color("lightsteelblue") {
    translate([-demo_explode, -demo_explode, 0]) v3_place_left()
        translate([0, -v3_joint_clr, 0]) v3_palm_box_left();
    translate([ demo_explode, -demo_explode, 0]) mirror([1,0,0]) v3_place_left()
        translate([0, -v3_joint_clr, 0]) v3_palm_box_left();
}
color("dimgray") v3_center_box();
color("steelblue")
    translate([0, pod_y - pod_flange_off, v3_cbox_h + demo_explode]) pod_tray();
color("lightsteelblue")
    translate([0, pod_y - pod_flange_off, v3_cbox_h + 3 + tid_bay_h + 1 + 2*demo_explode]) pod_lid();
