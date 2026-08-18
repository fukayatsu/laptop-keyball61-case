#!/usr/bin/env python3
"""v4 STLの設計検証: make v4 のあとに `make check-v4` で実行する。
必要: pip install trimesh numpy

チェック: 単一ボディ/watertight・プレートが完全平面(ベタ置き印刷)・
ジョイント軸6本の素通し+穴周囲の材料・ナット位置の空洞・プレート⇔箱の干渉。
注意: 材料存在のテスト点はネジ穴軸上に置かない(誤判定する)。
"""
import math
import sys

import numpy as np
import trimesh

PLATE_W, PLATE_D = 142.99, 113.53
KBW, KBD = PLATE_W + 12, PLATE_D + 12
SPLAY, TENT = 10.0, 7.0
V4_CORNER = (20.0, 238.0)
CJ_YS = [120, 170, 220]
PT, FIT, SPINE_Z0 = 2.0, 0.15, 13.5

TAN_T = math.tan(math.radians(TENT))
COS_T, SIN_T = math.cos(math.radians(TENT)), math.sin(math.radians(TENT))
COS_S, SIN_S = math.cos(math.radians(SPLAY)), math.sin(math.radians(SPLAY))


def seam(y):
    return V4_CORNER[0] + (V4_CORNER[1] - y) * math.tan(math.radians(SPLAY))


def rot(deg, axis):
    return trimesh.transformations.rotation_matrix(math.radians(deg), axis)


def tr(v):
    return trimesh.transformations.translation_matrix(v)


def place_left():
    return tr([-V4_CORNER[0], V4_CORNER[1], 0]) @ rot(-SPLAY, [0, 0, 1]) @ tr([-KBW, -KBD, 0])


FAILS = []


def check(label, ok):
    print(("  OK  " if ok else "  NG  ") + label)
    if not ok:
        FAILS.append(label)


