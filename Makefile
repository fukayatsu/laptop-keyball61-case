OPENSCAD ?= /opt/homebrew/bin/openscad
PARTS = side_left side_right bridge brace plate_left plate_right touchid_pod

all: $(PARTS:%=stl/%.stl) stl/touchid_pod_battery.stl

stl/%.stl: scad/parts_%.scad scad/*.scad
	$(OPENSCAD) -o $@ $<

# バッテリー内蔵バージョンのポッド
stl/touchid_pod_battery.stl: scad/parts_touchid_pod.scad scad/*.scad
	$(OPENSCAD) -D tid_battery=true -o $@ $<

# v3 モジュラー構造(検討中の別案)
V3_PARTS = v3_kb_box_left v3_kb_box_right v3_palm_box_left v3_palm_box_right v3_center_box v3_center_lid v3_plate_left v3_plate_right v3_pod

v3: $(V3_PARTS:%=stl/%.stl)

stl/v3_%.stl: scad/v3/parts_v3_%.scad scad/v3/*.scad scad/*.scad
	$(OPENSCAD) -o $@ $<

# v3 STLの設計検証(要: pip install trimesh numpy)
PYTHON ?= python3
check: v3
	$(PYTHON) scripts/verify_v3.py

.PHONY: v3 check

images:
	$(OPENSCAD) -o docs/images/assembly_top.png --imgsize 1600,800 --camera 0,110,0,0,0,0,560 --projection o scad/assembly.scad
	$(OPENSCAD) -o docs/images/assembly_persp.png --imgsize 1600,900 --camera 0,60,0,55,0,25,780 scad/assembly.scad
	$(OPENSCAD) -o docs/images/assembly_adjusted.png --imgsize 1600,900 --camera 0,60,0,55,0,25,780 -D demo_rotate=12 -D demo_slide=-15 scad/assembly.scad

clean:
	rm -f stl/*.stl

.PHONY: all images clean
