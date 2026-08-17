// v4 センターカバー: スパインの下の空間(z1..13.5)を覆う薄いカバー。
// スパインの底面フラットがそのまま蓋(天井)になり、内側の空間(深さ約10mm)に
// ケーブルやTouch IDモジュール等を収められる(スパインの結束バンドスロットで固定)。
//  - 底2mm+スカート壁2mm。スパイン外形の-1mmに収まる
//  - 取付: 下からM3x8なべ x4。頭はボス内の深座ぐりに沈み、ボス上端3mmの肉を
//    貫通してスパイン底面の下穴へセルフタップ(掛かり約5mm)
//  - ケーブルノッチ: 北縁(USB)と東西縁(TRSジャック付近, プレート下に隠れる)
// 印刷: 底をベッドに置いてそのまま(サポート不要)
include <v4_center_spine.scad>

v4_cover_z0 = 1;      // 底の下面(接地1mmクリア)
v4_cover_t  = 2;      // 底/壁の厚さ
v4_cover_rim = v4_spine_z0 - 0.05;   // 縁の上端(スパイン底面-0.05)

module v4_center_cover() {
    difference() {
        union() {
            // 底+スカート壁
            difference() {
                translate([0, 0, v4_cover_z0])
                    linear_extrude(v4_cover_rim - v4_cover_z0)
                        offset(delta = -1) v4_spine_fp2d();
                translate([0, 0, v4_cover_z0 + v4_cover_t])
                    linear_extrude(20)
                        offset(delta = -(1 + v4_cover_t)) v4_spine_fp2d();
            }
            // 取付ボス(Φ10筒, 底から縁まで)
            for (s = v4_case_screws)
                translate([s[0], s[1], v4_cover_z0])
                    cylinder(d = 10, h = v4_cover_rim - v4_cover_z0);
        }

        // 取付ネジ穴: Φ3.4貫通 + Φ7深座ぐり(ボス上端3mmの肉を残す)
        for (s = v4_case_screws) {
            translate([s[0], s[1], v4_cover_z0 - 1]) cylinder(d = 3.4, h = 20);
            translate([s[0], s[1], v4_cover_z0 - 1])
                cylinder(d = 7, h = 1 + (v4_cover_rim - v4_cover_z0) - 3);
        }

        // ケーブルノッチ(縁から下へ8mm): 北=USB出口
        translate([-7, v4_y1 - 12, v4_cover_rim - 8]) cube([14, 12, 10]);
        // 東西=TRSジャック付近(プレートの下に隠れる)
        for (m = [0, 1]) mirror([m, 0, 0]) v4_place_left()
            translate([kbw - 6, v4_jyl(181) - 7, v4_cover_rim - 8]) cube([12, 14, 10]);
    }
}
