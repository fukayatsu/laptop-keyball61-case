// ベース板(3分割): 左・中央・右
// 継手: 中央ピースの下段ひさし(厚3.6)が左右ピース下面の欠きに入り、
//       上から M3x8 皿ネジ -> ひさし下面の六角ナットポケット で締結
include <lib.scad>

// ---------------- 左ピース ----------------
// ローカル原点=南西角。西端=外側(角R付き)、東端=中央ピースとの継手
module base_left() {
    difference() {
        linear_extrude(base_t)
            union() {
                rounded_rect(base_side_w, base_d, base_corner_r);
                translate([base_side_w - base_corner_r - 0.1, 0])
                    square([base_corner_r + 0.1, base_d]);  // 東端は角を立てる
            }

        // 継手: 下面の欠き(中央ピースのひさしが入る)
        translate([base_side_w - joint_tab_l - clr, -1, -0.01])
            cube([joint_tab_l + clr + 1, base_d + 2, joint_step_t + clr]);

        // 継手ネジ(上から皿)
        for (y = joint_screw_y)
            translate([base_side_w - joint_tab_l/2, y, base_t])
                m3_countersunk(base_t);

        // Tスロット溝 x2 (西端開放 = ナット挿入口)
        for (cy = [ch_rear_y, ch_front_y])
            translate([ch_x0, cy, 0]) t_channel(ch_x1 - ch_x0);
    }
}

// ---------------- 右ピース(左のミラー) ----------------
module base_right() {
    translate([base_side_w, 0, 0]) mirror([1, 0, 0]) base_left();
}

// ---------------- 中央ピース ----------------
// ローカル原点=コア部の南西角。両側に下段ひさし付き
module base_center() {
    difference() {
        union() {
            linear_extrude(base_t) square([base_center_w, base_d]);
            // 下段ひさし(左右)
            translate([-joint_tab_l, 0, 0])
                cube([joint_tab_l + 0.1, base_d, joint_step_t]);
            translate([base_center_w - 0.1, 0, 0])
                cube([joint_tab_l + 0.1, base_d, joint_step_t]);
        }

        // 継手ネジ穴 + ナットポケット(ひさし下面)
        for (y = joint_screw_y, sx = [-joint_tab_l/2, base_center_w + joint_tab_l/2]) {
            translate([sx, y, -1]) cylinder(d = m3_hole_d, h = joint_step_t + 2);
            translate([sx, y, 0]) m3_nut_pocket();
        }

        // Touch ID ポッド固定穴 + ナットポケット(下面)
        for (sx = [-pod_screw_span/2, pod_screw_span/2]) {
            translate([base_center_w/2 + sx, pod_y, -1]) cylinder(d = m3_hole_d, h = base_t + 2);
            translate([base_center_w/2 + sx, pod_y, 0]) m3_nut_pocket();
        }

        // ケーブル用ベルクロスロット(北端付近)
        for (sx = [-25, 25])
            translate([base_center_w/2 + sx - 6, 199, -1]) cube([12, 4, base_t + 2]);
    }
}
