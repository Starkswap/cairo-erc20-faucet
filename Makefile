.PHONY: all clean test

mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
mkfile_dir := $(dir $(mkfile_path))


all: artifacts artifacts/faucet.sierra

.DELETE_ON_ERROR: artifacts/faucet.sierra
artifacts/%.sierra: src/%.cairo cairo_project.toml
	$(STARKNET_COMPILE) -- . artifacts/$*.sierra

test: 
	$(STARKNET_TEST) --starknet .

artifacts:
	mkdir -p artifacts

clean:
	rm -rf venv
	rm -rf artifacts
