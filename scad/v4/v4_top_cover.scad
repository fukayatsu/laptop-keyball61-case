// v4 上部カバー: キーボードの間・スパインの真上に載る底の開いた箱(2026-10-14)。
// 中にTouch ID基板(85x31, バッテリーなし)とTRSケーブル(L型プラグごと)を収める。
//  - 天面は水平。壁の下端は左右プレート上面(切妻)に沿う
//  - 取付: 左右プレートのKB外形〜縫い目の帯(sx140..156, 蝶番部)に柱を3本/側。
//    柱は全て天板まで通し、天板の座ぐりからM3x25なべ→左右プレート→スパイン底面の
//    六角ポケットのナット。カバー・左右プレート・スパインを同じネジで共締めする(2026-10-15)。
//    横挿しスロットは傾けるとナットが滑り出て組めず、ナット圧入は保持力が心もとなく、
//    インサートは部品・工具が増えるので、カバーの外(スパインの下)にナットを出した。
//    スパインがKB外形〜縫い目の帯まで広がって蝶番部を下から支え、
//    カバーは左右プレートを橋渡しする(旧スパイン接続帯の横リブsy31/98の役目)
//  - 柱は西壁と天板の高さまで一体のリブ(幅=柱径9)でつながる
//  - ブリッジなし: 座ぐりの座面は55°の円錐(なべ頭は外周で座る)。USB-C窓は下辺を45°に尖らせる
//  - 西壁(左右)にTRSプラグの切欠き、ボトムプレートの耳の逃げ。北壁にUSB-Cの窓
//  - Touch ID基板は天板の裏に両面テープで貼る(四隅にL字の位置決め枠)
// 印刷: 天面をベッドに伏せて(parts_v4_top_cover.scad)。切欠き・逃げは上に開くのでサポート不要
include <v4_params.scad>
use <v4_bottom_plate.scad>

// 平面視の外形(グローバル): 左プレート座標の範囲を中心線で切って左右対称に
module v4tc_half2d() {
    intersection() {
        v4_place_plate_left2d() polygon([
            [v4tc_xs, v4tc_ys0], v4tc_sw[0], v4tc_sw[1],
            [v4tc_x0, v4tc_nw[1]], [v4tc_nw[0], v4tc_y1],
            [400, v4tc_y1], [400, v4tc_ys0]
        ]);
        translate([-1000, -1000]) square([1000, 3000]);
    }
}
module v4tc_fp2d() {
    offset(r = v4tc_r) offset(delta = -v4tc_r) union() {
        v4tc_half2d();
        mirror([1, 0, 0]) v4tc_half2d();
    }
}

// 左右プレート上面(切妻)より上(+0.1)
module v4tc_above_gable() {
    for (m = [0, 1]) mirror([m, 0, 0]) intersection() {
        v4_place_plate_left() translate([-500, -500, v4_pt + 0.1]) cube([2000, 2000, 300]);
        translate([-1000, -1000, -100]) cube([1000, 3000, 400]);
    }
}

module v4tc_envelope() {
    difference() {
        intersection() {
            translate([0, 0, -50]) linear_extrude(v4tc_top_z + 50) v4tc_fp2d();
            v4tc_above_gable();
        }
        if (v4tc_cham > 0) v4tc_cham_cut();
    }
}

// 南区間の天面の縁の45°面取り(南壁・西壁・斜めの壁)。伏せ印刷で45°の張り出しになる。
// 外形が凹(親指の逃げ)なので、辺ごとに45°のくさびで切り、隣の辺とは角の二等分線で分ける
function v4p2g(p) = let (x = p[0] * cos(tent_angle) - kbw, y = p[1] - kbd)
    [-v4_corner_x + x * cos(splay) + y * sin(splay), kb_corner_y - x * sin(splay) + y * cos(splay)];
function v4u(v) = v / norm(v);
function v4n(p, q) = let (d = v4u(q - p)) [-d[1], d[0]];   // 時計回りに辿る辺の外向き法線(進行方向の左)

