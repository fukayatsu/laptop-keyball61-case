// v4 サイドプレート: キーボード搭載部+パームレスト+中央張り出しの一体2mm平板。
// 完全な平面でベッドにベタ置き印刷(サポート不要)。フェンス等の立体はなし。
// 組立時は 外側エッジが接地・内側が7°持ち上がる(テント角は中央箱の屋根が作る)。
// キーボードは直接ではなく別体のボトムプレート(v4_bottom_plate.scad)に固定し、
// それをこのプレートの上に重ねてM3でネジ止めする(2層4mmの積層で剛性UP・
// キーボードをボトムプレートごと着脱できる)。このプレートにはキーボードの
// M2/ボールケースネジの頭の逃げ穴と、ボトムプレート・上部カバーの取付穴を開ける。
//
// ローカル座標 = 斜面沿いの実寸(sx = kbローカルx / cos(tent), sy = kbローカルy)。
// 外形はキーボード矩形とパーム矩形のhull(角丸矩形同士なので輪郭は自動的に滑らか)。
include <v4_params.scad>

v4p_ox = kb_wall / cos(tent_angle);   // 外形(アクリル座標)の配置オフセット
v4p_oy = kb_wall;

// 平面視でkbローカルxをプレート座標へ
function v4sx(x) = x / cos(tent_angle);

module v4_plate_fp2d() {
    intersection() {
        hull() {
            rounded_rect(v4sx(kbw + v4_ovl), kbd, 6);
            translate([v4sx(palm_x0), -(palm_d - palm_overlap)])
                rounded_rect(v4sx(palm_w), palm_d, palm_r);
        }
        v4_plate_mid_clip2d();
    }
}

// グローバルの x <= -v4_mid_clr (中心線の左側)をプレート座標へ逆変換した半平面。
// 奥端で張り出しが中心線を越える分を切り、右プレートと稜線で突き合わせる
module v4_plate_mid_clip2d() {
    scale([1 / cos(tent_angle), 1])
        translate([kbw, kbd]) rotate(splay) translate([v4_corner_x, -kb_corner_y])
            translate([-2000 - v4_mid_clr, -1000]) square(2000);
}

module v4_plate_left() {
    difference() {
        union() {
            // 平板(キーボードフェンスは廃止: 位置決めはネジで足り、
            // 剛性も基板+スペーサーが担うためユーザー判断で削除)
            linear_extrude(v4_pt) v4_plate_fp2d();
            // たわみ抑えリブ(上面)。水平1本+外側エッジ沿いの縦1本(西端で合流)。
            // ジェルパッド80x95の領域を避けつつ位置決めストッパー兼用。
            // 外形の2mm内側にクリップ
            intersection() {
                translate([0, 0, v4_pt - 0.01]) linear_extrude(v4_rib_h + 0.01)
                    for (rib = v4_ribs, i = [0 : len(rib) - 2]) hull() {
                        translate(rib[i]) circle(d = v4_rib_w);
                        translate(rib[i + 1]) circle(d = v4_rib_w);
                    }
                linear_extrude(30) offset(delta = -2) v4_plate_fp2d();
            }
            // ケーブルまとめ用ベルトループ(外側後方の角, 上面)。
            // 貫通スロットだと結束バンドがプレート下に回って足に当たるため、
            // バー(z5..7)の下の開口9x3にバンドを通す方式。9mmブリッジで印刷可
            translate([4, 119, v4_pt + 3 - 0.01]) cube([15, 3, 2.01]);  // バー
            translate([4, 119, v4_pt - 0.01]) cube([3, 3, 3.02]);       // 西脚
            translate([16, 119, v4_pt - 0.01]) cube([3, 3, 3.02]);      // 東脚
        }

        // キーボードのネジ頭(ボトムプレート下面に出る)の逃げ穴。
        // 下からドライバーも通るので、キーボード単体の着脱もこのまま可能
        translate([v4p_ox, v4p_oy, 0])
            for (h = plate_holes_f) {
                if (h[2] > 1.9 && h[2] < 2.35)   // M2
                    translate([h[0], h[1], -1]) cylinder(d = v4_m2_head_clr, h = 20);
                if (h[2] >= 2.35 && h[2] < 4)    // ボールケースネジ
                    translate([h[0], h[1], -1]) cylinder(d = v4_bc_head_clr, h = 20);
                if (h[2] > 10)                   // ボール取出し穴
                    translate([h[0], h[1], -1]) cylinder(d = h[2], h = 20);
            }

        // ボトムプレート・上部カバーの取付穴(下からM3x8なべ)
        for (p = concat(v4_bp_ears, v4tc_cols))
            translate([p[0], p[1], -1]) cylinder(d = m3_hole_d, h = 20);

        // 中央ジョイント穴(縦M3なべ用ストレート穴, 屋根フランジのネジ軸位置)
        for (jy = v4_cj_ys)
            translate([v4sx(kbw + 6), v4_jyl(jy), -1]) cylinder(d = 3.4, h = 20);

        // ケーブルまとめ用スロット(3x15, 角丸):
        // 親指キー付近の2つのM2穴(sx126.9/134.8)のちょうど真北(ユーザー指定)。
        // ※外側後方の角は貫通スロットだと結束バンドが足に当たるため
        //   上面のベルトループに変更(unionブロック参照)
        hull() for (sx = [125, 137])
            translate([sx, 120.5, -1]) cylinder(d = 3, h = v4_pt + 2);
    }
}

module v4_plate_right() { mirror([1, 0, 0]) v4_plate_left(); }
