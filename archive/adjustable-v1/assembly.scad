// 組立プレビュー(印刷用ではない)
// F5 で全体レイアウトを確認。demo_rotate / demo_slide で調整範囲を確認できる。
include <lib.scad>
use <carriage.scad>
use <base.scad>
use <touchid_pod.scad>

demo_rotate  = 0;  // ハの字角度プレビュー(+で前が開く) 例: 15
demo_slide   = 0;  // 左右スライド量 例: -20(外) .. +20(内)
demo_explode = 0;  // 分解図: 部品を引き離す距離 例: 40

// ---- ベース ----
color("dimgray") {
    translate([-(base_center_w/2 + base_side_w) - demo_explode, 0, 0]) base_left();
    translate([base_center_w/2 + demo_explode, 0, 0]) base_right();
    translate([-base_center_w/2, 0, 0]) base_center();
}

// ---- キャリッジ(ピボット中心に回転デモ) ----
// 左: ピボットのグローバル位置
lp = [-(car_inner_gap + car_w) + knob_x - demo_slide, 7 + pivot_y];
color("slategray") translate([lp[0] - demo_explode, lp[1], base_t + demo_explode])
    rotate([0, 0, -demo_rotate]) translate([-knob_x, -pivot_y, 0]) carriage_left();
rp = [car_inner_gap + car_w - knob_x + demo_slide, 7 + pivot_y];
color("slategray") translate([rp[0] + demo_explode, rp[1], base_t + demo_explode])
    rotate([0, 0, demo_rotate]) translate([-(car_w - knob_x), -pivot_y, 0]) carriage_right();

// ---- Touch ID ポッド ----
color("steelblue") translate([0, pod_y - pod_flange_off, base_t + demo_explode])
    pod_tray();
color("lightsteelblue")
    translate([0, pod_y - pod_flange_off, base_t + 3 + tid_bay_h + 1 + 2 * demo_explode])
    pod_lid();
