// ============================================================
// Touch ID モジュール取付プレート + 十字フット のパラメータ
// 座標系: 上から見た形 / 原点=外形バウンディングボックスの南西角 / +Z=天面側
// 寸法はモジュール実物に合わせた実測値
// ============================================================

// ---------- プレート外形 ----------
touchid_plate_w = 15.6;   // 幅
touchid_plate_d = 16.0;   // 奥行き
touchid_plate_t = 0.9;    // 板厚(ネジ穴が貫通する厚み)
touchid_r_corner = 1.8;   // 南西・南東・北東の角R
touchid_r_nw     = 5.3;   // 北西の角R(ここだけ大きい)

// 南辺の切欠き(ケーブル逃げ)
touchid_notch_x  = [4.8, 10.8];
touchid_notch_d  = 1.0;

// ---------- ネジ穴 ----------
// 超低頭ネジ。軸φ1.8が通り、頭φ2.72がプレート裏に露出する
touchid_hole_d = 2.5;     // 通し穴。φ2.7では頭が座らず抜ける
touchid_head_d = 2.72;    // 頭径(実測)
touchid_hole_x = [3.0, 12.6];
touchid_hole_y = [2.65, 13.0];

// ---------- 天面のボス(モジュールの当たり面) ----------
touchid_boss_d = 3.0;
touchid_boss_h = 0.15;

// ---------- 十字フット ----------
touchid_foot_h        = 2.0;   // プレート裏に噛ませるスペーサ厚
touchid_foot_head_clr = 0.64;  // ネジ頭の外周からフットまでの逃げ
touchid_foot_fillet   = 1.0;   // 十字の内隅R(応力集中よけ)
touchid_foot_edge_clr = 0.3;   // Y方向バー端をプレート外形から控える量
touchid_foot_xbar     = [[0, 15.1], 3.0];  // [Xの範囲, ネジ列中心からの半幅]

// ---------- 導出 ----------
touchid_holes = [for (y = touchid_hole_y, x = touchid_hole_x) [x, y]];
touchid_hole_cx = (touchid_hole_x[0] + touchid_hole_x[1]) / 2;
touchid_hole_cy = (touchid_hole_y[0] + touchid_hole_y[1]) / 2;
// 穴中心から確保すべき逃げ半径(ネジ穴ではなく「裏に出る頭」で決まる)
touchid_head_r = touchid_head_d / 2 + touchid_foot_head_clr;
