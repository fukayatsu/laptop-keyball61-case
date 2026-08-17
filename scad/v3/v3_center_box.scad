// v3 中央ボックス: ブリッジ+ブレース代替の台形トーションボックス(リブなし・底面開放)。
// 左右間隔5cm短縮版: 幅は v3_seam() 基準(北端の半幅は約18mm)。四隅は角丸(r=6)。
// 天板がプレーンなため「天板をベッドに伏せて」印刷すればブリッジゼロ
// (parts ファイルで 180°回転済み)。
// KBフレームとはデッキ面一の長耳1枚(穴3)/側+縦M3x8なべ+ナットで締結
// (皿もみなしのストレート穴。薄い耳の縁を残して座面強度を確保)。
// ポッド(v3_pod, フランジレス)はベイ床からデッキへM3x8皿x4。
// バッテリーはポッドではなく箱内部に結束バンド(3x14スロット対)で固定する。
include <v3_params.scad>

function v3bx(y) = v3_seam(y) - v3_joint_clr;

// 台形フットプリント(角丸r=v3_cbox_r)
module v3cb_fp2d() {
    offset(r = v3_cbox_r) offset(delta = -v3_cbox_r)
        polygon([
            [-v3bx(v3_cbox_y0), v3_cbox_y0],
            [-v3bx(v3_cbox_y1), v3_cbox_y1],
            [ v3bx(v3_cbox_y1), v3_cbox_y1],
            [ v3bx(v3_cbox_y0), v3_cbox_y0]
        ]);
}

module v3_center_box() {
    difference() {
        union() {
            // KBフレームジョイント長耳(デッキと面一, 厚3, y114..228。
            // ネジ穴=継ぎ目の西5.91mmを覆うため西へ9.7mm張り出す)
            for (m = [0, 1]) mirror([m, 0, 0])
                translate([0, 0, v3_cbox_h - v3_top]) linear_extrude(v3_top)
                    polygon([
                        [-(v3_seam(114) + 9.7), 114],
                        [-(v3_seam(228) + 9.7), 228],
                        [-(v3_seam(228) - 3.2), 228],
                        [-(v3_seam(114) - 3.2), 114]
                    ]);

            // 底蓋用ボス柱(デッキから垂下、先端=底面から蓋厚の位置=蓋の受け座)
            for (bp = v3_lid_bosses)
                translate([bp[0], bp[1], v3_lid_t])
                    cylinder(d = 8, h = v3_cbox_h - v3_lid_t);

            // シェル(角丸台形柱, 底面開放, リブなし)
            difference() {
                linear_extrude(v3_cbox_h) v3cb_fp2d();
                translate([0, 0, -1]) linear_extrude(v3_cbox_h - v3_top + 1)
                    offset(delta = -v3_wall) v3cb_fp2d();
            }
        }

        // ジョイント長耳のネジ穴(縦M3なべ用ストレート穴, KB側ボス帯位置に一致:
        // kbローカル(kbw-6, jy) = グローバル(-(v3_seam+6cosθ), jy+6sinθ), θ=splay)
        for (m = [0, 1], jy = v3_cj_ys) mirror([m, 0, 0])
            translate([-(v3_seam(jy) + 5.91), jy + 1.04, v3_cbox_h - v3_top - 1])
                cylinder(d = 3.4, h = v3_top + 2);

        // 底蓋ネジの下穴(ボス柱内, M3セルフタップ)
        for (bp = v3_lid_bosses)
            translate([bp[0], bp[1], 1.5]) cylinder(d = 2.6, h = 8);

        // ポッド固定(ベイ床からの4本, 天板にM3セルフタップ下穴)
        for (s = v3pod_floor_screws)
            translate([s[0], pod_y + s[1], v3_cbox_h - v3_top - 1])
                cylinder(d = 2.6, h = v3_top + 2);

        // ケーブル用ベルクロスロット(北端付近, 天板貫通)
        for (sx = [-12, 12])
            translate([sx - 6, 242, v3_cbox_h - v3_top - 1]) cube([12, 4, v3_top + 2]);

        // 結束バンド用スロット対(3x14, 天板貫通。バッテリー等の内部固定用)
        for (tp = v3_tie_pairs, dx = [-4.75, 4.75])
            translate([tp[0] + dx - 1.5, tp[1] - 7, v3_cbox_h - v3_top - 1])
                cube([3, 14, v3_top + 2]);
    }
}

// 底蓋(あと付け可・平置き印刷)。内周-クリアランスの角丸台形板、下からM3x8皿x4で
// ボス柱に固定し、皿頭は底面ツライチ。
module v3_center_lid() {
    difference() {
        linear_extrude(v3_lid_t) offset(delta = -(v3_wall + clr)) v3cb_fp2d();
        for (bp = v3_lid_bosses)
            translate([bp[0], bp[1], 0]) rotate([180, 0, 0]) m3_countersunk(v3_lid_t + 1);
        // 取り外し用の指掛かり
        translate([0, v3_cbox_y0 + 18, -1]) cylinder(d = 10, h = v3_lid_t + 2);
    }
}
