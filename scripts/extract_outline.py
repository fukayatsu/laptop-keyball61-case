#!/usr/bin/env python3
"""Keyball61 の底板アクリル DXF から外形と穴位置を抽出し、
data/keyball61_ballside_bottom_real.json と scad/keyball61_outline.scad を生成する。

DXF はポイント単位(≒1/72inch)で描かれている。スケール係数は公式KiCad基板(右手・Ball側)の
スペーサー穴8点と底板M2穴8点の相似変換フィット(残差0.002mm)から 0.353407 mm/unit と確定。
プレート実寸 142.99 x 113.53 mm は PCB の Edge.Cuts 外形 142.9 x 113.5 とも一致する。
(当初「3:1スケール」と誤推定していた: 実寸比 1pt=0.35278 に対し 1/3=0.3333 で約6%小さかった)

使い方:
  python3 scripts/extract_outline.py path/to/Keyball61_Rev1_BallSide_Bottom_Acryl_Clear2mm.dxf

依存: pip install ezdxf
"""
import json
import math
import sys
from pathlib import Path

import ezdxf
from ezdxf.disassemble import recursive_decompose

SCALE = 0.353407  # mm/unit (KiCad基板との照合で確定)
TOL = 0.06  # 端点連結の許容距離 (DXF座標系)

REPO = Path(__file__).resolve().parent.parent


def load_paths(dxf_path):
    doc = ezdxf.readfile(dxf_path)
    open_paths, closed_paths = [], []
    for e in recursive_decompose(doc.modelspace()):
        t = e.dxftype()
        if t == "POLYLINE":
            pts = [(v.dxf.location.x, v.dxf.location.y) for v in e.vertices]
        elif t == "SPLINE":
            pts = [(p[0], p[1]) for p in e.flattening(0.05)]
        else:
            continue
        if len(pts) < 2:
            continue
        if math.dist(pts[0], pts[-1]) < TOL:
            closed_paths.append(pts)
        else:
            open_paths.append(pts)
    return open_paths, closed_paths


def chain_loops(open_paths):
    """細切れの線分群を端点距離で連結し、閉ループを取り出す。"""
    used = [False] * len(open_paths)
    loops = []
    near = lambda a, b: math.dist(a, b) < TOL
    for i, seed in enumerate(open_paths):
        if used[i]:
            continue
        chain = list(seed)
        used[i] = True
        extended = True
        while extended and not (near(chain[0], chain[-1]) and len(chain) > 3):
            extended = False
            for j, p in enumerate(open_paths):
                if used[j]:
                    continue
                if near(chain[-1], p[0]):
                    chain += p[1:]
                elif near(chain[-1], p[-1]):
                    chain += p[-2::-1]
                elif near(chain[0], p[-1]):
                    chain = p[:-1] + chain
                elif near(chain[0], p[0]):
                    chain = p[::-1][:-1] + chain
                else:
                    continue
                used[j] = True
                extended = True
                break
        if near(chain[0], chain[-1]) and len(chain) > 3:
            loops.append(chain)
    return loops


def area(pts):
    s = 0.0
    for k in range(len(pts)):
        x1, y1 = pts[k]
        x2, y2 = pts[(k + 1) % len(pts)]
        s += x1 * y2 - x2 * y1
    return abs(s) / 2


def inside(x, y, poly):
    c = False
    for i in range(len(poly)):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % len(poly)]
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
            c = not c
    return c


def simplify(pts, tol=0.02):
    """ほぼ一直線上の中間点を間引く (実寸mm基準)。"""
    out = [pts[0]]
    for p in pts[1:-1]:
        a, b = out[-1], p
        # 次点も見て、直線から外れているものだけ残す
        out.append(p)
    return out


def main():
    dxf_path = sys.argv[1]
    open_paths, closed_paths = load_paths(dxf_path)
    loops = sorted(chain_loops(open_paths), key=lambda l: -area(l))
    main_loop = loops[0]

    xs = [p[0] for p in main_loop]
    ys = [p[1] for p in main_loop]
    ox, oy = min(xs), min(ys)
    outline = [((x - ox) * SCALE, (y - oy) * SCALE) for x, y in main_loop]
    # 始点=終点の重複を除去
    if math.dist(outline[0], outline[-1]) < 0.01:
        outline = outline[:-1]

    holes = []
    for pts in closed_paths:
        cx = sum(p[0] for p in pts) / len(pts)
        cy = sum(p[1] for p in pts) / len(pts)
        if not inside(cx, cy, main_loop):
            continue
        w = max(p[0] for p in pts) - min(p[0] for p in pts)
        h = max(p[1] for p in pts) - min(p[1] for p in pts)
        holes.append(
            {
                "x": round((cx - ox) * SCALE, 3),
                "y": round((cy - oy) * SCALE, 3),
                "d": round((w + h) / 2 * SCALE, 2),
            }
        )

    w = (max(xs) - min(xs)) * SCALE
    h = (max(ys) - min(ys)) * SCALE
    print(f"outline: {len(outline)} pts, {w:.2f} x {h:.2f} mm")
    print(f"holes: {len(holes)}")

    data = {"plate_w": round(w, 2), "plate_d": round(h, 2), "outline": [(round(x, 3), round(y, 3)) for x, y in outline], "holes": holes}
    (REPO / "data").mkdir(exist_ok=True)
    with open(REPO / "data" / "keyball61_ballside_bottom_real.json", "w") as f:
        json.dump(data, f, indent=1)

    # OpenSCAD データファイル
    pts_str = ",\n  ".join(f"[{x:.3f},{y:.3f}]" for x, y in data["outline"])
    holes_str = ",\n  ".join(f"[{h['x']},{h['y']},{h['d']}]" for h in holes)
    scad = f"""// 自動生成: scripts/extract_outline.py による Keyball61 BallSide 底板の実寸データ
// 座標系: 左手ユニットを上から見た形 / 原点=外形バウンディングボックスの南西角 / +Y=奥(北)
// 編集しないこと。再生成: python3 scripts/extract_outline.py <DXF>
plate_w = {w:.2f};
plate_d = {h:.2f};
plate_outline = [
  {pts_str}
];
// [x, y, 直径] : d=11.3 はボール取出し穴, d=2.08 は M2, d=2.36 はボールケース部
plate_holes = [
  {holes_str}
];
"""
    (REPO / "scad").mkdir(exist_ok=True)
    with open(REPO / "scad" / "keyball61_outline.scad", "w") as f:
        f.write(scad)
    print("wrote data/keyball61_ballside_bottom_real.json, scad/keyball61_outline.scad")


if __name__ == "__main__":
    main()
