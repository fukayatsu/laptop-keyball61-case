// v4 センターカバー: スパインの下の空間(z1..13.5)を覆う薄いカバー。
// スパインの底面フラットがそのまま蓋(天井)になり、内側の空間(深さ約10mm)に
// ケーブルやTouch IDモジュール等を収められる(スパインの結束バンドスロットで固定)。
//  - 底2mm+スカート壁2mm。外周はスパインの縫い目から外側(プレートの下)へ
//    v4_cover_e 広げた台形。左右間隔の短縮(v4_corner_x=10)でスパインが細くなり
//    Touch ID基板85x31が入らなくなったため(2026-10-14)。広げた部分の天井は
//    プレート下面(縁との隙間2.4mm以上)。TRSケーブル通し穴もカバー内に収まり、
//    プラグはそのままカバー内へ下ろせる
//  - 内側寄りのキーボードM2穴(縫い目から21.2mm)はカバー内、29.0mmは外側
//    (壁から1mm以上離して下からのドライバーを通す)
//  - 取付: 下からM3x8皿 x4。頭はボス内の深座ぐり奥の90°皿座に座り、
//    スパイン上面の六角井戸に落としたナットへ全ネジ掛かり
//  - ケーブルノッチ: 北縁(USB)
// 印刷: 底をベッドに置いてそのまま(サポート不要)
include <v4_center_spine.scad>

v4_cover_z0 = 1;      // 底の下面(接地1mmクリア)
v4_cover_t  = 2;      // 底/壁の厚さ
v4_cover_rim = v4_spine_z0 - 0.05;   // 縁の上端(スパイン底面-0.05)
v4_cover_ch = 1.2;    // 底面外周の45°面取り(足に当たるエッジ)
v4_cover_e  = 26;     // 縫い目から外側への張り出し(縫い目に直交方向)

module v4_cover_fp2d() {
    sh = v4_cover_e / cos(splay);
    offset(r = v4_r) offset(delta = -v4_r)
        polygon([
            [-v4_seam(v4_y0) - sh, v4_y0],
            [-v4_seam(v4_y1) - sh, v4_y1],
            [ v4_seam(v4_y1) + sh, v4_y1],
            [ v4_seam(v4_y0) + sh, v4_y0]
        ]);
}

module v4_center_cover() {
    difference() {
        union() {
            // 底+スカート壁。底面の外周エッジは45°面取り
            // (下面は足に当たる可能性があるため。外形は凸形状なのでhullでテーパー)
            difference() {
                union() {
                    hull() {
                        translate([0, 0, v4_cover_z0]) linear_extrude(0.01)
                            offset(delta = -v4_cover_ch) v4_cover_fp2d();
                        translate([0, 0, v4_cover_z0 + v4_cover_ch]) linear_extrude(0.01)
                            v4_cover_fp2d();
                    }
                    translate([0, 0, v4_cover_z0 + v4_cover_ch])
                        linear_extrude(v4_cover_rim - v4_cover_z0 - v4_cover_ch)
                            v4_cover_fp2d();
                }
                translate([0, 0, v4_cover_z0 + v4_cover_t])
                    linear_extrude(20)
                        offset(delta = -v4_cover_t) v4_cover_fp2d();
            }
            // 取付ボス(Φ10筒, 底から縁まで)
            for (s = v4_case_screws)
                translate([s[0], s[1], v4_cover_z0])
                    cylinder(d = 10, h = v4_cover_rim - v4_cover_z0);
        }

        // 取付ネジ穴: Φ3.4貫通 + Φ7深座ぐり + 奥は90°の皿座(M3x8皿用)。
        // 皿座=45°テーパーなのでブリッジなしで綺麗に印刷できる。
        // 座ぐりの口元も45°面取り(下面のエッジを全て丸める)
        for (s = v4_case_screws) {
            translate([s[0], s[1], v4_cover_z0 - 1]) cylinder(d = 3.4, h = 20);
            translate([s[0], s[1], v4_cover_z0 - 1])
                cylinder(d = 7, h = 1 + (v4_cover_rim - v4_cover_z0) - 3);
            translate([s[0], s[1], v4_cover_z0 + (v4_cover_rim - v4_cover_z0) - 3 - 0.01])
                cylinder(d1 = 7, d2 = 3.4, h = 1.8);
            translate([s[0], s[1], v4_cover_z0 - 0.01])
                cylinder(d1 = 9, d2 = 7, h = 1);
        }

        // ケーブルノッチ(縁から下へ8mm): 北=USB出口
        translate([-7, v4_y1 - 12, v4_cover_rim - 8]) cube([14, 12, 10]);
    }
}
