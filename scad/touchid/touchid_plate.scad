// Touch ID モジュール取付プレート
// 底面が完全な平面なので、そのままベタ置きで印刷できる。
// 天面中央のボスは0.15mmしかないため積層0.15mm以下で印刷すること。
include <../params.scad>
include <touchid_params.scad>

// 外形: 角Rの異なる丸角矩形 - 南辺の切欠き
module touchid_outline_2d() {
    rc = touchid_r_corner;
    difference() {
        hull() {
            translate([rc, rc])                              circle(r = rc);
            translate([touchid_plate_w - rc, rc])             circle(r = rc);
            translate([touchid_plate_w - rc, touchid_plate_d - rc]) circle(r = rc);
            translate([touchid_r_nw, touchid_plate_d - touchid_r_nw])
                circle(r = touchid_r_nw);
        }
        translate([touchid_notch_x[0], -1])
            square([touchid_notch_x[1] - touchid_notch_x[0], 1 + touchid_notch_d]);
    }
}

module touchid_plate(hole_d = touchid_hole_d) {
    difference() {
        union() {
            linear_extrude(touchid_plate_t) touchid_outline_2d();
            translate([touchid_hole_cx, touchid_hole_cy, touchid_plate_t])
                cylinder(d = touchid_boss_d, h = touchid_boss_h);
        }
        for (h = touchid_holes)
            translate([h[0], h[1], -1])
                cylinder(d = hole_d, h = touchid_plate_t + 2);
    }
}
