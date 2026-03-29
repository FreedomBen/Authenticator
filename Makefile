.PHONY: build setup compile test install uninstall clean distclean fmt clippy rpm install-rpm help

MESON ?= meson
CARGO ?= cargo

BUILD_DIR ?= _build
PREFIX ?= /usr/local
RPM_DIR ?= $(BUILD_DIR)/rpm
SPEC_FILE ?= build-aux/authenticator.spec
VERSION = $(shell grep "^Version:" $(SPEC_FILE) | awk '{print $$2}')

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
		"  clippy           Run cargo clippy --all-targets --all-features -D warnings" \
		"  rpm              Build RPM package (requires rpmbuild, cargo-vendor-filterer)" \
		"  install-rpm      Build and install RPM via dnf"
