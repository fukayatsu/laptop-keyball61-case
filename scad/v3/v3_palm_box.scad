// v3 パームボックス: 差し替え式の楔シェル(リブなし・底面開放)。
// 「天面をベッドに伏せて」印刷すればブリッジゼロ(partsファイルで180°±tent回転済み)。
// 北端: 天板と面一の長耳1枚(厚2.5, 穴3, 上面=楔面=印刷時のベッド接地面)が
// KBフレーム南壁の切り欠きに載り、上から縦M3x8なべ→KB側ボス帯の
// 横挿しナットスロットで締結。頭はジェルパッドの下。
// 耳はボール部品の張り出し帯(kb x>=46)を避けて x<=45.5 に収める。
// 北東の縁(x>=46)は張り出し部品と接触しないよう1mmセットバック。
// kbフレーム基準(北端 y=0, 耳は y>0 へ張り出す)。
include <v3_params.scad>

module v3_palm_fp2d() {
    difference() {
        translate([v3_palm_x0, -v3_palm_d]) rounded_rect(v3_palm_w, v3_palm_d, palm_r);
        // 張り出し帯に面する北縁のセットバック
        translate([46, -1]) square([v3_palm_w, 1.01]);
    }
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
                    translate([0, 0, -1]) linear_extrude(62)
                        offset(delta = -v3_wall) v3_palm_fp2d();
                    halfspace_below_top(-v3_top);
                }
            }
            // ジョイント長耳(楔面-2.5 .. 0 のスラブ, 上面=天板と完全面一)
            intersection() {
                translate([15, -3, 0]) cube([45.5 - 15, 10.7, 60]);
                halfspace_below_top(0);
                halfspace_above_top(-v3_pj_tab_t);
            }
        }
        // 耳のネジ穴(縦M3なべ用ストレート穴, KB側ボスのネジ穴位置 y=4.5)
        for (jx = v3_pj_xs)
            translate([jx, 4.5, kb_top_z(jx) - 4.5]) cylinder(d = 3.4, h = 6);
    }
}

module v3_palm_box_right() { mirror([1, 0, 0]) v3_palm_box_left(); }
