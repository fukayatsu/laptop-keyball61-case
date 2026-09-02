#!/usr/bin/env python3
"""Touch ID プレート + 十字フットの設計検証: `make check-touchid` で実行する。
依存なし(標準ライブラリのみ)。

寸法は scad/touchid/touchid_params.scad から読み、外形は生成されたSTLから直接
拾うので、パラメータを変えたら再実行するだけでよい。

チェック:
  - 両パーツが閉じている(全エッジが2三角形で共有)
  - プレート: 底面が完全平面(ベタ置き印刷) / 外形寸法 / ネジ穴が上下とも公称径で貫通
  - プレート: 天面ボスが残っている
  - フット: 上下フラットな角柱 / スリバー(ゼロ幅)なし
  - フット: 裏に出るネジ頭を逃げている(穴中心から head_d/2 + clr)
  - フット: プレート外形からはみ出していない
  - ネジ頭の座面幅が正か
"""
import ast
import collections
import math
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCAD = ROOT / "scad" / "touchid"
STL = ROOT / "stl"
TOL = 1e-3

FAILS = []
WARNS = []


def check(ok, msg):
    print(("  OK   " if ok else "  FAIL ") + msg)
    if not ok:
        FAILS.append(msg)


def warn(ok, msg):
    if not ok:
        print("  WARN " + msg)
        WARNS.append(msg)


def scad_vars(*names):
    """touchid_params.scad からリテラル代入を拾う。"""
    src = (SCAD / "touchid_params.scad").read_text()
    src = re.sub(r"//.*", "", src)
    out = {}
    for m in re.finditer(r"(\w+)\s*=\s*([^;]+);", src, re.S):
        try:
            out[m.group(1)] = ast.literal_eval(m.group(2).strip().rstrip(","))
        except (ValueError, SyntaxError):
            pass
    missing = [n for n in names if n not in out]
    if missing:
        sys.exit(f"scadからパラメータを読めなかった: {missing}")
    return out


def read_stl(path):
    txt = path.read_text()
    vs = [tuple(round(float(x), 4) for x in l.split()[1:4])
          for l in txt.splitlines() if "vertex" in l]
    return [tuple(vs[i:i + 3]) for i in range(0, len(vs), 3)]


def closed(tris):
    e = collections.Counter()
    for t in tris:
        for a, b in ((0, 1), (1, 2), (2, 0)):
            e[tuple(sorted((t[a], t[b])))] += 1
    return [k for k, c in e.items() if c != 2]


def face_loops(tris, z):
    flat = [tuple(v[:2] for v in t) for t in tris
            if all(abs(v[2] - z) < TOL for v in t)]
    e = collections.Counter()
    for t in flat:
        for a, b in ((0, 1), (1, 2), (2, 0)):
            e[tuple(sorted((t[a], t[b])))] += 1
    adj = collections.defaultdict(list)
    for a, b in (k for k, c in e.items() if c == 1):
        adj[a].append(b)
        adj[b].append(a)
    loops, seen = [], set()
    for st in sorted(adj):
        if st in seen:
            continue
        lp, cur, prev = [st], st, None
        seen.add(st)
        while True:
            nx = [p for p in adj[cur] if p != prev and p not in seen]
            if not nx:
                break
            prev, cur = cur, nx[0]
            seen.add(cur)
            lp.append(cur)
        loops.append(lp)
    return sorted(loops, key=len, reverse=True), flat


def tri_area(t):
    (x1, y1), (x2, y2), (x3, y3) = t
    return abs((x2 - x1) * (y3 - y1) - (x3 - x1) * (y2 - y1)) / 2


def seg_dist(p, a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    L = dx * dx + dy * dy
    t = 0.0 if L == 0 else max(0.0, min(1.0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / L))
    return math.hypot(p[0] - (a[0] + t * dx), p[1] - (a[1] + t * dy))


def poly_dist(p, poly):
    return min(seg_dist(p, poly[i], poly[(i + 1) % len(poly)]) for i in range(len(poly)))


def inside(p, poly):
    c = False
    for i in range(len(poly)):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % len(poly)]
        if (y1 > p[1]) != (y2 > p[1]) and p[0] < x1 + (p[1] - y1) * (x2 - x1) / (y2 - y1):
            c = not c
    return c


def poly_area(lp):
    return abs(sum(lp[i][0] * lp[(i + 1) % len(lp)][1] - lp[(i + 1) % len(lp)][0] * lp[i][1]
                   for i in range(len(lp)))) / 2


