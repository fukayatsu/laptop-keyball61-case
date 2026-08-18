// v4 サイドプレート: キーボード搭載部+パームレスト+中央張り出しの一体2mm平板。
// 完全な平面でベッドにベタ置き印刷(サポート不要)。フェンス等の立体はなし。
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

        // ケーブルまとめ用スロット(3x15, 角丸, 北縁沿いに2箇所):
        //  - 外側後方の角(左サイドの左上/右サイドの右上)。外形はsy<108
        //  - 親指キー付近の2つのM2穴(sx126.9/134.8)のちょうど真北(ユーザー指定)。
        //    外形はsy<115
        // ストラップは穴と縁の間を通す
        for (xs = [[5.5, 17.5], [125, 137]])
            hull() for (sx = xs)
                translate([sx, 120.5, -1]) cylinder(d = 3, h = v4_pt + 2);
    }
}

module v4_plate_right() { mirror([1, 0, 0]) v4_plate_left(); }
