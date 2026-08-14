// サイドピース: キーボード取付面 + パームレスト + 7°テンティング楔 (固定式)
// ケースはキーボードのアクリル底板の置き換え。取付面(彫り込みの床)に
// スペーサーを載せ、純正M2ネジ / ボールケースネジで下から直接固定する。
// kbローカル座標系(x=0が外側=低い側)でブロックを作り、
// ハの字 splay 回転してグローバル座標に配置する。右は左のミラー。
include <lib.scad>

// パームレストのオフセット(kbフレーム)
palm_y0 = -(palm_d - palm_overlap);

// ---- フットプリント(kbフレーム) ----
// パームは外側(x=palm_x0)基準で幅 palm_w。親指側(内側)は大きく開ける。
// ただしブレース南帯の座面・ネジ座が載る内側エッジ沿いは支持アームを残す
module kb_footprint2d() {
    // クロージング(R=palm_fillet)でアーム両脇の鋭い凹みを滑らかな曲線で埋め、
    // オープニング(R=2)で凸角の尖りを丸める。直線エッジ(継ぎ目)は変化しない
    offset(r = 2) offset(r = -(palm_fillet + 2)) offset(r = palm_fillet)
    union() {
        hull() {
            rounded_rect(kbw, kbd, 6);
            translate([palm_x0, palm_y0]) rounded_rect(palm_w, palm_d, palm_r);
        }
        // 内側エッジ沿いの支持アーム(南端は斜めに落とす)
        polygon([
            [kbw - palm_arm_w, 4],
            [kbw, 4],
            [kbw, palm_arm_y0],
            [kbw - palm_arm_w, palm_arm_y0 + 12]
        ]);
    }
}

// ---- キーボードブロック(kbフレーム) ----
module kb_block() {
    difference() {
        // 楔本体
        intersection() {
            linear_extrude(60) kb_footprint2d();
            halfspace_below_top(0);
        }

        // 取付面の彫り込み(アクリル外形+クリアランス)
        intersection() {
            translate([kb_wall, kb_wall, -1]) linear_extrude(80) plate2d(clr);
            halfspace_above_top(-pocket_depth);
        }

        // ボールPCB切り欠き部の逃げ(プレート外形の外側のみ、床からさらに掘り下げ)
        // 東端はプレート外形まで: 内壁と継ぎ目帯(ブレース座面が載る)は削らない
        difference() {
            intersection() {
                translate([kb_wall + 91, -1, -1])
                    cube([plate_w - 91 + 0.5, kb_wall + 47, 80]);
                halfspace_above_top(-pocket_depth - notch_relief);
            }
            translate([kb_wall, kb_wall, -2]) linear_extrude(84) plate2d(0);
        }

        // 固定穴・ボール取出し穴 (plate_holes_f は前後反転済み)
        for (h = plate_holes_f) {
            hx = kb_wall + h[0];
            hy = kb_wall + h[1];
            if (h[2] > 1.9 && h[2] < 2.35) {
                // M2: スペーサーへ下からネジ止め。残り肉厚 = アクリル板厚(2.0)
                translate([hx, hy, -1]) cylinder(d = m2_hole_d, h = 80);
                translate([hx, hy, -1]) cylinder(d = m2_cb_d, h = 1 + pocket_floor_z(hx) - m2_remain);
            }
            if (h[2] >= 2.35 && h[2] < 4) {
                // ボールケース固定: 純正セルフタップが白ケースに届く残り肉厚
                translate([hx, hy, -1]) cylinder(d = bc_hole_d, h = 80);
                translate([hx, hy, -1]) cylinder(d = bc_cb_d, h = 1 + pocket_floor_z(hx) - m2_remain);
            }
            if (h[2] > 10) {
                // ボール取出し穴
                translate([hx, hy, -1]) cylinder(d = ball_hole_d, h = 80);
            }
        }
    }
}

// ---- グローバル配置(左): 後内側コーナー(kbw,kbd)を(-kb_corner_x, kb_corner_y)へ ----
module place_left() {
    translate([-kb_corner_x, kb_corner_y, 0])
        rotate([0, 0, -splay])
            translate([-kbw, -kbd, 0])
                children();
}

// ---- 左サイドピース(グローバル座標) ----
// 継手はサイド側が凸: 底面レベルのタブ(z0..ledge_t)が内側へ突き出し、
// ブリッジ下面のポケットに入る。タブはベッド直上に印刷されるためサポート不要
module side_left() {
    difference() {
        union() {
            place_left() kb_block();

            // 連続継手タブ(東=中央方向へ突出)
            linear_extrude(ledge_t)
                polygon([
                    [-(seam_x(joint_y0)) - 5,       joint_y0],
                    [-(seam_x(joint_y1)) - 5,       joint_y1],
                    [-(seam_x(joint_y1) - ledge_w), joint_y1],
                    [-(seam_x(joint_y0) - ledge_w), joint_y0]
                ]);
        }

        // リブ用の切り欠き(ブリッジ側リブと噛み合う)
        for (ry = joint_rib_ys) {
            w = joint_rib_w + 2 * clr;
            translate([-(seam_x(ry)) - 0.7, ry - w/2, -0.01])
                cube([ledge_w + 2, w, ledge_t + 0.11]);
        }

        // 継手ネジ: タブ下面から M3x8 皿(頭は底面ツライチ)。ナットはブリッジ上面側
        for (y = joint_screw_ys)
            translate([-(seam_x(y) - joint_screw_inset), y, 0])
                mirror([0, 0, 1]) m3_countersunk(ledge_t + 1);

        // ブレースプレート用の座面(内壁上面を水平に彫る)
        translate([0, 0, brace_shelf_z]) linear_extrude(30)
            polygon([
                [-(seam_x(brace_y0 - 2)) + 2,             brace_y0 - 2],
                [-(seam_x(brace_y1 + 2)) + 2,             brace_y1 + 2],
                [-(seam_x(brace_y1 + 2) + brace_shelf_w), brace_y1 + 2],
                [-(seam_x(brace_y0 - 2) + brace_shelf_w), brace_y0 - 2]
            ]);

        // ブレース固定ネジの下穴(M3セルフタップ)
        for (y = brace_screw_ys)
            translate([-(seam_x(y) + brace_screw_inset), y, brace_shelf_z - 7])
                cylinder(d = 2.6, h = 7.5);
    }
}

module side_right() {
    mirror([1, 0, 0]) side_left();
}
