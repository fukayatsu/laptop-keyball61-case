// v3 パームボックス: 差し替え式の楔シェル(リブなし・底面開放)。
// 「天面をベッドに伏せて」印刷すればブリッジゼロ(partsファイルで180°±tent回転済み)。
// 北端: 天板と面一のタブx3(厚3.2, 上面=楔面=印刷時のベッド接地面)が
// KBフレーム南壁の切り欠きに載り、
// 上から縦M3x8なべ→KB側ボスの横挿しナットスロットで締結(皿もみなしの
// ストレート穴。薄タブの縁を残して座面強度を確保)。頭はジェルパッドの下。
// kbフレーム基準(北端 y=0, タブは y>0 へ張り出す)。
include <v3_params.scad>

module v3_palm_fp2d() {
    translate([v3_palm_x0, -v3_palm_d]) rounded_rect(v3_palm_w, v3_palm_d, palm_r);
}

module v3_palm_box_left() {
    difference() {
        union() {
            // シェル(リブなし)
            difference() {
                intersection() {
                    linear_extrude(60) v3_palm_fp2d();
                    halfspace_below_top(0);
                }
                intersection() {
                    translate([0, 0, -1]) linear_extrude(62) offset(delta = -v3_wall) v3_palm_fp2d();
                    halfspace_below_top(-v3_top);
                }
            }
            // ジョイントタブ(楔面-3.2 .. 0 のスラブ。北端はネジ穴縁の肉1.5mmを確保)
            // 上面は天板と完全に面一: 伏せ印刷でタブも1層目からベッドに接する
            // (0.2下げるとタブだけ浮いて1層目が欠ける)
            for (jx = v3_pj_xs)
                intersection() {
                    translate([jx - 7, -3, 0]) cube([14, 10.7, 60]);
                    halfspace_below_top(0);
                    halfspace_above_top(-3.2);
                }
        }
        // タブのネジ穴(縦M3なべ用ストレート穴, KB側ボスのネジ穴位置 y=4.5)
        for (jx = v3_pj_xs)
            translate([jx, 4.5, kb_top_z(jx) - 4.5]) cylinder(d = 3.4, h = 6);
    }
}

module v3_palm_box_right() { mirror([1, 0, 0]) v3_palm_box_left(); }
