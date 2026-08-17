// v3 中央ボックス: ブリッジ+ブレース代替の台形トーションボックス(リブなし・底面開放)。
// 天板がプレーンなため「天板をベッドに伏せて」印刷すればブリッジゼロ
// (parts ファイルで 180°回転済み)。
// 天板にポッドをM3セルフタップ。KBフレームとはデッキ面一タブ+縦M3x8なべ
// で締結(皿もみなしのストレート穴。薄タブの縁を残して座面強度を確保)。
include <v3_params.scad>

function v3bx(y) = seam_x(y) - v3_joint_clr;

module v3_center_box() {
    difference() {
        union() {
            // KB箱ジョイントタブ(デッキと面一, 厚3。KBフレーム東壁の切り欠きに載る。
            // ネジ穴=継ぎ目の西5.91mmを覆うため西へ9.7mm張り出す)
            for (m = [0, 1], jy = v3_cj_ys) mirror([m, 0, 0])
                translate([-(seam_x(jy) + 9.7), jy + 1.04 - 7, v3_cbox_h - v3_top])
                    cube([9.7 + 3 + seam_x(jy) - v3bx(jy), 14, v3_top]);

            // 底蓋用ボス柱(デッキから垂下、先端=底面から蓋厚の位置=蓋の受け座)
            for (bp = v3_lid_bosses)
                translate([bp[0], bp[1], v3_lid_t]) cylinder(d = 8, h = v3_cbox_h - v3_lid_t);

            // シェル(台形柱, 底面開放, リブなし)
            difference() {
                linear_extrude(v3_cbox_h)
                    polygon([
                        [-v3bx(v3_cbox_y0), v3_cbox_y0],
                        [-v3bx(v3_cbox_y1), v3_cbox_y1],
                        [ v3bx(v3_cbox_y1), v3_cbox_y1],
                        [ v3bx(v3_cbox_y0), v3_cbox_y0]
                    ]);
                translate([0, 0, -1]) linear_extrude(v3_cbox_h - v3_top + 1)
                    offset(delta = -v3_wall)
                        polygon([
                            [-v3bx(v3_cbox_y0), v3_cbox_y0],
                            [-v3bx(v3_cbox_y1), v3_cbox_y1],
                            [ v3bx(v3_cbox_y1), v3_cbox_y1],
                            [ v3bx(v3_cbox_y0), v3_cbox_y0]
                        ]);
            }
        }

        // KB箱ジョイントタブのネジ穴(縦M3なべ用ストレート穴, KB側ボス位置に一致:
        // kbローカル(kbw-6, jy) = グローバル(-(seam+6cosθ), jy+6sinθ), θ=splay。
        // 皿もみだと厚3のタブの縁が刃状に薄くなるため、平座面のなべネジで締める)
        for (m = [0, 1], jy = v3_cj_ys) mirror([m, 0, 0])
            translate([-(seam_x(jy) + 5.91), jy + 1.04, v3_cbox_h - v3_top - 1])
                cylinder(d = 3.4, h = v3_top + 2);

        // 底蓋ネジの下穴(ボス柱内, M3セルフタップ)
        for (bp = v3_lid_bosses)
            translate([bp[0], bp[1], 1.5]) cylinder(d = 2.6, h = 8);

        // ポッド固定(天板にM3セルフタップ下穴)
        for (sx = [-pod_screw_span/2, pod_screw_span/2])
            translate([sx, pod_y, v3_cbox_h - v3_top - 1]) cylinder(d = 2.6, h = v3_top + 2);

        // ケーブル用ベルクロスロット(北端付近, 天板貫通)
        for (sx = [-25, 25])
            translate([sx - 6, 242, v3_cbox_h - v3_top - 1]) cube([12, 4, v3_top + 2]);

        // 結束バンド用スロット対(3x14, 天板貫通, ポッドのフットプリント±32の外側)
        for (tp = v3_tie_pairs, dx = [-4.75, 4.75])
            translate([tp[0] + dx - 1.5, tp[1] - 7, v3_cbox_h - v3_top - 1])
                cube([3, 14, v3_top + 2]);
    }
}



// 底蓋(あと付け可・平置き印刷)。内周-クリアランスの台形板、下からM3x8皿x4で
// ボス柱に固定し、皿頭は底面ツライチ。
module v3_center_lid() {
    difference() {
        linear_extrude(v3_lid_t)
            offset(delta = -(v3_wall + clr))
                polygon([
                    [-v3bx(v3_cbox_y0), v3_cbox_y0],
                    [-v3bx(v3_cbox_y1), v3_cbox_y1],
                    [ v3bx(v3_cbox_y1), v3_cbox_y1],
                    [ v3bx(v3_cbox_y0), v3_cbox_y0]
                ]);
        for (bp = v3_lid_bosses)
            translate([bp[0], bp[1], 0]) rotate([180, 0, 0]) m3_countersunk(v3_lid_t + 1);
        // 取り外し用の指掛かり
        translate([0, v3_cbox_y0 + 18, -1]) cylinder(d = 10, h = v3_lid_t + 2);
    }
}
