OPENSCAD ?= /opt/homebrew/bin/openscad

# v4 平面構造(2mmプレート+切妻スパイン+下面カバー)
V4_PARTS = v4_plate_left v4_plate_right v4_center_spine v4_center_cover

all: $(V4_PARTS:%=stl/%.stl)

v4: all

stl/v4_%.stl: scad/v4/parts_v4_%.scad scad/v4/*.scad scad/*.scad
	$(OPENSCAD) -o $@ $<

# STLの設計検証(要: pip install trimesh numpy)
PYTHON ?= python3
check: all
	$(PYTHON) scripts/verify_v4.py

check-v4: check

images:
	$(OPENSCAD) -o docs/images/v4_persp.png --imgsize 1600,900 --camera 0,150,0,55,0,25,760 scad/v4/v4_assembly.scad
	$(OPENSCAD) -o docs/images/v4_exploded.png --imgsize 1600,1000 --camera 0,150,30,60,0,30,950 -D explode=40 scad/v4/v4_assembly.scad

clean:
	rm -f stl/*.stl

.PHONY: all v4 check check-v4 images clean
