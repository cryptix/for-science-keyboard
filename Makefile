#!/usr/bin/make

.PHONY: erc drc sch_fab pcb_fab erc_and_fab drc_and_fab

DEBUG=
OUT_DIR=build

define generate_pcb
	echo "-- PCB fab. ($(1)) ..."; \
	mkdir -p "$(OUT_DIR)"; \
	find . -type f -name '*.kicad_pcb' ! -path './build/*' \
		| while read -r kicad_pcb; \
	do \
		echo "-- PCB fab. for '$$kicad_pcb' ..."; \
		base_path="$${kicad_pcb%.kicad_pcb}"; \
		base_path="$${base_path#./}"; \
		base_file="$$(echo "$$base_path" | tr '/' '-')"; \
		out_dir="$(OUT_DIR)/$$base_path"; \
		echo "Building PCB Fabrication files for '$$kicad_pcb' at '$$out_dir', skipping '$(1)' ..."; \
		kibot $(DEBUG) --out-dir "$$out_dir" --board-file "$$kicad_pcb" --schematic "" --skip-pre $(1) \
			print_front print_bottom print_gnd print_power print_s1 print_s2 gerbers \
			excellon_drill gerber_drills position step pcb_top_g pcb_bot_g pcb_top_b \
			pcb_bot_b pcb_top_r pcb_bot_r; \
		echo "--"; \
	done; \
	echo "-- PCB fab. done."
endef

all: erc_and_fab drc_and_fab

erc:
	echo "-- ERC ..."; \
	mkdir -p "$(OUT_DIR)"; \
	find . -type f -name '*.sch' ! -path './build/*' \
		| while read -r sch; \
	do \
		echo "-- ERC for '$$sch' ..."; \
		kibot $(DEBUG) --out-dir $(OUT_DIR) --schematic "$$sch" \
			--skip-pre run_drc --invert-sel; \
		echo "--"; \
	done; \
	echo "-- ERC done."

drc:
	echo "-- DRC ..."; \
	mkdir -p "$(OUT_DIR)"; \
	find . -type f -name '*.kicad_pcb' ! -path './build/*' \
		| while read -r kicad_pcb; \
	do \
		echo "-- DRC for '$$kicad_pcb' ..."; \
		kibot $(DEBUG) --out-dir $(OUT_DIR) --board-file "$$kicad_pcb" \
			--skip-pre run_erc --invert-sel; \
		echo "--"; \
	done; \
	echo "-- DRC done."

sch_fab:
	echo "-- Schema fab. ..."; \
	mkdir -p "$(OUT_DIR)"; \
	find . -type f -name '*.sch' ! -path './build/*' \
		| while read -r sch; \
	do \
		echo "-- Schema fab. for '$$sch' ..."; \
		kibot $(DEBUG) --out-dir $(OUT_DIR) --schematic "$$sch" \
			--skip-pre run_erc,run_drc print_sch bom_html bom_xlsx bom_csv; \
		echo "--"; \
	done
	echo "-- Schema fab. done."

pcb_fab:
	$(call generate_pcb,all)

erc_and_fab: sch_fab erc

drc_and_fab:
	$(call generate_pcb,run_erc)

