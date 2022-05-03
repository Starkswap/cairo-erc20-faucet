.PHONY: all clean test

SRC_FILES=faucet.cairo

OUT_FILES=$(SRC_FILES:.cairo=.comp.json)
OBJECTS = $(addprefix artifacts/, $(OUT_FILES))


mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir := $(dir $(mkfile_path))

CAIRO_DEPS=$(mkfile_dir)dependencies/openzeppelin/src

all: artifacts $(OBJECTS)

.DELETE_ON_ERROR: $(OBJECTS)
artifacts/%.comp.json: contracts/%.cairo
	starknet-compile --cairo_path=$(CAIRO_DEPS) $< --output artifacts/$*.comp.json --abi artifacts/$*.abi.json

test:
	PYTHONPATH=$(CAIRO_DEPS) pytest -s tests/

artifacts:
	mkdir -p artifacts

clean:
	rm -rf venv
	rm -f artifacts/*
