// v4 中央スパイン: 切妻テント形の中実板(箱をやめた極力シンプルな形)。
//  - 上面 = 左右プレートの下面平面(-v4_fit)。テント角7°はこの形が作る
//  - 底面 = z=v4_spine_z0 のフラット(接地せず浮く)。組立の向きのまま
//    ベタ置き印刷でき、上面は7°の緩斜面なのでサポートゼロ・安定
//  - プレートとは縦M3x8なべ x3/側。ナットは底面からの六角ポケット
//    (ネジ軸方向・回り止め。ナットの上の肉は約3mm)
// 厚さは端で約5.4mm、稜線で約11mm
include <v4_params.scad>

// kbローカル -> グローバル(左)。プレートと同じ配置
module v4_place_left() {
    translate([-v4_corner_x, kb_corner_y, 0]) rotate([0, 0, -splay])
        translate([-kbw, -kbd, 0]) children();
}

// 左プレート下面平面(z = x*tan(tent), kbローカル)より下の半空間
module v4_below_plateL(dz = 0) {
    v4_place_left() translate([0, 0, dz]) rotate([0, -tent_angle, 0])
        translate([-2000, -1500, -3000]) cube([5000, 3000, 3000]);
}

module v4_spine_fp2d() {
    offset(r = v4_r) offset(delta = -v4_r)
        polygon([
            [-v4_seam(v4_y0), v4_y0],
            [-v4_seam(v4_y1), v4_y1],
            [ v4_seam(v4_y1), v4_y1],
            [ v4_seam(v4_y0), v4_y0]
        ]);
}

module v4_center_spine() {
    difference() {
        // 中実スパイン: 台形柱 ∩ 左右プレート面の下 ∩ 底面フラット
        intersection() {
            translate([0, 0, v4_spine_z0]) linear_extrude(40) v4_spine_fp2d();
            v4_below_plateL(-v4_fit);
            mirror([1, 0, 0]) v4_below_plateL(-v4_fit);
        }

        // ジョイント: ネジ穴 + 底面からの六角ナットポケット(ともにネジ軸方向)
        for (m = [0, 1]) mirror([m, 0, 0]) v4_place_left()
            for (jy = v4_cj_ys) {
                jyl = v4_jyl(jy);
                translate([kbw + 6, jyl, (kbw + 6) * tan(tent_angle)])
                    rotate([0, -tent_angle, 0]) {
                        cylinder(d = m3_hole_d, h = 30, center = true);
                        // ナットポケット: 底面から差し込み、天井(-3.15)まで。
                        // ナット上の肉=約3mm。M3x8でナット全ネジ掛かり
                        translate([0, 0, -7])
                            cylinder(d = m3_nut_af / cos(30), h = 3.85, $fn = 6);
                        // 天井は45°の六角テーパーでネジ穴へすぼめる
                        // (平天井だとブリッジが垂れて綺麗に印刷できない。
                        //  ナットは六角外周のリムで座るので締結には影響なし)
                        translate([0, 0, -3.16])
                            cylinder(d1 = m3_nut_af / cos(30), d2 = 4, h = 1.4, $fn = 6);
                    }
            }


        // カバー取付ネジ(セルフタップ廃止): 上面からの六角ナット井戸 + 貫通ボア。
        // ナットは井戸床(底面+2.5)に座り、カバー側から来るM3x8なべの先端が
        // ちょうど全ネジ掛かりで届く。井戸は上開きなので印刷も綺麗
        for (s = v4_case_screws) {
            translate([s[0], s[1], v4_case_nut_z])
                cylinder(d = m3_nut_af / cos(30), h = 30, $fn = 6);
            translate([s[0], s[1], v4_spine_z0 - 1])
                cylinder(d = m3_hole_d, h = v4_case_nut_z - v4_spine_z0 + 1.1);
        }
    }
}
