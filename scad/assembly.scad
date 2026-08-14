// 組立プレビュー(印刷用ではない)
// F5 で全体レイアウトを確認。demo_explode で分解図。
include <lib.scad>
use <side.scad>
use <bridge.scad>
use <brace.scad>
use <touchid_pod.scad>

demo_explode = 0;  // 分解図: 部品を引き離す距離 例: 45

color("slategray") {
    translate([-demo_explode, 0, 0]) side_left();
    translate([ demo_explode, 0, 0]) side_right();
}
color("dimgray") bridge();

color("steelblue")
    translate([0, pod_y - pod_flange_off, bridge_t + demo_explode]) pod_tray();
color("lightsteelblue")
    translate([0, pod_y - pod_flange_off, bridge_t + 3 + tid_bay_h + 1 + 2 * demo_explode])
    pod_lid();

// ---- ブレースプレート ----
color("cadetblue")
    translate([0, 0, brace_shelf_z + 3 * demo_explode]) brace();
