// Touch ID 取付プレート裏の十字フット(2mmスペーサ)
// 単純な角柱の足だと短辺6mmで倒れるため、直交バーを足して支持スパンを広げたもの。
// バー幅を決めているのはネジ穴ではなく「プレート裏に露出する超低頭ネジの頭」で、
// 穴中心から touchid_head_r を空ける。
include <touchid_plate.scad>

// X方向バー = 元からある支持帯(左端はプレート外形と面一のまま残す)
// Y方向バー = 左右のネジ穴列から touchid_head_r を空けた帯
touchid_ybar_hw = (touchid_hole_x[1] - touchid_hole_x[0]) / 2 - touchid_head_r;

module _touchid_band(b) translate(b[0]) square([b[1][0] - b[0][0], b[1][1] - b[0][1]]);

module touchid_foot_2d() {
    xb = touchid_foot_xbar;
    // closing(膨張->収縮)で内隅だけにRが付く。外周の寸法は変わらない
    offset(r = -touchid_foot_fillet) offset(r = touchid_foot_fillet)
    union() {
        _touchid_band([[xb[0][0], touchid_hole_cy - xb[1]],
                       [xb[0][1], touchid_hole_cy + xb[1]]]);
        intersection() {
            _touchid_band([[touchid_hole_cx - touchid_ybar_hw, -1],
                           [touchid_hole_cx + touchid_ybar_hw, touchid_plate_d + 1]]);
            // プレート外形(南辺の切欠きを含む)から控えて端を決める
            offset(r = -touchid_foot_edge_clr) touchid_outline_2d();
        }
    }
}

module touchid_foot() linear_extrude(touchid_foot_h) touchid_foot_2d();
