# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Authenticator is a GNOME desktop/mobile application for generating two-factor authentication codes (TOTP/HOTP/Steam). Built with Rust, GTK 4, and libadwaita. Licensed GPL-3.0-or-later. Hosted on GNOME GitLab.

## Build Commands

The project uses a **dual build system**: Meson orchestrates the overall build (resources, i18n, installation) and invokes Cargo for the Rust compilation.

```bash
make build          # Configure (if needed) and build via Meson (default target)
make test           # Run tests via Meson
make fmt            # cargo fmt
make clippy         # cargo clippy -- -D warnings
make distclean      # Remove _build/ entirely
```

**Direct Cargo commands** (useful for faster iteration on Rust code only):
```bash
cargo clippy --all-targets --workspace --all-features -- -D warnings
cargo test --workspace --all-features --all-targets
cargo fmt --all -- --check    # Check formatting
```

Note: Meson generates `src/config.rs` from `src/config.rs.in` during setup. A full `make build` is needed at least once before `cargo` commands will work (the generated config must exist). The build directory is `_build/` by default.

**Flatpak build** (for full integration testing):
```bash
flatpak-builder --force-clean --repo=_flatpak_repo _flatpak build-aux/com.belmoussaoui.Authenticator.Devel.json
```

## Architecture

### Entry Point and Startup

`src/main.rs` → initializes tracing, GTK, aperture (camera), i18n, GResources, then launches `Application::run()`.

`src/application.rs` → `Application` is an `AdwApplication` subclass managing app lifecycle: keyring init, settings, providers model loading, window creation, GNOME Shell search provider, and auto-lock timeout.

### Core Layers

- **Models** (`src/models/`): GObject-based data types with reactive properties (`glib::Properties` derive macro)
  - `Account` / `Provider` / `OTP` — 2FA account data and code generation
  - `ProvidersModel` (`providers.rs`) — top-level list model aggregating all providers/accounts
  - `Database` — Diesel SQLite ORM with migrations in `migrations/`
  - `Keyring` — Secret storage via `oo7` crate
  - `Settings` — GSettings wrapper
  - `SearchProvider` — GNOME Shell search integration

- **Widgets** (`src/widgets/`): GTK4/libadwaita UI components
  - `Window` — main `AdwApplicationWindow` with `NavigationView`
  - Dialogs for adding accounts, backup/restore, preferences, provider management

- **Backup** (`src/backup/`): Import/export for multiple formats (Aegis encrypted/plain, FreeOTP+, Google Authenticator, andOTP, Bitwarden, Yandex, RaivoOTP)

- **Favicon Scrapper** (`favicon-scrapper/`): In-tree sub-crate for fetching provider favicons. Has its own tests in `favicon-scrapper/tests/`.

### Key Patterns

- GObject subclassing throughout models and widgets (ObjectSubclass, ObjectImpl, etc.)
- `LazyLock` statics for app-wide singletons: `RUNTIME` (Tokio), `SETTINGS`, `SECRET_SERVICE`
- Tokio async runtime for non-blocking keyring/database/network operations
- `src/schema.rs` is Diesel-generated — edit migrations, not this file directly
- `src/config.rs` is Meson-generated from `src/config.rs.in` — do not edit directly
- Translations use gettext via `formatx` crate (replaces a former in-tree i18n module)

### Data Layer

- SQLite database managed by Diesel ORM
- 7 migration sets in `migrations/` — add new migrations via `diesel migration generate`
- Secrets stored in system keyring via `oo7` (freedesktop Secret Service)

## Code Style

- Rust edition 2021, MSRV 1.80
- `rustfmt.toml`: imports grouped by `StdExternalCrate`, crate-level granularity, Unix newlines, comments wrapped and normalized
- Clippy warnings are errors (`-D warnings`)
- Development profile builds in Meson install a git pre-commit hook (`hooks/pre-commit.hook`) that enforces formatting

## CI/CD

GitLab CI (`.gitlab-ci.yml`): rustfmt check → Flatpak builds (x86_64 + aarch64), cargo clippy, cargo test, doc generation → nightly Flathub publishing.

## Native Build Dependencies (Fedora)

```
gtk4-devel libadwaita-devel gstreamer1-devel gstreamer1-plugins-base-devel
```
