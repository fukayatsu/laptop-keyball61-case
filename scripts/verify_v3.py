#!/usr/bin/env python3
"""v3 STLの設計検証: make v3 のあとに `make check` で実行する。

必要: pip install trimesh numpy

チェック内容(過去に実際に起きた設計ミスに対応):
  1. 各パーツが単一ボディ・watertight であること
  2. 伏せ印刷パーツ(パーム/中央箱)のジョイント耳が印刷1層目に接地していること
  3. ジョイントのネジ軸12本が両部品を素通しできること(軸上に材料がない)
     + 穴の周囲に材料があること(穴位置の座標変換ミスで逆側に開いたことがある)
  4. ナット挿入スロットの中心(=ネジ軸直下)が空洞であること
  5. 部品間の干渉サンプリングが0であること(KB⇔中央 / KB⇔パーム / KB⇔プレート)
  6. プレート穴の7mmルール: 全キーボード穴の周囲r6.5・座面下に構造がないこと
     (v3初回印刷でネジ頭・スペーサーが内部構造と干渉した)

注意: テスト点をネジ穴の軸上に置くと「材料なし」と誤判定するので、
材料の存在確認は必ず穴からオフセットした点で行うこと。
"""
import math
import sys

import numpy as np
import trimesh

# ---- scad/params.scad, scad/v3/v3_params.scad と一致させること ----
PLATE_W, PLATE_D = 142.99, 113.53
KBW, KBD = PLATE_W + 12, PLATE_D + 12
SPLAY, TENT = 10.0, 7.0
WEDGE_T0 = 6.0
KB_WALL = 6.0
V3_CORNER = (20.0, 238.0)        # v3_corner_x (左右間隔5cm短縮)
CJ_YS = [120, 170, 220]
CJ_SCREW_IN = 6.0
PJ_XS = [22, 32, 41]
PJ_SCREW_Y = 4.5
PJ_TAB_T = 2.5
CBOX_H = 16.0
SLOT_T, SLOT_CEIL = 2.7, 2.5
POCKET = 4.6
GRID_X, GRID_Y = [44, 113], [45, 74]
V3_WALL, SEAT_W = 2.5, 4.0
POD_Y = 178.0

# キーボード穴(プレート座標, Y反転済み) [px, py, d]
RAW_HOLES = [
    [71.961, 95.252, 12.0], [61.104, 103.252, 2.5], [61.104, 87.252, 2.5],
    [56.455, 61.351, 2.2], [128.785, 88.912, 2.2], [57.292, 18.55, 2.2],
    [18.773, 87.402, 2.2], [18.773, 30.251, 2.2], [94.556, 21.051, 2.2],
    [95.392, 61.651, 2.2], [120.871, 101.715, 2.2],
]
HOLES = [(h[0], PLATE_D - h[1], h[2]) for h in RAW_HOLES]

TAN_T = math.tan(math.radians(TENT))
COS_T = math.cos(math.radians(TENT))
COS_S, SIN_S = math.cos(math.radians(SPLAY)), math.sin(math.radians(SPLAY))


def seam(y):
    return V3_CORNER[0] + (V3_CORNER[1] - y) * math.tan(math.radians(SPLAY))


def kb_top_z(x):
    return WEDGE_T0 + x * TAN_T


def kb_xy(px, py):
    """プレート座標 -> kbローカル水平座標"""
    return KB_WALL + px * COS_T, KB_WALL + py


def load(name):
    return trimesh.load(f"stl/{name}.stl")


def rot(deg, axis):
    return trimesh.transformations.rotation_matrix(math.radians(deg), axis)


def place_left():
    """kbローカル -> グローバル(左)"""
    t1 = trimesh.transformations.translation_matrix([-KBW, -KBD, 0])
    t2 = trimesh.transformations.translation_matrix([-V3_CORNER[0], V3_CORNER[1], 0])
    return t2 @ rot(-SPLAY, [0, 0, 1]) @ t1


FAILS = []


def check(label, ok):
    print(("  OK  " if ok else "  NG  ") + label)
    if not ok:
        FAILS.append(label)


