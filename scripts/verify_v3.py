#!/usr/bin/env python3
"""v3 STLの設計検証: make v3 のあとに `make check` で実行する。

必要: pip install trimesh numpy

チェック内容(過去に実際に起きた設計ミスに対応):
  1. 各パーツが単一ボディ・watertight であること
  2. 伏せ印刷パーツ(パーム/中央箱)のジョイントタブが印刷1層目に接地していること
     (タブ上面を天板から0.2mm下げただけでベッドから浮き、印刷不良になった)
  3. ジョイントのネジ軸12本が両部品を素通しできること(軸上に材料がない)
     + 穴の周囲4点に材料があること(穴位置の座標変換ミスで逆側に開いたことがある)
  4. ナット挿入スロットの中心(=ネジ軸直下)が空洞であること
     (スロット奥行き不足でナットが軸下に届かなかったことがある)
  5. KB⇔中央 / KB⇔パーム の干渉サンプリングが0であること
     (傾斜タブ vs 水平切り欠き床で0.9mm食い込んだことがある)

注意: テスト点をネジ穴の軸上に置くと「材料なし」と誤判定するので、
材料の存在確認は必ず穴からオフセットした点で行うこと。
"""
import math
import sys

import numpy as np
import trimesh

# ---- scad/params.scad と一致させること ----
PLATE_W, PLATE_D = 142.99, 113.53
KBW, KBD = PLATE_W + 12, PLATE_D + 12
SPLAY, TENT = 10.0, 7.0
WEDGE_T0 = 6.0
KB_CORNER = (45.0, 238.0)
CJ_YS = [120, 170, 220]          # v3_cj_ys (グローバルy)
CJ_SCREW_IN = 6.0                # 東壁面からネジ軸までの距離(kbローカル)
PJ_XS = [30, 60, 88]             # v3_pj_xs (kbローカルx)
PJ_SCREW_Y = 4.5                 # 南壁面からネジ軸までの距離
CBOX_H = 16.0
SLOT_T, SLOT_CEIL = 2.7, 2.5

TAN_T = math.tan(math.radians(TENT))
COS_S, SIN_S = math.cos(math.radians(SPLAY)), math.sin(math.radians(SPLAY))


def seam_x(y):
    return KB_CORNER[0] + (KB_CORNER[1] - y) * math.tan(math.radians(SPLAY))


def kb_top_z(x):
    return WEDGE_T0 + x * TAN_T


def load(name):
    return trimesh.load(f"stl/{name}.stl")


def rot(deg, axis):
    return trimesh.transformations.rotation_matrix(math.radians(deg), axis)


def place_left():
    """kbローカル → グローバル(左)。scad/side.scad の place_left と同じ"""
    t1 = trimesh.transformations.translation_matrix([-KBW, -KBD, 0])
    t2 = trimesh.transformations.translation_matrix([-KB_CORNER[0], KB_CORNER[1], 0])
    return t2 @ rot(-SPLAY, [0, 0, 1]) @ t1


FAILS = []


def check(label, ok):
    print(("  OK  " if ok else "  NG  ") + label)
    if not ok:
        FAILS.append(label)


