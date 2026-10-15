#!/usr/bin/env python3
"""v4 STLの設計検証: make v4 のあとに `make check-v4` で実行する。
必要: pip install trimesh numpy rtree networkx

チェック: 単一ボディ/watertight・平面性(ベタ置き印刷)・ジョイント軸の素通し+穴周囲の材料・
ナット位置の空洞・ボトムプレート/上部カバーの取付ネジ・ネジ頭の逃げと接地・
部品間干渉・Touch ID基板/TRSプラグの空間・印刷オーバーハング。
注意: 材料存在のテスト点はネジ穴軸上に置かない(誤判定する)。
座標: 「プレート座標」= 左プレートの(sx, sy, z=プレート下面から法線方向)。
"""
import math
import os
import subprocess
import sys
import tempfile

import numpy as np
import trimesh

PLATE_W, PLATE_D = 142.99, 113.53
KBW, KBD = PLATE_W + 12, PLATE_D + 12
SPLAY, TENT = 10.0, 7.0
V4_CORNER = (10.0, 238.0)
CJ_YS = [120, 170, 220]
PT, FIT, SPINE_Z0 = 2.0, 0.15, 13.5
BP_T, BP_BOSS_H = 2.0, 6.2
BP_EARS = [[40, 113], [110, 119.5], [34, 8.5], [118, 8.5], [146, 47], [146, 100]]
TC_COLS = [[149.5, 35], [149.5, 80], [149.5, 113]]
TC_NUT_D, TC_NUT_AF = 2.6, 5.6
TC_JACK_Y, TC_JACK_H, TC_PLUG_D = 64.7, 11.0, 11.0
TID = (31.0, 85.0, 3.0)
TID_Y0 = 146.0
M3_LEN, M3_HEAD_D, M3_HEAD_H, NUT_T = 8.0, 5.5, 2.4, 2.4

TAN_T = math.tan(math.radians(TENT))
COS_T, SIN_T = math.cos(math.radians(TENT)), math.sin(math.radians(TENT))
COS_S, SIN_S = math.cos(math.radians(SPLAY)), math.sin(math.radians(SPLAY))


def scad_value(expr):
    """v4_params.scad の導出値をOpenSCADから取得する"""
    with tempfile.TemporaryDirectory() as d:
        out = os.path.join(d, "v.echo")
        subprocess.run([os.environ.get("OPENSCAD", "openscad"), "-o", out,
                        "-D", f"echo(v={expr});", "scad/v4/v4_params.scad"],
                       capture_output=True, check=True)
        for line in open(out):
            if line.startswith("ECHO: v = "):
                return float(line.split("=")[1])
    raise RuntimeError(f"OpenSCADから {expr} を取得できない")


def seam(y):
    return V4_CORNER[0] + (V4_CORNER[1] - y) * math.tan(math.radians(SPLAY))


def rot(deg, axis):
    return trimesh.transformations.rotation_matrix(math.radians(deg), axis)


def tr(v):
    return trimesh.transformations.translation_matrix(v)


MIRROR_X = trimesh.transformations.reflection_matrix([0, 0, 0], [1, 0, 0])


def place_left():
    return tr([-V4_CORNER[0], V4_CORNER[1], 0]) @ rot(-SPLAY, [0, 0, 1]) @ tr([-KBW, -KBD, 0])


PLATE_FRAME = place_left() @ rot(-TENT, [0, 1, 0])   # プレート座標 -> グローバル(左)


def pf(pts):
    """プレート座標の点列 -> グローバル(左)"""
    pts = np.atleast_2d(np.asarray(pts, dtype=float))
    return trimesh.transform_points(pts, PLATE_FRAME)


def circle_pts(cx, cy, r, z, n=8):
    return [[cx + r * math.cos(2 * math.pi * k / n), cy + r * math.sin(2 * math.pi * k / n), z]
            for k in range(n)]


FAILS = []


def check(label, ok):
    print(("  OK  " if ok else "  NG  ") + label)
    if not ok:
        FAILS.append(label)


def interference(a, b, rng, n=40000):
    lo = np.maximum(a.bounds[0], b.bounds[0])
    hi = np.minimum(a.bounds[1], b.bounds[1])
    if not np.all(hi > lo):
        return 0
    pts = rng.uniform(lo, hi, (n, 3))
    ina = a.contains(pts)
    return int(b.contains(pts[ina]).sum()) if ina.any() else 0