def main():
    parts = ["v3_kb_box_left", "v3_kb_box_right", "v3_palm_box_left",
             "v3_palm_box_right", "v3_center_box", "v3_center_lid",
             "v3_plate_left", "v3_plate_right", "v3_pod"]
    meshes = {p: load(p) for p in parts}

    print("[0] 7mmルール(数値): 井桁壁・座リブと全キーボード穴の距離")
    ok = True
    for px, py, d in HOLES:
        hx, hy = kb_xy(px, py)
        dists = [abs(hx - g) - V3_WALL / 2 for g in GRID_X] \
              + [abs(hy - g) - V3_WALL / 2 for g in GRID_Y] \
              + [hx - (V3_WALL + SEAT_W), hy - (V3_WALL + SEAT_W),
                 (KBW - V3_WALL - SEAT_W) - hx, (KBD - V3_WALL - SEAT_W) - hy]
        if min(dists) < 7.0:
            ok = False
            print(f"    違反: 穴({px},{py}) 最小距離{round(min(dists),2)}mm")
    check("全穴と井桁壁/座リブの距離 >= 7mm", ok)

    print("[1] 単一ボディ / watertight")
    for p, m in meshes.items():
        bodies = len(m.split(only_watertight=False))
        want = 2 if p == "v3_pod" else 1   # ポッドはトレイ+蓋の印刷プレート
        check(f"{p}: bodies={bodies}, watertight={m.is_watertight}",
              bodies == want and m.is_watertight)

    print("[2] 伏せ印刷パーツの耳が1層目に接地")
    for side, sgn in [("left", +1), ("right", -1)]:
        pm = meshes[f"v3_palm_box_{side}"]
        zmin = pm.bounds[0][2]
        a = math.radians(180 + sgn * TENT)
        ok = True
        for jx in PJ_XS:
            hit = False
            for dx in (-3.5, 3.5):  # ネジ穴(Φ3.4)の両脇
                xl, zl = sgn * (jx + dx), kb_top_z(jx + dx) - 0.1
                xr = xl * math.cos(a) + zl * math.sin(a)
                zr = -xl * math.sin(a) + zl * math.cos(a)
                if abs(zr - (zmin + 0.1)) < 0.2 and pm.contains([[xr, PJ_SCREW_Y, zr]])[0]:
                    hit = True
            ok = ok and hit
        check(f"palm_{side}: 耳3穴が1層目に存在", ok)
    cb = meshes["v3_center_box"]
    zmin = cb.bounds[0][2]
    ok = True
    for jy in CJ_YS:
        ax = seam(jy) + CJ_SCREW_IN * COS_S
        ay = -(jy + CJ_SCREW_IN * SIN_S)  # 印刷回転(rotate 180 x)でy反転
        hit = any(cb.contains([[ax + dx, ay, zmin + 0.1]])[0] for dx in (-2.5, 2.5))
        ok = ok and hit
    check("center_box: 耳(片側3穴)が1層目に存在", ok)

    print("[3] ネジ軸の素通し + 穴周囲の材料")
    kb_l = meshes["v3_kb_box_left"]
    kb_g = kb_l.copy()
    kb_g.apply_transform(place_left())
    cb_up = meshes["v3_center_box"].copy()
    cb_up.apply_transform(rot(180, [1, 0, 0]))
    for jy in CJ_YS:
        ax, ay = -(seam(jy) + CJ_SCREW_IN * COS_S), jy + CJ_SCREW_IN * SIN_S
        zs = np.arange(0.5, CBOX_H - 0.1, 0.5)
        axis = np.column_stack([np.full_like(zs, ax), np.full_like(zs, ay), zs])
        clear = kb_g.contains(axis).sum() == 0 and cb_up.contains(axis).sum() == 0
        ring = all(cb_up.contains([[ax + dx, ay + dy, CBOX_H - 1.5]])[0]
                   for dx, dy in [(2.5, 0), (-2.5, 0), (0, 3.5), (0, -3.5)])
        check(f"中央ジョイント jy={jy}: 軸素通し={clear}, 耳穴周囲={ring}", clear and ring)
    pm_l = meshes["v3_palm_box_left"].copy()
    pm_l.apply_transform(rot(-(180 + TENT), [0, 1, 0]))
    for jx in PJ_XS:
        zs = np.arange(1.0, kb_top_z(jx) + 3, 0.4)
        axis = np.column_stack([np.full_like(zs, jx), np.full_like(zs, PJ_SCREW_Y), zs])
        clear = kb_l.contains(axis).sum() == 0 and pm_l.contains(axis).sum() == 0
        ring = all(pm_l.contains([[jx + dx, PJ_SCREW_Y, kb_top_z(jx + dx) - 1.2]])[0]
                   for dx in (-3.5, 3.5))
        check(f"パームジョイント jx={jx}: 軸素通し={clear}, 耳穴周囲={ring}", clear and ring)

    print("[4] ナット位置(軸直下のスロット中心)が空洞")
    for jy in CJ_YS:
        jyl = KBD - (V3_CORNER[1] - jy) / COS_S
        z_nut = 13 - SLOT_CEIL - SLOT_T / 2
        check(f"中央 jy={jy}",
              not kb_l.contains([[KBW - CJ_SCREW_IN, jyl, z_nut]])[0])
    for jx in PJ_XS:
        z_nut = kb_top_z(jx) - PJ_TAB_T - SLOT_CEIL - SLOT_T / 2
        check(f"パーム jx={jx}",
              not kb_l.contains([[jx, PJ_SCREW_Y, z_nut]])[0])

    print("[5] プレート穴の7mmルール(メッシュ): 穴周囲・座面下に構造がない")
    ok = True
    bad = []
    for px, py, d in HOLES:
        hx, hy = kb_xy(px, py)
        seatz = kb_top_z(hx) - POCKET
        r = 3.5 if 2.35 <= d < 4 else 6.5   # BCはΦ8筒柱内のみ要求
        for ang in range(0, 360, 45):
            for dz in (1.5, 3.5):
                p = [hx + r * math.cos(math.radians(ang)),
                     hy + r * math.sin(math.radians(ang)), seatz - dz]
                if p[2] < 0.5:
                    continue
                if kb_l.contains([p])[0]:
                    ok = False
                    bad.append((round(px, 1), round(py, 1), ang, dz))
    check(f"ネジ頭・スペーサー逃げ(違反{len(bad)}点)", ok)

    print("[6] 干渉サンプリング")
    # プレートをkbローカルへ配置(斜面に沿わせる)
    pl = meshes["v3_plate_left"].copy()
    pl.apply_transform(rot(-TENT, [0, 1, 0]))
    z0 = kb_top_z(KB_WALL) - POCKET
    pl.apply_transform(trimesh.transformations.translation_matrix([KB_WALL, KB_WALL, z0]))
    rng = np.random.default_rng(11)
    for label, a, b, n in [("kb-中央(グローバル)", kb_g, cb_up, 40000),
                           ("kb-パーム(ローカル)", kb_l, pm_l, 40000),
                           ("kb-プレート(ローカル)", kb_l, pl, 40000)]:
        lo = np.maximum(a.bounds[0], b.bounds[0])
        hi = np.minimum(a.bounds[1], b.bounds[1])
        if np.any(hi <= lo):
            check(f"{label}: 重なり領域なし", True)
            continue
        pts = rng.uniform(lo, hi, (n, 3))
        ina = a.contains(pts)
        hits = int(b.contains(pts[ina]).sum()) if ina.any() else 0
        check(f"{label}: {hits}/{n}", hits == 0)

    print("[7] ポッドが細幅デッキに収まるか(数値)")
    pod_w_half, pod_n = 20.0, POD_Y + 47 + 4  # コア半幅 / 北壁ボス北端
    ok = pod_w_half <= seam(POD_Y + 47) - 0.2 and 19 <= seam(pod_n) - 0.2
    check(f"ポッド北端y={POD_Y+47}で半幅{round(seam(POD_Y+47)-0.2,1)}mm >= 20mm", ok)

    print()
    if FAILS:
        print(f"NG {len(FAILS)}件:")
        for f in FAILS:
            print("  -", f)
        sys.exit(1)
    print("全チェックOK")


if __name__ == "__main__":
    main()
