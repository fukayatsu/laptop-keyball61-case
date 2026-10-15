// v4 中央スパイン: 切妻テント形の中実板(箱をやめた極力シンプルな形)。
//  - 上面 = 左右プレートの下面平面(-v4_fit)。テント角7°はこの形が作る
//  - 底面 = z=v4_spine_z0 のフラット(接地せず浮く)。組立の向きのまま
//    ベタ置き印刷でき、上面は7°の緩斜面なのでサポートゼロ・安定
//  - 平面形 = 縫い目の台形 + 上部カバーと同じ幅(プレート座標 sx >= v4_spine_x0)。
//    KB外形〜縫い目の帯(蝶番部)も下から支える(2026-10-15)
//  - 上部カバーの柱の長ネジ(M3x25なべ)がプレートを貫いてスパインまで届き、
//    カバー・左右プレート・スパインを共締め。ナットは底面からの六角ポケット
//  - カバーより南は縦M3x8なべ x1/側のジョイント。同じく底面からのナットポケット
//    (ネジ軸方向・回り止め。ナットの上の肉は約3mm)
//  - 上面にボトムプレートの耳ネジ(プレート下面に頭が出る)の逃げ
// 厚さは外縁で約6.5mm、稜線で約14mm
include <v4_params.scad>

// 左プレート下面平面(z = x*tan(tent), kbローカル)より下の半空間
module v4_below_plateL(dz = 0) {
    v4_place_left() translate([0, 0, dz]) rotate([0, -tent_angle, 0])
        translate([-2000, -1500, -3000]) cube([5000, 3000, 3000]);
}

// 上部カバーと同じ幅の張り出し(左半分, sy 0..kbd = プレートのKB矩形の範囲)
module v4_spine_ext_half2d() {
    intersection() {
        v4_place_plate_left2d() translate([v4_spine_x0, 0]) square([300, kbd]);
        translate([-1000, -1000]) square([1000, 3000]);
    }
}

module v4_spine_fp2d() {
    offset(r = v4_r) offset(delta = -v4_r) union() {
        v4_spine_ext_half2d();
        mirror([1, 0, 0]) v4_spine_ext_half2d();
        polygon([
            [-v4_seam(v4_y0), v4_y0],
            [-v4_seam(v4_y1), v4_y1],
            [ v4_seam(v4_y1), v4_y1],
            [ v4_seam(v4_y0), v4_y0]
        ]);
    }
}

// 底面から差し込むM3ナットポケット(ネジ軸方向, プレート座標の軸上)。
// 天井はスパイン上面から v4_sp_meat。天井は45°の六角テーパーでネジ穴へすぼめる
// (平天井だとブリッジが垂れて綺麗に印刷できない。ナットは六角外周のリムで座る)
module v4_spine_nut_pocket() {
    zc = -(v4_fit + v4_sp_meat);
    translate([0, 0, zc - 30]) cylinder(d = m3_nut_af / cos(30), h = 30, $fn = 6);
    translate([0, 0, zc - 0.01])
        cylinder(d1 = m3_nut_af / cos(30), d2 = 4, h = 1.4, $fn = 6);
}

module v4_center_spine() {
    difference() {
        // 中実スパイン: 台形柱 ∩ 左右プレート面の下 ∩ 底面フラット
        intersection() {
            translate([0, 0, v4_spine_z0]) linear_extrude(40) v4_spine_fp2d();
            v4_below_plateL(-v4_fit);
            mirror([1, 0, 0]) v4_below_plateL(-v4_fit);
        }

        for (m = [0, 1]) mirror([m, 0, 0]) {
            // ジョイント(カバーより南): ネジ穴 + ナットポケット。M3x8でナット全ネジ掛かり
            v4_place_left() for (jy = v4_cj_ys)
                translate([kbw + 6, v4_jyl(jy), (kbw + 6) * tan(tent_angle)])
                    rotate([0, -tent_angle, 0]) {
                        cylinder(d = m3_hole_d, h = 60, center = true);
                        v4_spine_nut_pocket();
                    }
            v4_place_plate_left() {
                // 上部カバーの長ネジ: ネジ穴 + ナットポケット
                for (c = v4tc_cols) translate([c[0], c[1], 0]) {
                    cylinder(d = m3_hole_d, h = 60, center = true);
                    v4_spine_nut_pocket();
                }
                // ボトムプレートの耳ネジの頭(プレート下面から2.4mm)の逃げ
                for (e = v4_bp_ears)
                    if (e[0] + v4_bp_ear_d / 2 > v4_spine_x0)
                        translate([e[0], e[1], -3]) cylinder(d = v4_bp_ear_d - 2, h = 4);
            }
        }
    }
}