module v4tc_cham_cut(dz = 0) {   // dz: 面を下げる量(空洞側は板厚 x √2)
    c = v4tc_cham;
    v1 = v4p2g([v4tc_xs, v4tc_ys0]); v2 = v4p2g(v4tc_sw[0]); v3 = v4p2g(v4tc_sw[1]);
    s1 = v4p2g([300, v4tc_ys0]);
    c0 = v1 + (s1 - v1) * (-v1[0] / (s1[0] - v1[0]));       // 南壁と中心線の交点
    n0 = v4n(c0, v1); n1 = v4n(v1, v2); n2 = v4n(v2, v3);
    b = v4u(n1 + n2);                                         // 凹角v2の二等分線
    for (m = [0, 1]) mirror([m, 0, 0]) {
        // 凸角だけでつながる辺(南壁)は無限平面のまま
        v4tc_cham_plane(c0, n0, c + dz);
        // 凹角v2を挟む2辺は二等分線で領域を分ける
        intersection() { v4tc_cham_plane(v1, n1, c + dz); v4tc_halfplane(v2, b, v1); }
        intersection() { v4tc_cham_plane(v2, n2, c + dz); v4tc_halfplane(v2, b, v3); }
    }
}
// 外面の線(点p, 外向き法線n)から天面までcの45°面より上
module v4tc_cham_plane(p, n, c) {
    translate([p[0], p[1], v4tc_top_z - c]) rotate([0, 0, atan2(n[1], n[0])])
        rotate([0, -45, 0]) translate([0, -500, -500]) cube(1000);
}
// 点pを通る方向dの直線で分けた、点sを含む側
module v4tc_halfplane(p, d, s) {
    side = sign(d[0] * (s[1] - p[1]) - d[1] * (s[0] - p[0]));
    k = [-d[1], d[0]] * side;
    translate([0, 0, -100]) linear_extrude(400)
        polygon([p - d * 500, p + d * 500, p + d * 500 + k * 500, p - d * 500 + k * 500]);
}

// 空洞から除く(=面取りに沿って板厚を残す)部分: 面取り面を板厚分だけ内側へ平行移動した面より上
module v4tc_cham_keep_inner() { v4tc_cham_cut(v4tc_t * sqrt(2)); }

// 取付ネジ: 天板の座ぐりからM3x25なべ、スパイン底面のポケットのナット
// (プレート座標z=プレート下面から。ナットの上面 = -(v4_fit + v4_sp_meat))
v4tc_screw_l = 25;
v4tc_seat_z  = v4tc_screw_l - (v4_fit + v4_sp_meat + 2.4) - 1.2;
                     // 頭の座面 = ネジ長 - ナット下面の深さ4.55 - 先端の余裕1.2 → 19.25
v4tc_head_d  = 5.5;  // なべ頭の径
v4tc_cb_d    = 6.5;  // 座ぐり径(なべ頭 + 1)
v4tc_cb_cone = 55;   // 座面の円錐角(水平から)。伏せ印刷で座ぐりの奥が張り出しになるため平座にしない。
                     // テント7°が加わっても48°に収まる

module v4tc_columns() {
    // 柱(天板まで)と西壁を天板の高さまで一体のリブでつなぐ(v4_top_cover側で壁・天板の内側に切る)。
    // 斜面だけだと柱・斜面・天板の間に閉じた空洞ができた
    for (m = [0, 1]) mirror([m, 0, 0]) v4_place_plate_left()
        for (c = v4tc_cols) hull() {
            translate([c[0], c[1], v4_pt]) cylinder(d = v4tc_col_d, h = 100);
            translate([v4tc_x0, c[1] - v4tc_col_d / 2, v4_pt]) cube([v4tc_t, v4tc_col_d, 100]);
        }
}

