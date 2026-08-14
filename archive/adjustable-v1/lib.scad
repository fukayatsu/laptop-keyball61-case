// 共通モジュール
include <params.scad>
include <keyball61_outline.scad>

// ---- キャリッジ用: 傾斜半空間 ----
// 上面平面: z = car_base_t + dz + x*tan(tent_angle)
module halfspace_below_top(dz = 0) {
    translate([0, 0, car_base_t + dz])
        rotate([0, -tent_angle, 0])
            translate([-1000, -500, -2000]) cube([3000, 2000, 2000]);
}
module halfspace_above_top(dz = 0) {
    translate([0, 0, car_base_t + dz])
        rotate([0, -tent_angle, 0])
            translate([-1000, -500, 0]) cube([3000, 2000, 2000]);
}

// キャリッジ上面の高さ(ローカルxにおける)
function car_top_z(x) = car_base_t + x * tan(tent_angle);
// ポケット床の高さ
function pocket_floor_z(x) = car_top_z(x) - pocket_depth;
// ポケット原点Y
pocket_y0 = car_d - pocket_north_margin - plate_d;

// ---- プレート外形(左手ユニット) ----
module plate2d(off = 0) {
    if (off > 0) offset(r = off) polygon(plate_outline);
    else polygon(plate_outline);
}

// ---- 角丸長方形 ----
module rounded_rect(w, d, r) {
    offset(r = r) offset(delta = -r) square([w, d]);
}

// ---- Tスロット溝(負形状) X方向・原点=溝中心線の西端 ----
module t_channel(len) {
    // 上面開口
    translate([0, -ch_slot_w/2, base_t - ch_top_t - 0.01])
        cube([len, ch_slot_w, ch_top_t + 1]);
    // ナット空洞
    translate([0, -ch_cav_w/2, base_t - ch_top_t - ch_cav_h])
        cube([len, ch_cav_w, ch_cav_h]);
    // 底抜きスロット(ネジ先端の逃げ)
    translate([0, -ch_bot_slot_w/2, -1])
        cube([len, ch_bot_slot_w, base_t]);
}

// ---- M3 六角ナットポケット(下から挿入) 原点=ナット中心軸/z=0が下面 ----
module m3_nut_pocket() {
    translate([0, 0, m3_nut_t/2 - 0.01])
        cylinder(d = m3_nut_af / cos(30), h = m3_nut_t + 0.02, center = true, $fn = 6);
}

// ---- M3 皿ネジ穴(上から) 原点=軸/z=0が頭側表面, 下向きに掘る ----
module m3_countersunk(depth) {
    translate([0, 0, -depth - 0.01]) cylinder(d = m3_hole_d, h = depth + 0.02);
    translate([0, 0, -(m3_cs_d - m3_hole_d)/2]) cylinder(d1 = m3_hole_d, d2 = m3_cs_d, h = (m3_cs_d - m3_hole_d)/2 + 0.01);
    translate([0, 0, -0.005]) cylinder(d = m3_cs_d, h = 5);
}

// ---- Y方向スロット(負形状, 縦穴) ----
module slot_y(y0, y1, d, h0 = -1, h1 = 60) {
    hull() {
        translate([0, y0, h0]) cylinder(d = d, h = h1 - h0);
        translate([0, y1, h0]) cylinder(d = d, h = h1 - h0);
    }
}
