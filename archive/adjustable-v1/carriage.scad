// キャリッジ: キーボードポケット + パームレスト + 固定テンティング楔
// 左キャリッジ基準(x=0 が外側=低い側, 内側ほど高い)。右は mirror。
include <lib.scad>

module carriage_left() {
    union() {
    difference() {
        // 楔本体
        intersection() {
            linear_extrude(60) rounded_rect(car_w, car_d, car_corner_r);
            halfspace_below_top(0);
        }

        // ---- キーボードポケット ----
        intersection() {
            translate([pocket_x0, pocket_y0, -1]) linear_extrude(80) plate2d(clr);
            halfspace_above_top(-pocket_depth);
        }

        // ---- 取り出し用サムノッチ(南壁) ----
        intersection() {
            translate([pocket_x0 + notch_plate_x, pocket_y0 + notch_plate_y, -1])
                cylinder(d = 20, h = 80);
            halfspace_above_top(-pocket_depth);
        }

        // ---- ボール取出し穴 ----
        translate([pocket_x0 + ball_x, pocket_y0 + ball_y, -1])
            cylinder(d = ball_hole_d, h = 80);

        // ---- ピボット(M4ノブ) ----
        translate([knob_x, pivot_y, -1]) cylinder(d = knob_hole_d, h = 80);
        translate([knob_x, pivot_y, seat_floor]) cylinder(d = seat_d, h = 80);

        // ---- ロックスロット(M4ノブ) ----
        translate([knob_x, 0, 0]) slot_y(lock_y_min, lock_y_max, knob_hole_d);
        translate([knob_x, 0, 0]) slot_y(lock_y_min, lock_y_max, seat_d, seat_floor, 80);

        // ---- M2 固定穴(オプション用) 下から座ぐり ----
        for (h = plate_holes)
            if (h[2] > 1.9 && h[2] < 2.2) {
                hx = pocket_x0 + h[0];
                hy = pocket_y0 + h[1];
                translate([hx, hy, -1]) cylinder(d = m2_hole_d, h = 80);
                translate([hx, hy, -1]) cylinder(d = m2_cb_d, h = 1 + pocket_floor_z(hx) - m2_remain);
            }
    }
    hooks();
    }
}

// ボール取出し穴のプレート座標
ball_x = plate_holes[0][0];
ball_y = plate_holes[0][1];

// サムノッチ位置(プレート座標系, 南端直線部)
notch_plate_x = 105;
notch_plate_y = 8;

// 北側フック: 断面(y,z)ポリゴンをX方向に押し出し
module hooks() {
    edge_y = pocket_y0 + 99.93;  // プレート北端(x=5..65で直線)
    for (hx = hook_plate_x) {
        cx = pocket_x0 + hx;
        zu = pocket_floor_z(cx) + hook_gap;
        zt = zu + hook_h;
        translate([cx - hook_w/2, 0, 0])
            rotate([90, 0, 90])
                linear_extrude(hook_w)
                    polygon([
                        [edge_y + hook_anchor, zu],
                        [edge_y - hook_overhang/2, zu],
                        [edge_y - hook_overhang, zu + hook_overhang/2],
                        [edge_y - hook_overhang, zt],
                        [edge_y + hook_anchor, zt]
                    ]);
    }
}

module carriage_right() {
    translate([car_w, 0, 0]) mirror([1, 0, 0]) carriage_left();
}