// Touch ID基板の位置決め枠(天板裏から下へ1.5mm, 四隅のL字)
module v4tc_tid_frame() {
    w = v4tc_tid[0] + 0.8; l = v4tc_tid[1] + 0.8; rw = 1.2; arm = 8;
    translate([-w / 2, v4tc_tid_y0 - 0.4, v4tc_top_z - v4tc_t - 1.5])
        for (cx = [0, 1], cy = [0, 1])
            translate([cx * w, cy * l, 0]) mirror([cx, 0, 0]) mirror([0, cy, 0]) {
                translate([-rw, -rw, 0]) cube([arm + rw, rw, 1.51]);
                translate([-rw, -rw, 0]) cube([rw, arm + rw, 1.51]);
            }
}

module v4_top_cover() {
    difference() {
        union() {
            difference() {
                v4tc_envelope();
                difference() {
                    translate([0, 0, -60]) linear_extrude(v4tc_top_z - v4tc_t + 60)
                        offset(delta = -v4tc_t) v4tc_fp2d();
                    // 面取り部も板厚を保つ
                    if (v4tc_cham > 0) v4tc_cham_keep_inner();
                }
            }
            // 柱は壁・天板に0.5食い込む所まで(外面と共面にしない=縮退面防止)
            intersection() {
                v4tc_columns();
                v4tc_envelope();
                translate([0, 0, -60]) linear_extrude(v4tc_top_z - v4tc_t + 0.5 + 60)
                    offset(delta = -v4tc_t + 0.5) v4tc_fp2d();
            }
            v4tc_tid_frame();
        }

        for (m = [0, 1]) mirror([m, 0, 0]) v4_place_plate_left() {
            // TRSプラグの切欠き(西壁, 下端から)。壁はグローバルで鉛直なので
            // プレート座標では高さとともに東へずれる(z*tan7)——奥行きを余分に取る
            translate([v4tc_x0 - 3, v4tc_jack_y - v4tc_notch_w / 2, -1])
                cube([v4tc_t + 9, v4tc_notch_w, v4tc_notch_top + 1]);
            // ボトムプレートの耳の逃げ(耳と同じ平面形+0.6)
            for (e = v4_bp_ears)
                if (e[0] + v4_bp_ear_d / 2 + 0.6 > v4tc_x0 && e[1] > v4tc_y0 - 5)
                    translate([0, 0, -1]) linear_extrude(v4_pt + v4_bp_boss_h + 1 + 1)
                        offset(r = 0.6) v4_bp_ear2d(e);
            // 柱: Φ3.4ネジ穴(天板まで貫通) + 天板の座ぐり(座面は円錐。なべ頭の外周が
            // 円錐の径5.5の位置=v4tc_seat_zに座る)
            for (c = v4tc_cols) translate([c[0], c[1], 0]) {
                translate([0, 0, -1]) cylinder(d = m3_hole_d, h = 100);
                let (k = tan(v4tc_cb_cone),
                     zc = v4tc_seat_z + (v4tc_cb_d - v4tc_head_d) / 2 * k,  // 円錐の上端
                     hc = (v4tc_cb_d - m3_hole_d) / 2 * k) {
                    translate([0, 0, zc]) cylinder(d = v4tc_cb_d, h = 100);
                    translate([0, 0, zc - hc]) cylinder(d1 = m3_hole_d, d2 = v4tc_cb_d, h = hc + 0.01);
                }
            }
        }

        // 北壁のUSB-C窓(Touch ID基板のポート用。ボタンのフレキもここから出す)。
        // 天板の縁ごと切り欠き、下辺は45°の尖り(伏せ印刷で屋根になりブリッジなし)
        let (zr = v4tc_top_z - v4tc_t - v4tc_port_h, hw = v4tc_port_w / 2)
            translate([0, v4tc_tid_y0 + v4tc_tid[1] - 2, 0]) rotate([-90, 0, 0])
                linear_extrude(30) polygon([[-hw, -(v4tc_top_z + 1)], [hw, -(v4tc_top_z + 1)],
                                            [hw, -zr], [0, -(zr - hw)], [-hw, -zr]]);
    }
}