def circle_dia(lp):
    xs, ys = [p[0] for p in lp], [p[1] for p in lp]
    c = ((min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2)
    return c, 2 * sum(math.dist(p, c) for p in lp) / len(lp)


def main():
    V = scad_vars("touchid_plate_w", "touchid_plate_d", "touchid_plate_t",
                  "touchid_boss_d", "touchid_boss_h", "touchid_hole_x",
                  "touchid_hole_y", "touchid_hole_d", "touchid_head_d",
                  "touchid_foot_h", "touchid_foot_head_clr", "touchid_foot_xbar")
    head_r = V["touchid_head_d"] / 2 + V["touchid_foot_head_clr"]
    holes = [(x, y) for y in V["touchid_hole_y"] for x in V["touchid_hole_x"]]

    for name in ("touchid_plate", "touchid_foot"):
        if not (STL / f"{name}.stl").exists():
            sys.exit(f"{name}.stl がない。先に `make touchid` を実行すること")

    # ---------- プレート ----------
    print("touchid_plate.stl")
    pt = read_stl(STL / "touchid_plate.stl")
    bad = closed(pt)
    check(not bad, f"閉じたソリッド (開いたエッジ {len(bad)})")

    zs = sorted({v[2] for t in pt for v in t})
    check(zs == [0.0, V["touchid_plate_t"],
                 round(V["touchid_plate_t"] + V["touchid_boss_h"], 4)],
          f"Z平面が 底面/天面/ボス頂面の3枚 {zs}")

    xs = [v[0] for t in pt for v in t]
    ys = [v[1] for t in pt for v in t]
    check(abs(max(xs) - min(xs) - V["touchid_plate_w"]) < 0.01
          and abs(max(ys) - min(ys) - V["touchid_plate_d"]) < 0.01,
          f"外形 {max(xs)-min(xs):.2f} x {max(ys)-min(ys):.2f} mm")

    # 底面はベタ置き面。外形と同じ輪郭 - ネジ穴4つ の1枚でなければならない
    loops0, flat0 = face_loops(pt, 0.0)
    check(len(loops0) == 5, f"底面が平面1枚 + ネジ穴4つ (ループ {len(loops0)})")
    outline = max(loops0, key=poly_area)   # 以降のはみ出し判定はこの実物外形を使う
    a0 = sum(tri_area(t) for t in flat0)
    check(a0 > 200, f"底面のベッド接地面積 {a0:.1f} mm2")

    # ループは点数順に並ぶ(穴の分割数 > 外形の点数)ので、中心一致で穴を特定する
    for z in (0.0, V["touchid_plate_t"]):
        loops, _ = face_loops(pt, z)
        rings = [circle_dia(lp) for lp in loops]
        dias, ok = [], True
        for hc in holes:
            c, d = min(rings, key=lambda cd: math.dist(cd[0], hc))
            dias.append(d)
            if math.dist(c, hc) > 0.02 or abs(d - V["touchid_hole_d"]) > 0.01:
                ok = False
        check(ok, f"z={z} のネジ穴4つが φ{V['touchid_hole_d']} で貫通 "
                  f"({', '.join(f'{d:.3f}' for d in dias)})")

    loopsb, _ = face_loops(pt, round(V["touchid_plate_t"] + V["touchid_boss_h"], 4))
    check(len(loopsb) == 1 and abs(circle_dia(loopsb[0])[1] - V["touchid_boss_d"]) < 0.02,
          f"天面ボス φ{V['touchid_boss_d']} x {V['touchid_boss_h']} が残っている")

    bearing = (V["touchid_head_d"] - V["touchid_hole_d"]) / 2
    check(bearing > 0,
          f"ネジ頭の座面幅 片側 {bearing:.3f} mm (頭φ{V['touchid_head_d']} / "
          f"穴φ{V['touchid_hole_d']})")
    warn(bearing >= 0.15,
         f"座面幅 {bearing:.3f} mm は薄い。印刷で穴が細く出る前提の指定か要確認")

    # ---------- 十字フット ----------
    print("touchid_foot.stl")
    ft = read_stl(STL / "touchid_foot.stl")
    bad = closed(ft)
    check(not bad, f"閉じたソリッド (開いたエッジ {len(bad)})")

    fzs = sorted({v[2] for t in ft for v in t})
    check(fzs == [0.0, V["touchid_foot_h"]],
          f"上下フラットな角柱 (Z平面 {fzs})")

    loopsf, flatf = face_loops(ft, 0.0)
    check(len(loopsf) == 1, f"穴のない単一輪郭 (ループ {len(loopsf)})")
    foot = loopsf[0]

    shortest = min(math.dist(foot[i], foot[(i + 1) % len(foot)])
                   for i in range(len(foot)))
    check(shortest > 0.005, f"スリバーなし (最短エッジ {shortest:.4f} mm)")

    for h in holes:
        d = poly_dist(h, foot)
        check(d >= head_r - 0.01 and not inside(h, foot),
              f"穴{h} の頭逃げ {d:.3f} mm >= {head_r:.3f} "
              f"(頭φ{V['touchid_head_d']} の外周から {d - V['touchid_head_d']/2:.3f} mm)")

    over = max((poly_dist(p, outline) for p in foot if not inside(p, outline)),
               default=0.0)
    check(over < 0.01, f"プレート外形からのはみ出し {over:.4f} mm")

    fx = [p[0] for p in foot]
    fy = [p[1] for p in foot]
    span = min(max(fx) - min(fx), max(fy) - min(fy))
    xbar = V["touchid_foot_xbar"]
    bar_span = min(xbar[0][1] - xbar[0][0], 2 * xbar[1])
    check(span > bar_span,
          f"支持スパン(短辺) {span:.2f} mm > X方向バー単体 {bar_span:.2f} mm")

    print()
    if FAILS:
        print(f"NG: {len(FAILS)} 件")
        for f in FAILS:
            print("  - " + f)
        sys.exit(1)
    print(f"OK: 全チェック通過" + (f" (警告 {len(WARNS)} 件)" if WARNS else ""))


if __name__ == "__main__":
    main()
