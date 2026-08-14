OPENSCAD ?= /opt/homebrew/bin/openscad
PARTS = carriage_left carriage_right base_left base_center base_right touchid_pod

all: $(PARTS:%=stl/%.stl) stl/touchid_pod_battery.stl

stl/%.stl: scad/parts_%.scad scad/*.scad
	$(OPENSCAD) -o $@ $<

# バッテリー内蔵バージョンのポッド
stl/touchid_pod_battery.stl: scad/parts_touchid_pod.scad scad/*.scad
	$(OPENSCAD) -D tid_battery=true -o $@ $<

images:
	$(OPENSCAD) -o docs/images/assembly_top.png --imgsize 1600,800 --camera 0,110,0,0,0,0,560 --projection o scad/assembly.scad
	$(OPENSCAD) -o docs/images/assembly_persp.png --imgsize 1600,900 --camera 0,60,0,55,0,25,780 scad/assembly.scad
	$(OPENSCAD) -o docs/images/assembly_adjusted.png --imgsize 1600,900 --camera 0,60,0,55,0,25,780 -D demo_rotate=12 -D demo_slide=-15 scad/assembly.scad

clean:
	rm -f stl/*.stl

.PHONY: all images clean