def main():
    top_z = scad_value("v4tc_top_z")
    pl = trimesh.load("stl/v4_plate_left.stl")
    pr = trimesh.load("stl/v4_plate_right.stl")
    bl = trimesh.load("stl/v4_bottom_plate_left.stl")
    br = trimesh.load("stl/v4_bottom_plate_right.stl")
    cb = trimesh.load("stl/v4_center_spine.stl")
    tc = trimesh.load("stl/v4_top_cover.stl")

    print("[1] 単一ボディ / watertight / 平面性")
    for name, m in [("plate_left", pl), ("plate_right", pr), ("bottom_plate_left", bl),
                    ("bottom_plate_right", br), ("center_spine", cb), ("top_cover", tc)]:
        bodies = len(m.split(only_watertight=False))
        check(f"{name}: bodies={bodies}, watertight={m.is_watertight}",
              bodies == 1 and m.is_watertight)
    for name, m in [("plate_left", pl), ("plate_right", pr)]:
        check(f"{name}: 下面フラット(zmin={round(m.bounds[0][2],3)}, "
              f"z範囲{round(m.bounds[1][2],1)})",
              abs(m.bounds[0][2]) < 0.01 and m.bounds[1][2] < 9)
    for name, m in [("bottom_plate_left", bl), ("bottom_plate_right", br)]:
        check(f"{name}: 下面フラット(zmin={round(m.bounds[0][2],3)}, "
              f"zmax={round(m.bounds[1][2],2)}=耳ボス)",
              abs(m.bounds[0][2]) < 0.01 and abs(m.bounds[1][2] - BP_BOSS_H) < 0.01)
    check(f"center_spine(印刷向き): 底面フラット接地(zmin={round(cb.bounds[0][2],3)})",
          abs(cb.bounds[0][2]) < 0.01)
    check(f"top_cover(印刷向き=伏せ): 天面フラット接地(zmin={round(tc.bounds[0][2],3)})",
          abs(tc.bounds[0][2]) < 0.01)

    # グローバル配置
    plg = pl.copy()
    plg.apply_transform(PLATE_FRAME)
    prg = pr.copy()
    prg.apply_transform(MIRROR_X @ PLATE_FRAME @ MIRROR_X)
    blg = bl.copy()
    blg.apply_transform(PLATE_FRAME @ tr([0, 0, PT]))
    brg = br.copy()
    brg.apply_transform(MIRROR_X @ PLATE_FRAME @ tr([0, 0, PT]) @ MIRROR_X)
    cbg = cb.copy()
    cbg.apply_transform(tr([0, 0, SPINE_Z0]))  # 印刷並進を戻す
    tcg = tc.copy()
    tcg.apply_transform(rot(180, [1, 0, 0]) @ tr([0, 0, -top_z]))  # 伏せ印刷を戻す

    print("[2] ジョイント軸の素通し + 穴周囲の材料 (左側)")
    n = np.array([-SIN_T * COS_S, SIN_T * SIN_S, COS_T])  # 左プレート法線
    for jy in CJ_YS:
        p0 = np.array([-(seam(jy) - 6 * COS_S), jy - 6 * SIN_S, 0])
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

    print("[3] 印刷オーバーハング")
    # スパイン: 許容は六角ナットポケットの天井6箇所(約1.2cm2)のみ
    fn, fz = cb.face_normals, cb.triangles_center[:, 2]
    over_area = cb.area_faces[(fn[:, 2] < -0.75) & (fz > 0.5)].sum() / 100
    check(f"スパイン: 41°超の下向き面 {round(over_area,2)}cm2 (< 2cm2)", over_area < 2)
    # 上部カバー(伏せ): ナットポケットは上に開き、USB-C窓は下辺を45°に尖らせてブリッジなし
    fn, fz = tc.face_normals, tc.triangles_center[:, 2]
    over = (fn[:, 2] < -0.75) & (fz > 0.5)
    over_area = tc.area_faces[over].sum() / 100
    check(f"上部カバー: 41°超の下向き面 {round(over_area,2)}cm2 (< 1.5cm2)", over_area < 1.5)
    # 個々のブリッジ幅: 下向き面の連結成分ごとに、向きを合わせた外接矩形の短辺と
    # 平均幅(面積/長辺)の小さい方(部品は10°回転しているので軸平行の外接矩形は不可)
    spans = []
    parts = (tc.submesh([np.where(over)[0]], append=True).split(only_watertight=False)
             if over.any() else [])
    for p in parts:
        if p.area < 0.5:
            continue
        _, ext = trimesh.bounds.oriented_bounds_2D(p.vertices[:, :2])
        spans.append(min(min(ext), p.area / max(ext)))
    check(f"上部カバー: 最大ブリッジ幅 {round(max(spans, default=0), 1)}mm (<= 4mm, {len(spans)}箇所)",
          max(spans, default=0) <= 4)

    def head_checks(label, sx, sy):
        """下から入れるM3なべの頭: スパインに当たらず、接地(z=0)より上にあること"""
        head = pf([p for z in (-0.3, -1.2, -M3_HEAD_H) for p in
                   circle_pts(sx, sy, M3_HEAD_D / 2 + 0.3, z) + [[sx, sy, z]]])
        hit = int(cbg.contains(head).sum())
        zmin = float(head[:, 2].min())
        return hit == 0 and zmin > 1.0, f"頭⇔スパイン干渉={hit}, 頭の最下点z={round(zmin,1)}"

    print("[4] ボトムプレートの取付ネジ (左側, 左右プレートの下からM3x8なべ)")
    for sx, sy in BP_EARS:
        zs = np.arange(-0.5, PT + BP_BOSS_H + 0.5, 0.25)
        axis = pf([[sx, sy, z] for z in zs])
        clear = plg.contains(axis).sum() == 0 and blg.contains(axis).sum() == 0
        ring_plate = all(plg.contains(pf(circle_pts(sx, sy, 2.6, 1.0))))
        floor = all(blg.contains(pf(circle_pts(sx, sy, 2.4, PT + 1.0))))
        nut_void = not any(blg.contains(pf(circle_pts(sx, sy, 2.5, PT + BP_T + 1.2))))
        wall = all(blg.contains(pf(circle_pts(sx, sy, 4.0, PT + BP_T + 1.2))))
        tip = M3_LEN                                   # ネジ先端(プレート座標z)
        nut_top = PT + BP_T + NUT_T
        tip_ok = tip - nut_top >= 0.8 and tip <= PT + BP_BOSS_H
        ok_h, msg_h = head_checks("", sx, sy)
        check(f"({sx},{sy}): 軸素通し={clear}, プレート穴周囲={ring_plate}, 井戸床={floor}, "
              f"ナット空洞={nut_void}, 井戸壁={wall}, 掛かり余裕={round(tip-nut_top,2)}mm "
              f"先端がボス内={tip <= PT + BP_BOSS_H}, {msg_h}",
              clear and ring_plate and floor and nut_void and wall and tip_ok and ok_h)

    print("[5] 上部カバーの取付ネジ (左側, 左右プレートの下からM3x8なべ→柱下端の圧入ナット)")
    for sx, sy in TC_COLS:
        zs = np.arange(-0.5, PT + 7.0, 0.25)
        axis = pf([[sx, sy, z] for z in zs])
        clear = plg.contains(axis).sum() == 0 and tcg.contains(axis).sum() == 0
        ring_plate = all(plg.contains(pf(circle_pts(sx, sy, 2.6, 1.0))))
        # ポケット: ナット外接円(対辺/cos30)の内側が空洞、その外に壁、上に天井
        rn = TC_NUT_AF / 2 - 0.1
        pocket = not any(tcg.contains(pf(circle_pts(sx, sy, rn, PT + TC_NUT_D / 2))))
        wall = all(tcg.contains(pf(circle_pts(sx, sy, TC_NUT_AF / np.sqrt(3) + 0.5,
                                               PT + TC_NUT_D / 2))))
        ceil = all(tcg.contains(pf(circle_pts(sx, sy, 2.5, PT + TC_NUT_D + 0.5))))
        nut_top = PT + TC_NUT_D
        tip_ok = M3_LEN - nut_top >= 0.8
        ok_h, msg_h = head_checks("", sx, sy)
        check(f"({sx},{sy}): 軸素通し={clear}, プレート穴周囲={ring_plate}, ポケット空洞={pocket}, "
              f"ポケット壁={wall}, ポケット天井={ceil}, "
              f"掛かり余裕={round(M3_LEN-nut_top,2)}mm, {msg_h}",
              clear and ring_plate and pocket and wall and ceil and tip_ok and ok_h)

    print("[6] 干渉サンプリング")
    rng = np.random.default_rng(7)
    for la, a, lb, b in [("プレート", plg, "スパイン", cbg),
                         ("ボトムプレート", blg, "プレート", plg),
                         ("ボトムプレート", blg, "スパイン", cbg),
                         ("上部カバー", tcg, "プレート(左)", plg),
                         ("上部カバー", tcg, "プレート(右)", prg),
                         ("上部カバー", tcg, "ボトムプレート(左)", blg),
                         ("上部カバー", tcg, "ボトムプレート(右)", brg),
                         ("上部カバー", tcg, "スパイン", cbg)]:
        hits = interference(a, b, rng)
        check(f"{la}⇔{lb}: {hits}/40000", hits == 0)
    gap = prg.bounds[0][0] - plg.bounds[1][0]
    check(f"左右プレート間の隙間(中心線): {round(gap,2)}mm (>0)", gap > 0)

    print("[7] 上部カバーの載り方と内部空間")
    # 壁の下端(グローバルzが低い頂点)が全て左右プレートかスパインの上にある
    vs = tcg.vertices
    low = vs[vs[:, 2] < np.percentile(vs[:, 2], 30)]
    down = np.tile([0, 0, -1.0], (len(low), 1))
    under = (plg.convex_hull.ray.intersects_any(low, down)
             | prg.convex_hull.ray.intersects_any(low, down)
             | cbg.convex_hull.ray.intersects_any(low, down))
    check(f"カバー下端がプレート/スパインの上に載る: {int((~under).sum())}/{len(low)}点はみ出し",
          under.all())
    # Touch ID基板85x31x3が天板裏に貼れる(柱の斜面・壁・相手部品と干渉しない)
    zt = top_z - 2.0
    gx, gy, gz = np.meshgrid(np.linspace(-TID[0] / 2, TID[0] / 2, 9),
                             np.linspace(TID_Y0, TID_Y0 + TID[1], 35),
                             [zt - 0.1, zt - TID[2] / 2, zt - TID[2] - 0.5])
    pts = np.column_stack([gx.ravel(), gy.ravel(), gz.ravel()])
    hits = sum(int(m.contains(pts).sum()) for m in (tcg, plg, prg, blg, brg, cbg))
    check(f"Touch ID基板 {TID[1]:.0f}x{TID[0]:.0f}(y{TID_Y0:.0f}..{TID_Y0+TID[1]:.0f}) の空間: "
          f"干渉{hits}点", hits == 0)
    # TRSプラグ(L型)の頭: ジャック前から東へ13mm、軸=ボトムプレート上面+jack_h
    zc = PT + BP_T + TC_JACK_H
    plug = pf([[sx, TC_JACK_Y + r * math.cos(a), zc + r * math.sin(a)]
               for sx in np.arange(140.5, 153.5, 1.0)
               for r in (0, TC_PLUG_D / 2 * 0.5, TC_PLUG_D / 2)
               for a in np.linspace(0, 2 * math.pi, 12, endpoint=False)])
    hits = sum(int(m.contains(plug).sum()) for m in (tcg, plg, blg))
    check(f"TRSプラグ頭(Φ{TC_PLUG_D:.0f}, 軸高さ{TC_JACK_H:.0f})の通り道: 干渉{hits}点", hits == 0)
    check(f"上部カバー天面 z={round(top_z,1)} (参考: 左右プレート稜線付近 z≈"
          f"{round((KBW + 12) * TAN_T + PT, 1)})", True)

    print()
    if FAILS:
        print(f"NG {len(FAILS)}件:")
        for f in FAILS:
            print("  -", f)
        sys.exit(1)
    print("全チェックOK")


if __name__ == "__main__":
    main()
