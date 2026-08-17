// v3 取付プレート: フレーム内周に落とす長方形(ベッド直接印刷2mm)。
// v2のアクリル外形と違い、フレーム周壁の内側いっぱいまで広げた長方形。
// ただし以下の2箇所は欠き取り:
//  - ボール部品の張り出し帯(kb x>=46・南側, 実機知見): 外形+0.5の外側
//  - パームジョイント受けボス帯の上(kb x 11..47.5, y<9)
// 座標系 = v2プレート座標系(外形bboxのSW原点。斜面に沿った実寸)。右手用はミラー。
include <v3_params.scad>

v3p_clr = 0.5;
// 長方形の範囲(kb水平座標 -> 斜面沿い座標は /cos(tent))
v3p_x0 = (v3_wall + v3p_clr - kb_wall) / cos(tent_angle);
v3p_x1 = (kbw - v3_wall - v3p_clr - kb_wall) / cos(tent_angle);
v3p_y0 = v3_wall + v3p_clr - kb_wall;
v3p_y1 = kbd - v3_wall - v3p_clr - kb_wall;

module v3_plate_left() {
    difference() {
        linear_extrude(plate_t) difference() {
            translate([v3p_x0, v3p_y0])
                rounded_rect(v3p_x1 - v3p_x0, v3p_y1 - v3p_y0, 3);
            // ボール張り出し帯の欠き取り(外形+0.5の外側のみ)
            difference() {
                translate([40, v3p_y0 - 1])
                    square([(149.49 - kb_wall)/cos(tent_angle) - 40, 47 - v3p_y0 + 1]);
                plate2d(0.5);
            }
            // パームジョイント受けボス帯の上の南縁欠き取り
            translate([(11 - kb_wall)/cos(tent_angle), v3p_y0 - 1])
                square([(47.5 - 11)/cos(tent_angle), 3 - v3p_y0 + 1]);
        }

        // キーボード取付穴(v2プレートと同じ)
        for (h = plate_holes_f) {
            if (h[2] > 1.9 && h[2] < 2.35)   // M2
                translate([h[0], h[1], -1]) cylinder(d = m2_hole_d, h = plate_t + 2);
            if (h[2] >= 2.35 && h[2] < 4)    // ボールケースネジ
                translate([h[0], h[1], -1]) cylinder(d = bc_hole_d, h = plate_t + 2);
            if (h[2] > 10)                   // ボール取出し穴
                translate([h[0], h[1], -1]) cylinder(d = h[2], h = plate_t + 2);
        }

        // フレーム固定ネジ(M3x8皿, 井桁交点のΦ8ボスへセルフタップ)
        for (s = v3_plate_screws)
            translate([(s[0] - kb_wall)/cos(tent_angle), s[1] - kb_wall, plate_t])
                m3_countersunk(plate_t + 1);
    }
}

module v3_plate_right() { mirror([1, 0, 0]) v3_plate_left(); }
