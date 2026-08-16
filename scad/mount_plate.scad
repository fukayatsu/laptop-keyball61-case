// マウントプレート: アクリル底板と同形状の2mm板(ベッド直接印刷で精度を出す)。
// 組立順: 先にプレート単体をサイドのポケットへ落として M3x8皿 x4 で上から固定し、
// その後キーボードを載せてサイド底面のΦ8貫通穴から純正ネジを下から締める。
// 座標系 = プレート座標系(反転済み・左手ユニット)。右手用はミラー。
include <lib.scad>

module mount_plate_left() {
    difference() {
        linear_extrude(plate_t) plate2d(0);

        for (h = plate_holes_f) {
            if (h[2] > 1.9 && h[2] < 2.35)   // M2
                translate([h[0], h[1], -1]) cylinder(d = m2_hole_d, h = plate_t + 2);
            if (h[2] >= 2.35 && h[2] < 4)    // ボールケースネジ
                translate([h[0], h[1], -1]) cylinder(d = bc_hole_d, h = plate_t + 2);
            if (h[2] > 10)                   // ボール取出し穴
                translate([h[0], h[1], -1]) cylinder(d = h[2], h = plate_t + 2);
        }

        // サイド固定ネジ(M3皿, 頭は上面ツライチ)
        for (s = plate_screws)
            translate([s[0], s[1], plate_t]) m3_countersunk(plate_t + 1);
    }
}

module mount_plate_right() {
    mirror([1, 0, 0]) mount_plate_left();
}
