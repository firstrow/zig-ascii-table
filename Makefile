.PHONY:run build
.SILENT:build

build:
	@$(MAKE) -C ./build

run:
	@zig build test
