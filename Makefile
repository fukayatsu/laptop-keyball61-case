OPENSCAD ?= /opt/homebrew/bin/openscad

# v4 平面構造(2mmプレート+切妻スパイン+下面カバー)
V4_PARTS = v4_plate_left v4_plate_right v4_center_spine v4_center_cover

# Touch IDモジュール取付用(カバー内に入れる小物)
TOUCHID_PARTS = touchid_plate touchid_foot

all: $(V4_PARTS:%=stl/%.stl) $(TOUCHID_PARTS:%=stl/%.stl)

v4: $(V4_PARTS:%=stl/%.stl)

touchid: $(TOUCHID_PARTS:%=stl/%.stl)

stl/v4_%.stl: scad/v4/parts_v4_%.scad scad/v4/*.scad scad/*.scad
	$(OPENSCAD) -o $@ $<

stl/touchid_%.stl: scad/touchid/parts_touchid_%.scad scad/touchid/*.scad scad/*.scad
	$(OPENSCAD) -o $@ $<

# STLの設計検証(要: pip install trimesh numpy)
PYTHON ?= python3
check: all
	$(PYTHON) scripts/verify_v4.py
	$(PYTHON) scripts/verify_touchid.py

check-v4: v4
	$(PYTHON) scripts/verify_v4.py

check-touchid: touchid
	$(PYTHON) scripts/verify_touchid.py

images:
	$(OPENSCAD) -o docs/images/v4_persp.png --imgsize 1600,900 --camera 0,150,0,55,0,25,760 scad/v4/v4_assembly.scad
	$(OPENSCAD) -o docs/images/v4_exploded.png --imgsize 1600,1000 --camera 0,150,30,60,0,30,950 -D explode=40 scad/v4/v4_assembly.scad

clean:
	rm -f stl/*.stl

.PHONY: all v4 touchid check check-v4 check-touchid images clean
