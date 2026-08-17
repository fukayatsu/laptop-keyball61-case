include <v4_center_spine.scad>
// 底面(フラット)をベッドに置いて印刷。上面は7°の緩斜面でサポートゼロ
translate([0, 0, -v4_spine_z0]) v4_center_spine();
