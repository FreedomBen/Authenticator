.PHONY: build setup compile test install uninstall clean distclean fmt clippy help

MESON ?= meson
CARGO ?= cargo

BUILD_DIR ?= _build
PREFIX ?= /usr/local

# Default target
build: compile

compile: setup
	$(MESON) compile -C $(BUILD_DIR)

setup:
	@if [ ! -f "$(BUILD_DIR)/build.ninja" ]; then \
		$(MESON) setup "$(BUILD_DIR)" --prefix="$(PREFIX)"; \
	fi

test: setup
	$(MESON) test -C $(BUILD_DIR)

install: compile
	$(MESON) install -C $(BUILD_DIR)

uninstall:
	ninja -C $(BUILD_DIR) uninstall

clean:
	@if [ -f "$(BUILD_DIR)/build.ninja" ]; then \
		$(MESON) compile -C $(BUILD_DIR) --clean; \
	fi

distclean:
	rm -rf "$(BUILD_DIR)"

fmt:
	$(CARGO) fmt

clippy:
	$(CARGO) clippy --all-targets --all-features -- -D warnings

help:
	@printf "%s\n" \
		"Targets:" \
		"  build (default)  Configure (if needed) and build via Meson" \
		"  test             Run Meson tests" \
		"  install          Install from $(BUILD_DIR) (respects PREFIX)" \
		"  uninstall        Uninstall previously installed files" \
		"  clean            Clean build artifacts (keeps $(BUILD_DIR))" \
		"  distclean        Remove $(BUILD_DIR) entirely" \
		"  fmt              Run cargo fmt" \
		"  clippy           Run cargo clippy --all-targets --all-features -D warnings"
