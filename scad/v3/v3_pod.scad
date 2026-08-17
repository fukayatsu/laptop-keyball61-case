// v3 Touch ID ポッド: 幅の細い中央箱(間隔5cm短縮)用のフランジレス版。
// デッキへの固定はベイ床からの M3x8皿 x4 セルフタップ(頭はベイ床にツライチ、
// モジュールを入れる前に締める)。バッテリー版はなし——バッテリーは中央箱の
// 内部に結束バンドで固定する。
// 蓋ネジボスは南側の東西2 + 北壁1(ケーブルスリットx±7.5を避けてx=-14)。
// 原点=ベイ中心(XY), z=0 = 底面
include <v3_params.scad>

v3pod_w = tid_bay_w + 2 * tid_wall;   // 40
v3pod_d = 88 + 2 * tid_wall;          // 94 (モジュール版ベイ88固定)
v3pod_floor = 3;
v3pod_h = v3pod_floor + 4 + 1;        // 8 (壁天面=蓋座面)
v3pod_boss_d = 10;

// 蓋ネジボス位置 [x, y] (壁に3mm食い込ませて一体化)
function v3pod_bosses() = [
    [ (v3pod_w/2 + v3pod_boss_d/2 - 3), -30],
    [-(v3pod_w/2 + v3pod_boss_d/2 - 3), -30],
    [-14, v3pod_d/2 + v3pod_boss_d/2 - 3]
];

// トレイ天面/蓋の共通フットプリント: コア + ボスローブ(壁沿いガセット)
module v3pod_fp2d() {
    translate([-v3pod_w/2, -v3pod_d/2]) square([v3pod_w, v3pod_d]);
    for (p = v3pod_bosses())
        hull() {
            translate(p) circle(d = v3pod_boss_d);
            if (abs(p[0]) > v3pod_w/2 - 1)  // 東西壁のボス
                translate([sign(p[0]) * (v3pod_w/2 - 1), p[1] - v3pod_boss_d])
                    square([1, 2 * v3pod_boss_d]);
            else                             // 北壁のボス
                translate([p[0] - v3pod_boss_d, v3pod_d/2 - 1])
                    square([2 * v3pod_boss_d, 1]);
        }
}

module v3_pod_tray() {
    difference() {
        linear_extrude(v3pod_h) v3pod_fp2d();

        // ベイ
        translate([-tid_bay_w/2, -88/2, v3pod_floor]) cube([tid_bay_w, 88, 50]);

        // 基板取り出し用フィンガーノッチ(東西壁, 外壁1mm残し)
        for (sx = [-1, 1])
            translate([sx * (tid_bay_w/2 - 2.5), 15, v3pod_floor])
                cylinder(d = 9, h = 50);

        // ケーブル引き出しスリット(北壁, 幅15)
        translate([-7.5, 88/2 - 1, v3pod_floor]) cube([15, tid_wall + 2, 50]);

        // 充電ポート開口(南面, 上開きU字スロット)
        if (tid_port_w > 0)
            translate([tid_port_off - tid_port_w/2, -v3pod_d/2 - 2, v3pod_floor])
                cube([tid_port_w, tid_wall + 4, 50]);

        // 蓋ネジ下穴(M3セルフタップ)
        for (p = v3pod_bosses())
            translate([p[0], p[1], v3pod_h - 8]) cylinder(d = 2.6, h = 9);

        // デッキ固定ネジ(ベイ床, M3x8皿。頭は床にツライチ=モジュールの下)
        for (s = v3pod_floor_screws)
            translate([s[0], s[1], v3pod_floor]) m3_countersunk(v3pod_floor + 1);
    }
}

module v3_pod_lid() {
    hole = tid_btn_w + 2 * clr;
    difference() {
        linear_extrude(tid_lid_t) v3pod_fp2d();
        if (tid_btn_in_lid) {
            translate([tid_btn_x - hole/2, tid_btn_y - hole/2, -1])
                cube([hole, hole, tid_lid_t + 2]);
        }
        for (p = v3pod_bosses())
            translate([p[0], p[1], tid_lid_t]) m3_countersunk(tid_lid_t);
    }
}

// 印刷用: tray と lid を並べる
module v3_pod_print_plate() {
    v3_pod_tray();
    translate([v3pod_w + 20, 0, 0]) v3_pod_lid();
}