def main():
    parts = ["v3_kb_box_left", "v3_kb_box_right", "v3_palm_box_left",
             "v3_palm_box_right", "v3_center_box", "v3_center_lid"]
    meshes = {p: load(p) for p in parts}

    print("[1] 単一ボディ / watertight")
    for p, m in meshes.items():
        bodies = len(m.split(only_watertight=False))
        check(f"{p}: bodies={bodies}, watertight={m.is_watertight}",
              bodies == 1 and m.is_watertight)

    print("[2] 伏せ印刷パーツのタブが1層目に接地")
    for side, sgn in [("left", +1), ("right", -1)]:
        pm = meshes[f"v3_palm_box_{side}"]
        zmin = pm.bounds[0][2]
        a = math.radians(180 + sgn * TENT)
        ok = True
        for jx in PJ_XS:
            hit = False
            for dx in (-4.5, 4.5):  # ネジ穴(Φ3.4)の両脇
                xl, zl = sgn * (jx + dx), kb_top_z(jx + dx) - 0.1
                xr = xl * math.cos(a) + zl * math.sin(a)
                zr = -xl * math.sin(a) + zl * math.cos(a)
                if abs(zr - (zmin + 0.1)) < 0.2 and pm.contains([[xr, PJ_SCREW_Y, zr]])[0]:
                    hit = True
            ok = ok and hit
        check(f"palm_{side}: タブ3箇所が1層目に存在", ok)
    cb = meshes["v3_center_box"]  # rotate([180,0,0]) 済み: タブ(デッキ面一)が zmin にあるか
    zmin = cb.bounds[0][2]
    ok = True
    for jy in CJ_YS:
        ax = seam_x(jy) + CJ_SCREW_IN * COS_S  # 左タブのx(回転後は+x側)
        ay = -(jy + CJ_SCREW_IN * SIN_S)       # 回転でy反転
        hit = any(cb.contains([[ax + dx, ay, zmin + 0.1]])[0] for dx in (-2.5, 2.5))
        ok = ok and hit
    check("center_box: タブ(片側3箇所)が1層目に存在", ok)

    print("[3] ネジ軸の素通し + 穴周囲の材料")
    kb_l = meshes["v3_kb_box_left"]
    kb_g = kb_l.copy()
    kb_g.apply_transform(place_left())
    cb_up = meshes["v3_center_box"].copy()
    cb_up.apply_transform(rot(180, [1, 0, 0]))  # 印刷回転を戻す
    for jy in CJ_YS:
        ax, ay = -(seam_x(jy) + CJ_SCREW_IN * COS_S), jy + CJ_SCREW_IN * SIN_S
        zs = np.arange(0.5, CBOX_H - 0.1, 0.5)
        axis = np.column_stack([np.full_like(zs, ax), np.full_like(zs, ay), zs])
        clear = kb_g.contains(axis).sum() == 0 and cb_up.contains(axis).sum() == 0
        ring = all(cb_up.contains([[ax + dx, ay + dy, CBOX_H - 1.5]])[0]
                   for dx, dy in [(2.5, 0), (-2.5, 0), (0, 3.5), (0, -3.5)])
        check(f"中央ジョイント jy={jy}: 軸素通し={clear}, タブ穴周囲={ring}", clear and ring)
    pm_l = meshes["v3_palm_box_left"].copy()
    pm_l.apply_transform(rot(-(180 + TENT), [0, 1, 0]))  # 印刷回転を戻す(kbローカル)
    for jx in PJ_XS:
        zs = np.arange(1.0, kb_top_z(jx) + 3, 0.4)
        axis = np.column_stack([np.full_like(zs, jx), np.full_like(zs, PJ_SCREW_Y), zs])
        clear = kb_l.contains(axis).sum() == 0 and pm_l.contains(axis).sum() == 0
        ring = all(pm_l.contains([[jx + dx, PJ_SCREW_Y, kb_top_z(jx + dx) - 1.6]])[0]
                   for dx in (-4.5, 4.5))
        check(f"パームジョイント jx={jx}: 軸素通し={clear}, タブ穴周囲={ring}", clear and ring)

    print("[4] ナット位置(軸直下のスロット中心)が空洞")
    for jy in CJ_YS:  # kbローカルで確認
        jyl = KBD - (KB_CORNER[1] - jy) / COS_S
        z_nut = 13 - SLOT_CEIL - SLOT_T / 2
        check(f"中央 jy={jy}: ",
              not kb_l.contains([[KBW - CJ_SCREW_IN, jyl, z_nut]])[0])
    for jx in PJ_XS:
        nf = kb_top_z(jx) - 3.2
        check(f"パーム jx={jx}: ",
              not kb_l.contains([[jx, PJ_SCREW_Y, nf - SLOT_CEIL - SLOT_T / 2]])[0])

    print("[5] 干渉サンプリング")
    rng = np.random.default_rng(11)
    for label, a, b in [("kb-中央", kb_g, cb_up), ("kb-パーム", kb_l, pm_l)]:
        lo = np.maximum(a.bounds[0], b.bounds[0])
        hi = np.minimum(a.bounds[1], b.bounds[1])
        pts = rng.uniform(lo, hi, (40000, 3))
        ina = a.contains(pts)
        hits = int(b.contains(pts[ina]).sum()) if ina.any() else 0
        check(f"{label}: {hits}/40000", hits == 0)

    print()
    if FAILS:
        print(f"NG {len(FAILS)}件:")
        for f in FAILS:
            print("  -", f)
        sys.exit(1)
    print("全チェックOK")


if __name__ == "__main__":
    main()
