// v4 ボトムプレート: キーボードを純正M2ネジで固定する2mm平板(付属アクリル底板の代わり)。
// 左右プレート(v4_plate)の上に重ね、KB外形の外に出した耳でネジ止めする。
//  - キーボードをボトムプレートごと着脱できる(メンテナンス性)
//  - 左右プレート(3mm)と2層5mmの積層になり、キーボード部の剛性が上がる
//  - 耳: 上開きの六角井戸にナットを落とし、左右プレートの下からM3x8なべ。
//    ナットは井戸の床(板厚2mm)に引き付けられ、六角の壁が回り止めになる
//  - 外形 = アクリル外形そのまま + 耳(耳の円と近傍の外形のhullで滑らかにつなぐ)
// 座標は v4_plate と同じプレート座標(sx, sy)。組立時は左右プレート上面(z=v4_pt)に載る
// 印刷: ベタ置き(耳のボスと井戸は上向き・サポート不要)
include <v4_params.scad>

v4bp_ox = kb_wall / cos(tent_angle);   // 外形(アクリル座標)の配置オフセット(v4_plateと同じ)
v4bp_oy = kb_wall;

module v4_bp_outline2d() {
    translate([v4bp_ox, v4bp_oy]) plate2d();
}

// 耳1つ分の平面形(上部カバーの逃げにも使う)。
// ボス円筒と側面が一致すると縮退面が出るので、板の部分は径+1(0.5mmのつば)
module v4_bp_ear2d(e) {
    hull() {
        translate(e) circle(d = v4_bp_ear_d + 1);
        intersection() {
            v4_bp_outline2d();
            translate(e) circle(r = v4_bp_ear_d);
        }
    }
}

module v4_bp_fp2d() {
    v4_bp_outline2d();
    for (e = v4_bp_ears) v4_bp_ear2d(e);
}

module v4_bottom_plate_left() {
    difference() {
        union() {
            linear_extrude(v4_bp_t) v4_bp_fp2d();
            for (e = v4_bp_ears)
                translate([e[0], e[1], 0]) cylinder(d = v4_bp_ear_d, h = v4_bp_boss_h);
        }

        // キーボード取付穴(アクリルと同じ)
        translate([v4bp_ox, v4bp_oy, 0])
            for (h = plate_holes_f) {
                if (h[2] > 1.9 && h[2] < 2.35)   // M2
                    translate([h[0], h[1], -1]) cylinder(d = m2_hole_d, h = 20);
                if (h[2] >= 2.35 && h[2] < 4)    // ボールケースネジ
                    translate([h[0], h[1], -1]) cylinder(d = bc_hole_d, h = 20);
                if (h[2] > 10)                   // ボール取出し穴
                    translate([h[0], h[1], -1]) cylinder(d = h[2], h = 20);
            }

        // 耳: Φ3.4貫通 + 床(板厚)より上の六角井戸(上開き)
        for (e = v4_bp_ears) translate([e[0], e[1], 0]) {
            translate([0, 0, -1]) cylinder(d = m3_hole_d, h = 20);
            translate([0, 0, v4_bp_t]) cylinder(d = m3_nut_af / cos(30), h = 20, $fn = 6);
        }
    }
}

module v4_bottom_plate_right() { mirror([1, 0, 0]) v4_bottom_plate_left(); }
