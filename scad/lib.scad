// 共通モジュール
include <params.scad>
include <keyball61_outline.scad>

// キーボードブロック外形(kbローカル座標系)
kbw = plate_w + 2 * kb_wall;   // 幅
kbd = plate_d + 2 * kb_wall;   // 奥行き

// ---- テンティング用の傾斜半空間(kbローカル座標系) ----
// 上面平面: z = wedge_t0 + dz + x*tan(tent_angle)  (x=0 が外側=低い側)
module halfspace_below_top(dz = 0) {
    translate([0, 0, wedge_t0 + dz])
        rotate([0, -tent_angle, 0])
            translate([-1000, -500, -2000]) cube([3000, 2000, 2000]);
}
module halfspace_above_top(dz = 0) {
    translate([0, 0, wedge_t0 + dz])
        rotate([0, -tent_angle, 0])
            translate([-1000, -500, 0]) cube([3000, 2000, 2000]);
}

// kbローカルxにおける上面/ポケット床の高さ
function kb_top_z(x) = wedge_t0 + x * tan(tent_angle);
function pocket_floor_z(x) = kb_top_z(x) - pocket_depth;

// 継ぎ目: 左サイドの楔内側エッジのX(グローバル, 正値で返す)
// エッジは (kb_corner_x, kb_corner_y) から南へ向かって splay だけ開く
function seam_x(y) = kb_corner_x + (kb_corner_y - y) * tan(splay);

// ---- プレート外形(左手ユニット・上面視) ----
// DXFの描画は「右手ユニット上面視を180°回転」した状態なので、
// Y反転すると左手ユニット上面視(手前=ボール側, 奥=MCU/USB側)になる
module plate2d(off = 0) {
    translate([0, plate_d]) mirror([0, 1]) {
        if (off > 0) offset(r = off) polygon(plate_outline);
        else polygon(plate_outline);
    }
}

// Y反転済みの穴リスト [x, y, d]
plate_holes_f = [for (h = plate_holes) [h[0], plate_d - h[1], h[2]]];

// ---- 角丸長方形 ----
module rounded_rect(w, d, r) {
    offset(r = r) offset(delta = -r) square([w, d]);
}

// ---- M3 六角ナットポケット 原点=軸, z=0から上へ掘る ----
module m3_nut_pocket() {
    translate([0, 0, m3_nut_t/2 - 0.01])
        cylinder(d = m3_nut_af / cos(30), h = m3_nut_t + 0.02, center = true, $fn = 6);
}

// ---- M3 皿ネジ穴 原点=軸/z=0が頭側表面, 下向きに掘る ----
module m3_countersunk(depth) {
    translate([0, 0, -depth - 0.01]) cylinder(d = m3_hole_d, h = depth + 0.02);
    translate([0, 0, -(m3_cs_d - m3_hole_d)/2]) cylinder(d1 = m3_hole_d, d2 = m3_cs_d, h = (m3_cs_d - m3_hole_d)/2 + 0.01);
    translate([0, 0, -0.005]) cylinder(d = m3_cs_d, h = 5);
}
