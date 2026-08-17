// v3 KBフレーム(加算的構成):
//   周壁(楔上端) + プレート座リング + 米の字スポーク + 貫通ボス4 + BCネジ筒柱2。
// 天板なし=マウントプレートが天板。ブリッジ面が存在せず正立印刷でサポート不要。
//
// ジョイント(全て垂直M3x8皿, 上から締結。ナットは横挿しスロットで回り止め):
//  - 中央箱と: 東壁に切り欠き(床z=13)+チャネル側に張り出すボス。中央箱のデッキ面一
//    タブが切り欠きに載り、縦ネジ→ボス内の西向きナットスロットで締結
//  - パーム箱と: 南壁に切り欠き(床=楔面-3.2)+内側に張り出すボス。パーム天板面一の
//    タブが載り、縦ネジ→ボス内の北向きナットスロットで締結
// kbローカル座標系。左用: v3_kb_box_left() / 右用はミラー。
include <v3_params.scad>

v3_seat_ledge = 4;                  // 座リングの内側張り出し幅
v3_hub = [73, 61.75];               // 米の字スポークのハブ(4ボスの重心)

module v3_kb_box_left() {
    difference() {
        union() {
            // 周壁(上端 = 楔上面)
            intersection() {
                linear_extrude(60)
                    difference() {
                        rounded_rect(kbw, kbd, 6);
                        offset(delta = -v3_wall) rounded_rect(kbw, kbd, 6);
                    }
                halfspace_below_top(0);
            }
            // 内部構造(上端 = プレート座面)
            intersection() {
                linear_extrude(60) union() {
                    // 座リング(プレート外形の -4 .. +1)
                    translate([kb_wall, kb_wall]) difference() {
                        offset(r = 1) plate2d(0);
                        offset(delta = -v3_seat_ledge) plate2d(0);
                    }
                    // 米の字スポーク: 水平・垂直・対角2本(対角上のボス対の平均方位)
                    intersection() {
                        union() {
                            translate(v3_hub) circle(d = 16);
                            for (a = [0, 90, 51, 126])
                                translate(v3_hub) rotate(a)
                                    translate([-220, -v3_wall/2]) square([440, v3_wall]);
                        }
                        offset(delta = -1) rounded_rect(kbw, kbd, 6);
                    }
                    // プレート固定ボス
                    for (sp = plate_screws)
                        translate([kb_wall + sp[0]*cos(tent_angle), kb_wall + sp[1]])
                            circle(d = 8);
                    // ボールケースネジ支持柱(+連結帯)
                    for (h = plate_holes_f)
                        if (h[2] >= 2.35 && h[2] < 4)
                            translate([kb_wall + h[0]*cos(tent_angle), kb_wall + h[1]])
                                circle(d = 14);
                    translate([65.2, 12]) square([2.5, 24]);
                }
                halfspace_below_top(-pocket_depth);
            }
            // 中央箱ジョイント受けボス(東壁の内側への張り出し, z0..13)
            for (jy_g = v3_cj_ys) {
                jy = kbd - (kb_corner_y - jy_g) / cos(splay);
                translate([kbw - 11.5, jy - 9, 0]) cube([11.5 - v3_wall, 18, 13]);
            }
            // パーム箱ジョイント受けボス(南壁の内側への張り出し, 上端=タブ下面)
            for (jx = v3_pj_xs)
                intersection() {
                    translate([jx - 9, v3_wall, 0]) cube([18, 8 - v3_wall, 60]);
                    halfspace_below_top(-3.2);
                }
        }

        // BCネジ支持柱の中通し穴(Φ8)
        for (h = plate_holes_f)
            if (h[2] >= 2.35 && h[2] < 4)
                translate([kb_wall + h[0]*cos(tent_angle), kb_wall + h[1], -1])
                    cylinder(d = kb_head_hole_d, h = 80);

        // プレート固定ネジの下穴(M3セルフタップ, 貫通)
        for (sp = plate_screws) {
            sx = kb_wall + sp[0] * cos(tent_angle);
            sy = kb_wall + sp[1];
            translate([sx, sy, -1]) cylinder(d = 2.6, h = 80);
        }

        // ==== 中央箱ジョイント受け(東壁) ====
        // ネジ軸は東壁面から6mm内側(穴縁の肉4.3mm)。スロットはナットの対角6.35が
        // 軸の真下まで届く奥行きを確保し、天井2.5mmが締結面(M3x8で全ネジ掛かり)
        for (jy_g = v3_cj_ys) {
            jy = kbd - (kb_corner_y - jy_g) / cos(splay);
            // 切り欠き(壁+ボス上部をz=13まで除去。タブ幅14に対し開口18で角度差を吸収)
            translate([kbw - 11.5, jy - 9, 13]) cube([14.5, 18, 40]);
            // 縦ネジ穴
            translate([kbw - 6, jy, -1]) cylinder(d = m3_hole_d, h = 20);
            // ナットスロット(西=フレーム内側から挿入, 天井2.5)
            translate([kbw - 12.5, jy - v3_slot_w/2, 13 - 2.5 - v3_slot_t])
                cube([9.8, v3_slot_w, v3_slot_t]);
        }

        // ==== パーム箱ジョイント受け(南壁) ====
        // ネジ軸は南壁面から4.5mm(ナットの対角がスロット内で軸の真下に届く位置)。
        // スロット天井2.5mmが締結面
        for (jx = v3_pj_xs) {
            nf = pocket_floor_z(jx) + pocket_depth - 3.2;  // ナットスロットの基準高さ
            // 切り欠き(壁+ボス上部を除去)。床はタブ下面と同じ傾斜面(楔面-3.2):
            // 水平な床だとタブ西側が最大0.9mm食い込む
            intersection() {
                translate([jx - 9, -1, 0]) cube([18, 9.5, 60]);
                halfspace_above_top(-3.2);
            }
            // 縦ネジ穴
            translate([jx, 4.5, -1]) cylinder(d = m3_hole_d, h = 60);
            // ナットスロット(北=フレーム内側から挿入, 天井2.5)
            translate([jx - v3_slot_w/2, 1.2, nf - 2.5 - v3_slot_t])
                cube([v3_slot_w, 8.5, v3_slot_t]);
        }
    }
}

module v3_kb_box_right() { mirror([1, 0, 0]) v3_kb_box_left(); }
