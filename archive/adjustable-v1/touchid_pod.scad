// Touch ID ポッド: 摘出済み Magic Keyboard モジュールを収める中央ドック
// 実測: 基板 85x31x3(長辺を前後に収納) / ボタン 16x16x3(基板上に載る想定) / ポート 19x3.1(北面)
//
// 構成: tray(本体) + lid(蓋)。蓋は対角2箇所のボスへ M3x8 皿(セルフタップ)。
// トレイはベース中央ピースへ M3x12 なべ + ナット(ベース下面ポケット) x2 で固定。
// 原点 = ベイ中心(XY), z=0 = 底面
include <lib.scad>

pod_core_w = tid_bay_w + 2 * tid_wall;
pod_core_d = tid_bay_d + 2 * tid_wall;
pod_floor_t = 3;
pod_h = pod_floor_t + tid_bay_h + 1;      // 壁天面 = 蓋座面
pod_flange_t = 4;
pod_flange_ext = 12;                       // フランジ張り出し(東西)
pod_boss_d = 9;                            // 蓋ネジボス(対角: 北東+南西)
pod_boss_y = 30;                           // ボス中心の前後オフセット

// ボス中心位置 [x, y] (北東と南西の対角)
function boss_pos() = [
    [ (pod_core_w/2 + pod_boss_d/2 - 1),  pod_boss_y],
    [-(pod_core_w/2 + pod_boss_d/2 - 1), -pod_boss_y]
];

module pod_tray() {
    difference() {
        union() {
            // コア
            translate([-pod_core_w/2, -pod_core_d/2, 0])
                cube([pod_core_w, pod_core_d, pod_h]);
            // ベース固定フランジ(東西)
            translate([-pod_core_w/2 - pod_flange_ext, -pod_core_d/2, 0])
                cube([pod_core_w + 2*pod_flange_ext, pod_core_d, pod_flange_t]);
            // 蓋ネジボス
            for (p = boss_pos())
                translate([p[0], p[1], 0]) cylinder(d = pod_boss_d, h = pod_h);
            // ボタン台座(オプション)
            if (tid_pedestal_h > 0)
                translate([tid_btn_x - 6, tid_btn_y - 6, 0])
                    cube([12, 12, pod_floor_t + tid_pedestal_h]);
        }

        // ベイ
        translate([-tid_bay_w/2, -tid_bay_d/2, pod_floor_t])
            cube([tid_bay_w, tid_bay_d, 50]);

        // 基板取り出し用フィンガーノッチ(東西壁, 外壁1mm残し)
        for (sx = [-1, 1])
            translate([sx * (tid_bay_w/2 - 2.5), 15, pod_floor_t])
                cylinder(d = 9, h = 50);

        // 充電ポート開口(北面) tid_port_w=0 で無効
        // バッテリー版は基板が電池の上に載る分だけ開口も上がる
        if (tid_port_w > 0)
            translate([tid_port_off - tid_port_w/2, 0,
                       pod_floor_t + (tid_battery ? tid_bat_t : 0)])
                cube([tid_port_w, pod_core_d/2 + 1, tid_port_h]);

        // 蓋ネジ下穴(M3セルフタップ)
        for (p = boss_pos())
            translate([p[0], p[1], 1]) cylinder(d = 2.6, h = pod_h);

        // ベース固定ネジ穴(フランジ) ※ベース側の穴位置は両バージョン共通
        for (sx = [-1, 1])
            translate([sx * pod_screw_span/2, pod_flange_off, -1])
                cylinder(d = m3_hole_d, h = pod_flange_t + 2);
    }
}

module pod_lid() {
    hole = tid_btn_w + 2 * clr;
    difference() {
        union() {
            translate([-pod_core_w/2, -pod_core_d/2, 0])
                cube([pod_core_w, pod_core_d, tid_lid_t]);
            for (p = boss_pos())
                translate([p[0], p[1], 0]) cylinder(d = pod_boss_d, h = tid_lid_t);
        }
        // センサーボタン角穴 + 指を誘う面取り
        translate([tid_btn_x - hole/2, tid_btn_y - hole/2, -1])
            cube([hole, hole, tid_lid_t + 2]);
        hull() {
            translate([tid_btn_x - hole/2, tid_btn_y - hole/2, tid_lid_t/2])
                cube([hole, hole, 1]);
            translate([tid_btn_x - hole/2 - 1.5, tid_btn_y - hole/2 - 1.5, tid_lid_t])
                cube([hole + 3, hole + 3, 1]);
        }
        // 蓋ネジ(皿)
        for (p = boss_pos())
            translate([p[0], p[1], tid_lid_t]) m3_countersunk(tid_lid_t);
    }
}

// 印刷用: tray と lid を並べる
module pod_print_plate() {
    pod_tray();
    translate([pod_core_w + 2*pod_flange_ext + 15, 0, 0]) pod_lid();
}
