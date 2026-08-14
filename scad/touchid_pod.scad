// Touch ID ポッド: 摘出済み Magic Keyboard モジュールを収める中央ドック
// 実測: 基板 85x31x3(長辺を前後に収納) / ボタン 16x16x3(基板上に載る想定) / ポート 19x3.1(南面)
//
// 構成: tray(本体) + lid(蓋)。
//  - 蓋ネジボスは壁に埋め込んだ台形ガセット付きで補強(対角2箇所, M3x8皿セルフタップ)
//  - 北側に TRS ケーブルギャラリー(蓋付き配線溝, 東西貫通)。左右キーボード間の
//    TRS ケーブル中央部をポッド内に隠し、余長も収納できる
//  - トレイはブリッジへ M3x12なべ + ナット(ブリッジ下面ポケット) x2 で固定
// 原点 = ベイ中心(XY), z=0 = 底面
include <lib.scad>

pod_core_w = tid_bay_w + 2 * tid_wall;
pod_core_d = tid_bay_d + 2 * tid_wall;
pod_floor_t = 3;
pod_h = pod_floor_t + tid_bay_h + 1;      // 壁天面 = 蓋座面
pod_flange_t = 4;
pod_flange_ext = 12;
pod_boss_d = 10;                           // 蓋ネジボス径
pod_boss_y = 30;                           // ボス中心の前後オフセット
gal_d_out = gal_ch + gal_wall;             // ギャラリーの北への張り出し

// ボス中心位置 [x, y] (北東と南西の対角, 壁に3mm食い込ませて一体化)
function boss_pos() = [
    [ (pod_core_w/2 + pod_boss_d/2 - 3),  pod_boss_y],
    [-(pod_core_w/2 + pod_boss_d/2 - 3), -pod_boss_y]
];

// トレイ天面/蓋の共通フットプリント: コア + ギャラリー + ボスローブ(ガセット)
module pod_fp2d() {
    translate([-pod_core_w/2, -pod_core_d/2])
        square([pod_core_w, pod_core_d + gal_d_out]);
    for (p = boss_pos())
        hull() {
            translate(p) circle(d = pod_boss_d);
            // 壁に沿った台形ガセット
            translate([sign(p[0]) * (pod_core_w/2 - 1), p[1] - pod_boss_d, 0])
                square([1, 2 * pod_boss_d], center = false);
        }
}

module pod_tray() {
    difference() {
        union() {
            linear_extrude(pod_h) pod_fp2d();
            // ブリッジ固定フランジ(東西)
            translate([-pod_core_w/2 - pod_flange_ext, -pod_core_d/2, 0])
                cube([pod_core_w + 2*pod_flange_ext, pod_core_d, pod_flange_t]);
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

        // TRSケーブルギャラリー(東西貫通, 蓋がカバーになる)
        translate([-pod_core_w/2 - 20, pod_core_d/2, gal_floor])
            cube([pod_core_w + 40, gal_ch, 50]);

        // 充電ポート開口(南面) tid_port_w=0 で無効
        // バッテリー版は基板が電池の上に載る分だけ開口も上がる
        if (tid_port_w > 0)
            translate([tid_port_off - tid_port_w/2, -pod_core_d/2 - 10,
                       pod_floor_t + (tid_battery ? tid_bat_t : 0)])
                cube([tid_port_w, 11, tid_port_h]);

        // 蓋ネジ下穴(M3セルフタップ)
        for (p = boss_pos())
            translate([p[0], p[1], pod_h - 8]) cylinder(d = 2.6, h = 9);

        // ブリッジ固定ネジ穴(フランジ, M3x8皿・継手と共通) ※ブリッジ側の穴位置は両バージョン共通
        for (sx = [-1, 1])
            translate([sx * pod_screw_span/2, pod_flange_off, pod_flange_t])
                m3_countersunk(pod_flange_t);
    }
}

module pod_lid() {
    hole = tid_btn_w + 2 * clr;
    difference() {
        linear_extrude(tid_lid_t) pod_fp2d();
        // センサーボタン角穴 + 指を誘う面取り (tid_btn_in_lid = true の場合のみ)
        if (tid_btn_in_lid) {
            translate([tid_btn_x - hole/2, tid_btn_y - hole/2, -1])
                cube([hole, hole, tid_lid_t + 2]);
            hull() {
                translate([tid_btn_x - hole/2, tid_btn_y - hole/2, tid_lid_t/2])
                    cube([hole, hole, 1]);
                translate([tid_btn_x - hole/2 - 1.5, tid_btn_y - hole/2 - 1.5, tid_lid_t])
                    cube([hole + 3, hole + 3, 1]);
            }
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
