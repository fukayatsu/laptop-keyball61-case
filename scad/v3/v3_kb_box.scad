// v3 KBフレーム(シンプル化版):
//   段付き周壁(外リム=楔上面 / 内側4mm座リブ=プレート座面) + 井桁壁(x2+y2)。
//   天板なし=長方形マウントプレート(v3_plate)が天板。正立印刷でサポート不要。
//
// 実機知見(v3初回印刷で干渉):
//  - 内部構造は全プレート穴(M2/BC/ボール)から壁面まで7mm以上離す
//    (キーボード下面のネジ頭・スペーサーの逃げ)。井桁位置は v3_grid_x/y で管理
//  - 南帯(kb x>=46)はボール部品がプレート外形からはみ出す帯:
//    楔面-8.6より上に構造を置かない(v2の逃げと同じ)。パーム耳もここを避ける
//
// ジョイント(垂直M3x8なべ+ナット, 上から締結):
//  - 中央箱と: 東壁の長い切り欠き(床z=13)+受けボス帯。中央箱の長耳(穴3)が載り、
//    縦ネジ→ボス帯の西向きナットスロット(3箇所)で締結
//  - パーム箱と: 南壁の長い切り欠き(床=楔面-2.5)+受けボス帯。パームの長耳(穴3)が
//    載り、縦ネジ→北向きナットスロットで締結
// kbローカル座標系。左用: v3_kb_box_left() / 右用はミラー。
include <v3_params.scad>

module v3_kb_box_left() {
    difference() {
        union() {
            // 外周リム(壁厚2.5, 上端=楔上面)
            intersection() {
                linear_extrude(60) difference() {
                    rounded_rect(kbw, kbd, 6);
                    offset(delta = -v3_wall) rounded_rect(kbw, kbd, 6);
                }
                halfspace_below_top(0);
            }
            // 周壁内側の座リブ(幅4, 上端=プレート座面。段付き壁なのでオーバーハングなし)
            intersection() {
                linear_extrude(60) difference() {
                    offset(delta = -v3_wall) rounded_rect(kbw, kbd, 6);
                    offset(delta = -(v3_wall + v3_seat_w)) rounded_rect(kbw, kbd, 6);
                }
                halfspace_below_top(-pocket_depth);
            }
            // 井桁壁 + プレート固定ボス(交点) + BCネジ筒柱(+井桁への連結帯)
            intersection() {
                linear_extrude(60) intersection() {
                    union() {
                        for (gx = v3_grid_x)
                            translate([gx - v3_wall/2, 0]) square([v3_wall, kbd]);
                        for (gy = v3_grid_y)
                            translate([0, gy - v3_wall/2]) square([kbw, v3_wall]);
                        for (s = v3_plate_screws) translate(s) circle(d = 8);
                        for (h = plate_holes_f)
                            if (h[2] >= 2.35 && h[2] < 4)
                                translate([kb_wall + h[0]*cos(tent_angle), kb_wall + h[1]])
                                    circle(d = 14);
                        // BC筒柱を井桁(y1壁)へ連結
                        translate([65.4, 16]) square([2.5, v3_grid_y[0] - 16 + 2]);
                    }
                    offset(delta = -1) rounded_rect(kbw, kbd, 6);
                }
                halfspace_below_top(-pocket_depth);
            }
            // パームジョイント受けボス帯(南壁内側, 上端=耳下面=楔面-2.5)
            intersection() {
                translate([13, v3_wall, 0]) cube([45.9 - 13, 8 - v3_wall, 60]);
                halfspace_below_top(-v3_pj_tab_t);
            }
            // 中央箱ジョイント受けボス帯(東壁内側, z0..13)
            translate([kbw - 11.5, 0, 0]) cube([11.5 - v3_wall, 116.3, 13]);
        }

        // BCネジ筒柱の中通し穴(Φ8)
        for (h = plate_holes_f)
            if (h[2] >= 2.35 && h[2] < 4)
                translate([kb_wall + h[0]*cos(tent_angle), kb_wall + h[1], -1])
                    cylinder(d = kb_head_hole_d, h = 80);

        // プレート固定ネジの下穴(M3セルフタップ, 貫通)
        for (s = v3_plate_screws)
            translate([s[0], s[1], -1]) cylinder(d = 2.6, h = 80);

        // ボール部品の張り出し帯の逃げ(v2と同じ):
        // プレート外形の外側(x>=46, y<52)を楔面-8.6より上から除去
        difference() {
            intersection() {
                translate([kb_wall + 40, -1, -1])
                    cube([plate_w - 40 + 0.5, kb_wall + 47, 80]);
                halfspace_above_top(-pocket_depth - notch_relief);
            }
            translate([kb_wall, kb_wall, -2]) linear_extrude(84) plate2d(0);
            // BC筒柱は保護
            for (h = plate_holes_f)
                if (h[2] >= 2.35 && h[2] < 4)
                    translate([kb_wall + h[0]*cos(tent_angle), kb_wall + h[1], -2])
                        cylinder(d = 14, h = 84);
        }

        // ==== 中央箱ジョイント受け(東壁, 長耳1枚) ====
        // 切り欠き(壁+ボス帯のz13より上を長さ全体で除去)
        translate([kbw - 11.5, -1.4, 13]) cube([14.5, 117.8, 40]);
        for (jy_g = v3_cj_ys) {
            jy = kbd - (kb_corner_y - jy_g) / cos(splay);
            // 縦ネジ穴(東壁面から6mm内側)
            translate([kbw - 6, jy, -1]) cylinder(d = m3_hole_d, h = 20);
            // ナットスロット(西=フレーム内側から挿入。ナット対角6.35が軸直下に届く奥行き)
            translate([kbw - 12.5, jy - v3_slot_w/2, 13 - 2.5 - v3_slot_t])
                cube([9.8, v3_slot_w, v3_slot_t]);
        }

        // ==== パームジョイント受け(南壁, 長耳1枚) ====
        // 切り欠き(床=耳下面と同じ傾斜面。水平床だと耳が食い込む)
        intersection() {
            translate([13.5, -1, 0]) cube([47 - 13.5, 10.5, 60]);
            halfspace_above_top(-v3_pj_tab_t);
        }
        for (jx = v3_pj_xs) {
            // 縦ネジ穴(南壁面から4.5mm)
            translate([jx, 4.5, -1]) cylinder(d = m3_hole_d, h = 60);
            // ナットスロット(北=フレーム内側から挿入, 天井2.5)
            translate([jx - v3_slot_w/2, 1.2,
                       kb_top_z(jx) - v3_pj_tab_t - 2.5 - v3_slot_t])
                cube([v3_slot_w, 8.5, v3_slot_t]);
        }
    }
}

module v3_kb_box_right() { mirror([1, 0, 0]) v3_kb_box_left(); }
