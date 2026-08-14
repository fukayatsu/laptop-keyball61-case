// ブレースプレート: ポッドの上を跨いで左右サイドを上側で連結する台形プレート。
// 下側の継手(タブ+ブリッジ)と合わせて閉断面になり、ねじり剛性が大幅に上がる。
// サイド内壁上面の座面(brace_shelf_z)に載り、M3x8皿セルフタップ x2/側で固定。
// 原点 = グローバルXY / z=0 がプレート下面(印刷はこのまま平置き)
include <lib.scad>

module brace() {
    difference() {
        linear_extrude(brace_t)
            polygon([
                [-(seam_x(brace_y0) + brace_overlap), brace_y0],
                [-(seam_x(brace_y1) + brace_overlap), brace_y1],
                [ (seam_x(brace_y1) + brace_overlap), brace_y1],
                [ (seam_x(brace_y0) + brace_overlap), brace_y0]
            ]);

        // TRSジャック/プラグ/ケーブル降下ゾーンの切り欠き(左右エッジ, 角R付き)
        for (m = [0, 1]) mirror([m, 0, 0])
            translate([0, 0, -1]) linear_extrude(brace_t + 2)
                offset(r = 4) offset(delta = -4)
                    polygon([
                        [-200,              brace_notch_y0],
                        [-200,              brace_notch_y1],
                        [-brace_notch_keep, brace_notch_y1],
                        [-brace_notch_keep, brace_notch_y0]
                    ]);

        // 固定ネジ(皿, 上から)
        for (sx = [-1, 1], y = brace_screw_ys)
            translate([sx * (seam_x(y) + brace_screw_inset), y, brace_t])
                m3_countersunk(brace_t + 1);
    }
}
