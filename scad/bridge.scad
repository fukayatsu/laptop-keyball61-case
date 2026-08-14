// 中央ブリッジ: サイド2枚を後方でつなぐ台形ピース。Touch ID ポッドを搭載。
// 前方中央(y < bridge_y0)は開放空間。
// 継手: ブリッジのひさし(厚3.6)がサイド下面の欠きに入り、
//       下から M3x8 皿 -> サイド側の六角ナットポケット で締結(下面ツライチ)。
include <lib.scad>

// コア西端X(左, 正値): 継ぎ目からクリアランス分だけ内側
function bx(y) = seam_x(y) - seam_clr;

// kbローカル座標 -> グローバル座標(左サイド)
function kb2glob(p) = [
    -kb_corner_x + (p[0] - kbw) * cos(splay) + (p[1] - kbd) * sin(splay),
     kb_corner_y - (p[0] - kbw) * sin(splay) + (p[1] - kbd) * cos(splay)
];

ledge_y0 = 95;
ledge_y1 = 235;

module bridge() {
    difference() {
        union() {
            // コア(台形)
            linear_extrude(bridge_t)
                polygon([
                    [-bx(bridge_y0), bridge_y0],
                    [-bx(bridge_y1), bridge_y1],
                    [ bx(bridge_y1), bridge_y1],
                    [ bx(bridge_y0), bridge_y0]
                ]);
            // (継手はサイド側が凸。ブリッジは下面ポケットで受ける)
        }

        // サイドの連続タブ用の下面ポケット(西端は縁まで開放)。
        // ポケット内のリブ(サイド側切り欠きと噛み合う)が天井の中間支柱になり、
        // 天井は両端支持の約28mmブリッジ×5区間となりサポート不要
        for (m = [0, 1]) mirror([m, 0, 0])
            difference() {
                y0 = joint_y0 - clr;
                y1 = joint_y1 + clr;
                translate([0, 0, -0.01]) linear_extrude(ledge_t + 0.11)
                    polygon([
                        [-bx(y0) - 2,                   y0],
                        [-bx(y1) - 2,                   y1],
                        [-(seam_x(y1) - ledge_w - clr), y1],
                        [-(seam_x(y0) - ledge_w - clr), y0]
                    ]);
                // リブ(残す部分)
                for (ry = joint_rib_ys)
                    translate([-(seam_x(ry)) - 3, ry - joint_rib_w/2, -1])
                        cube([ledge_w + 4, joint_rib_w, ledge_t + 2]);
            }

        // 継手ネジ: 貫通穴 + 上面の浅い六角ナットポケット(上から落とし込み)
        for (m = [0, 1], y = joint_screw_ys) mirror([m, 0, 0]) {
            sx = -(seam_x(y) - joint_screw_inset);
            translate([sx, y, -1]) cylinder(d = m3_hole_d, h = bridge_t + 2);
            translate([sx, y, bridge_t - 2.5])
                cylinder(d = m3_nut_af / cos(30), h = 3.6, $fn = 6);
        }

        // Touch ID ポッド固定: M3x8皿セルフタップ用の下穴(止まり穴, 蓋ネジと同方式)
        // フランジ(4)を貫通した M3x8 が 4mm 食い付く。底面に穴は開かない
        for (sx = [-pod_screw_span/2, pod_screw_span/2])
            translate([sx, pod_y, 3]) cylinder(d = 2.6, h = bridge_t);

        // ケーブル用ベルクロスロット(北端付近)
        for (sx = [-25, 25])
            translate([sx - 6, 242, -1]) cube([12, 4, bridge_t + 2]);
    }
}
