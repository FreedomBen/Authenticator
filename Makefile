.PHONY: build setup compile test install check-prefix-writable uninstall clean distclean fmt clippy rpm install-rpm run help

MESON ?= meson
CARGO ?= cargo

BUILD_DIR ?= _build
PREFIX ?= $(HOME)/.local
RPM_DIR ?= $(BUILD_DIR)/rpm
SPEC_FILE ?= build-aux/authenticator.spec
VERSION = $(shell grep "^Version:" $(SPEC_FILE) | awk '{print $$2}')

# Default target
build: compile

compile: setup
	$(MESON) compile -C $(BUILD_DIR)

setup:
	@if [ -f "$(BUILD_DIR)/build.ninja" ]; then \
		$(MESON) setup "$(BUILD_DIR)" --prefix="$(PREFIX)" --reconfigure; \
	else \
		$(MESON) setup "$(BUILD_DIR)" --prefix="$(PREFIX)"; \
	fi

test: setup
	$(MESON) test -C $(BUILD_DIR)

check-prefix-writable:
	@prefix="$(PREFIX)"; \
	while [ ! -e "$${prefix}" ]; do prefix="$$(dirname "$${prefix}")"; done; \
	if [ ! -w "$${prefix}" ]; then \
		echo "error: PREFIX '$(PREFIX)' is not writable by $$(id -un)." >&2; \
		echo "       Re-run with sudo, or install to a user-writable location, e.g.:" >&2; \
		echo "         sudo make install" >&2; \
		echo "         make install PREFIX=\$$HOME/.local" >&2; \
		exit 1; \
	fi

install: check-prefix-writable
	@if [ ! -x "$(BUILD_DIR)/src/authenticator" ]; then \
		echo "error: no built binary at $(BUILD_DIR)/src/authenticator." >&2; \
		echo "       Run 'make build' first as a non-root user, then re-run 'sudo make install'." >&2; \
		echo "       (Compile is decoupled from install so rustup/cargo can resolve the user's toolchain.)" >&2; \
		exit 1; \
	fi
	$(MESON) install --no-rebuild -C $(BUILD_DIR)

uninstall:
	ninja -C $(BUILD_DIR) uninstall

rpm:
	rm -rf $(RPM_DIR)
	mkdir -p $(RPM_DIR)/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
	git archive --format=tar.gz --prefix=Authenticator-$(VERSION)/ HEAD > $(RPM_DIR)/SOURCES/Authenticator-$(VERSION).tar.gz
	cd $$(mktemp -d) && \
		tar xf $(CURDIR)/$(RPM_DIR)/SOURCES/Authenticator-$(VERSION).tar.gz && \
		cd Authenticator-$(VERSION) && \
		cargo vendor && \
		tar cJf $(CURDIR)/$(RPM_DIR)/SOURCES/vendor.tar.xz vendor/
	cp $(SPEC_FILE) $(RPM_DIR)/SPECS/
	rpmbuild --define "_topdir $(CURDIR)/$(RPM_DIR)" --nodeps -ba $(RPM_DIR)/SPECS/authenticator.spec

install-rpm: rpm
	sudo dnf install -y $(RPM_DIR)/RPMS/*/*.rpm

run: compile
	$(MESON) devenv -C $(BUILD_DIR) src/authenticator

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
		"  setup            Run meson setup (reconfigures if already configured)" \
		"  build (default)  Configure (if needed) and build via Meson" \
		"  test             Run Meson tests" \
		"  run              Build and run the application via meson devenv" \
		"  install          Install from $(BUILD_DIR) (PREFIX=$(PREFIX); run 'make build' first)" \
		"  uninstall        Uninstall previously installed files" \
		"  clean            Clean build artifacts (keeps $(BUILD_DIR))" \
		"  distclean        Remove $(BUILD_DIR) entirely" \
		"  fmt              Run cargo fmt" \
		"  clippy           Run cargo clippy --all-targets --all-features -D warnings" \
		"  rpm              Build RPM package (requires rpmbuild, cargo-vendor-filterer)" \
		"  install-rpm      Build and install RPM via dnf"