def main():
    pl = trimesh.load("stl/v4_plate_left.stl")
    pr = trimesh.load("stl/v4_plate_right.stl")
    cb = trimesh.load("stl/v4_center_spine.stl")
    cv = trimesh.load("stl/v4_center_cover.stl")

    print("[1] 単一ボディ / watertight / 平面性")
    for name, m in [("plate_left", pl), ("plate_right", pr), ("center_spine", cb),
                    ("center_cover", cv)]:
        bodies = len(m.split(only_watertight=False))
        check(f"{name}: bodies={bodies}, watertight={m.is_watertight}",
              bodies == 1 and m.is_watertight)
    for name, m in [("plate_left", pl), ("plate_right", pr)]:
        check(f"{name}: 下面フラット(zmin={round(m.bounds[0][2],3)}, "
              f"z範囲{round(m.bounds[1][2],1)})",
              abs(m.bounds[0][2]) < 0.01 and m.bounds[1][2] < 9)
    check(f"center_spine(印刷向き): 底面フラット接地(zmin={round(cb.bounds[0][2],3)})",
          abs(cb.bounds[0][2]) < 0.01)
    check(f"center_cover(印刷向き): 底面フラット接地(zmin={round(cv.bounds[0][2],3)})",
          abs(cv.bounds[0][2]) < 0.01)

    # グローバル配置
    plg = pl.copy()
    plg.apply_transform(place_left() @ rot(-TENT, [0, 1, 0]))
    cbg = cb.copy()
    cbg.apply_transform(tr([0, 0, SPINE_Z0]))  # 印刷並進を戻す

    print("[2] ジョイント軸の素通し + 穴周囲の材料 (左側)")
    n = np.array([-SIN_T * COS_S, SIN_T * SIN_S, COS_T])  # 左プレート法線
    for jy in CJ_YS:
        # 屋根上面のネジ軸位置(kbローカル(kbw+6, jyl) -> グローバル)
        p0 = np.array([-(seam(jy) - 6 * COS_S), jy - 6 * SIN_S,
                       0])
        # z: プレート下面平面 z = kb_x*tanT。kb_x = kbw+6
        p0[2] = (KBW + 6) * TAN_T - FIT
        ts = np.arange(-9.0, 3.0, 0.5)
        axis = p0 + np.outer(ts, n)
        clear = plg.contains(axis).sum() == 0 and cbg.contains(axis).sum() == 0
        ring_plate = all(plg.contains([p0 + n * (FIT + 1.0) + d])[0]
                         for d in ([3.0, 0, 0], [-3.0, 0, 0], [0, 3.0, 0], [0, -3.0, 0]))
        ring_roof = all(cbg.contains([p0 - n * 1.2 + d])[0]
                        for d in ([3.0, 0, 0], [-3.0, 0, 0], [0, 3.0, 0], [0, -3.0, 0]))
        nut_void = not cbg.contains([p0 - n * 4.2])[0]  # 六角ポケット内(天井-3.15の下)
        check(f"jy={jy}: 軸素通し={clear}, プレート穴周囲={ring_plate}, "
              f"スパイン穴周囲={ring_roof}, ナット位置空洞={nut_void}",
              clear and ring_plate and ring_roof and nut_void)

    print("[3] 印刷オーバーハング(スパイン・印刷向き)")
    # 中実スパインはベタ置きでサポートゼロのはず。許容されるのは
    # 六角ナットポケットの天井6箇所(約20mm2×6=1.2cm2, 6.7mm幅のマイクロブリッジ)のみ
    fn, fz = cb.face_normals, cb.triangles_center[:, 2]
    over_area = cb.area_faces[(fn[:, 2] < -0.75) & (fz > 0.5)].sum() / 100
    check(f"41°超の下向き面 {round(over_area,2)}cm2 (< 2cm2)", over_area < 2)

    print("[3.5] カバー取付ネジ(軸素通し+スパイン下穴)")
    cvg = cv.copy()
    cvg.apply_transform(tr([0, 0, 1.0]))  # 印刷並進を戻す
    for sx, sy in [[-24, 120], [24, 120], [-10, 218], [10, 218]]:
        zs = np.arange(2.0, 18.3, 0.4)
        axis = np.column_stack([np.full_like(zs, sx), np.full_like(zs, sy), zs])
        clear = cvg.contains(axis).sum() == 0 and cbg.contains(axis).sum() == 0
        ring = all(cvg.contains([[sx + dx, sy + dy, 12.0]])[0]
                   for dx, dy in [(4.2, 0), (-4.2, 0), (0, 4.2), (0, -4.2)])
        nut_void = not cbg.contains([[sx, sy, 17.2]])[0]  # 六角井戸内
        seat = cbg.contains([[sx, sy + 4.6, 15.0]])[0]     # 井戸床下の材料
        check(f"({sx},{sy}): 軸素通し={clear}, ボス材料={ring}, "
              f"井戸空洞={nut_void}, 床材料={seat}", clear and ring and nut_void and seat)

    print("[4] 干渉サンプリング")
    rng = np.random.default_rng(7)
    lo = np.maximum(plg.bounds[0], cbg.bounds[0])
    hi = np.minimum(plg.bounds[1], cbg.bounds[1])
    pts = rng.uniform(lo, hi, (40000, 3))
    ina = plg.contains(pts)
    hits = int(cbg.contains(pts[ina]).sum()) if ina.any() else 0
    check(f"プレート⇔スパイン: {hits}/40000", hits == 0)
    lo = np.maximum(cvg.bounds[0], cbg.bounds[0])
    hi = np.minimum(cvg.bounds[1], cbg.bounds[1])
    if np.all(hi > lo):
        pts = rng.uniform(lo, hi, (40000, 3))
        ina = cvg.contains(pts)
        hits = int(cbg.contains(pts[ina]).sum()) if ina.any() else 0
        check(f"カバー⇔スパイン: {hits}/40000", hits == 0)

    print()
    if FAILS:
        print(f"NG {len(FAILS)}件:")
        for f in FAILS:
            print("  -", f)
        sys.exit(1)
    print("全チェックOK")


if __name__ == "__main__":
    main()
