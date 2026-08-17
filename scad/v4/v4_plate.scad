// v4 サイドプレート: キーボード搭載部+パームレスト+中央張り出しの一体2mm平板。
// 完全な平面(下面フラット)でベッドにベタ置き印刷。キーボードフェンス(6mm)が
// 上に立つだけなのでサポート不要。
// 組立時は 外側エッジが接地・内側が7°持ち上がる(テント角は中央箱の屋根が作る)。
//
// ローカル座標 = 斜面沿いの実寸(sx = kbローカルx / cos(tent), sy = kbローカルy)。
// 外形はキーボード矩形とパーム矩形のhull(角丸矩形同士なので輪郭は自動的に滑らか)。
// ボール部品の張り出し帯(実機知見)は貫通欠き取り——テントで浮くので
// プレート下にはみ出しても接地しない。
include <v4_params.scad>

v4p_ox = kb_wall / cos(tent_angle);   // 外形(アクリル座標)の配置オフセット
v4p_oy = kb_wall;

// 平面視でkbローカルxをプレート座標へ
function v4sx(x) = x / cos(tent_angle);

module v4_plate_fp2d() {
    hull() {
        rounded_rect(v4sx(kbw + v4_ovl), kbd, 6);
        translate([v4sx(palm_x0), -(palm_d - palm_overlap)])
            rounded_rect(v4sx(palm_w), palm_d, palm_r);
    }
}

module v4_plate_left() {
    difference() {
        union() {
            // 平板
            linear_extrude(v4_pt) v4_plate_fp2d();
            // キーボードフェンス(外形+0.5..+3の帯のうち、西/北/南の一部)
            translate([v4p_ox, v4p_oy, 0]) linear_extrude(v4_pt + v4_rim_h)
                intersection() {
                    difference() {
                        offset(r = 0.5 + v4_rim_t) plate2d(0);
                        offset(r = 0.5) plate2d(0);
                    }
                    union() {
                        translate([-10, -10]) square([16, plate_d + 20]);      // 西
                        translate([-10, plate_d - 8]) square([65, 20]);        // 北西(MCU/USB回避)
                        translate([120, plate_d - 8]) square([40, 20]);        // 北東
                        translate([-10, -10]) square([50, 18]);                // 南西
                    }
                }
        }

        // キーボード取付穴
        translate([v4p_ox, v4p_oy, 0]) {
            for (h = plate_holes_f) {
                if (h[2] > 1.9 && h[2] < 2.35)   // M2
                    translate([h[0], h[1], -1]) cylinder(d = m2_hole_d, h = 20);
                if (h[2] >= 2.35 && h[2] < 4)    // ボールケースネジ
                    translate([h[0], h[1], -1]) cylinder(d = bc_hole_d, h = 20);
                if (h[2] > 10)                   // ボール取出し穴
                    translate([h[0], h[1], -1]) cylinder(d = h[2], h = 20);
            }
            // ボール張り出し帯の貫通欠き取り(v4_ball_relief=true時のみ。既定は埋める)
            if (v4_ball_relief)
                translate([0, 0, -1]) linear_extrude(20) difference() {
                    translate([40, -kb_wall - 1])
                        square([(149.49 - kb_wall) / cos(tent_angle) - 40, 47 + kb_wall + 1]);
                    plate2d(0.5);
                }
        }

        // 中央ジョイント穴(縦M3なべ用ストレート穴, 屋根フランジのネジ軸位置)
        for (jy = v4_cj_ys)
            translate([v4sx(kbw + 6), v4_jyl(jy), -1]) cylinder(d = 3.4, h = 20);
    }
}

module v4_plate_right() { mirror([1, 0, 0]) v4_plate_left(); }
