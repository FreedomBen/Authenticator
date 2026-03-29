# Repository Guidelines

## Project Structure & Module Organization
- `src/` holds the Rust GTK app: `main.rs` boots `application.rs`, `widgets/` exposes composite views, `models/` owns Diesel types, `backup/` handles import/export, and `utils.rs` stores shared helpers.
- Database metadata sits in `schema.rs` and `migrations/`; UI templates, icons, desktop/metainfo files, and search-provider bits live in `data/resources` and `data/icons`.
- Supporting assets include the `favicon-scrapper/` helper crate, tooling in `tools/`, translations in `po/`, and screenshots/logos under `data/`.

## Build, Test, and Development Commands
- `meson setup _build --prefix=/usr` prepares a local build dir with the correct GTK resources and Cargo flags.
- `meson compile -C _build` builds the app; `meson install -C _build` stages it system-wide or into a destdir.
- `meson test -C _build` triggers registered suites; `cargo test --lib` is handy for quick Rust iterations.
- `flatpak-builder --user --install --force-clean _flatpak build-aux/com.belmoussaoui.Authenticator.Devel.json` matches the GNOME Builder runtime.
- `cargo fmt` plus `cargo clippy -- -D warnings` enforce the repo’s `rustfmt.toml`.

## Coding Style & Naming Conventions
- Use Rust 2021, four-space indentation, snake_case files/modules, and UpperCamelCase for types and GTK composite templates.
- Keep new resources and schemas in kebab-case (`com.belmoussaoui.Authenticator.*`) beneath `data/`, mirroring the existing gschema/metainfo layout.
- Break out sizable widgets into their own module under `src/widgets` with matching template XML.

## Testing Guidelines
- Co-locate `#[cfg(test)]` modules with the code under test and reuse fixtures from `src/backup/tests/*.json`.
- Schema or data changes require Diesel migrations plus a local `diesel migration run` check; update `schema.rs` accordingly.
- UI or portal edits should be validated with `meson test -C _build` followed by a manual Flatpak launch.

## Commit & Pull Request Guidelines
- Write short, imperative summaries similar to the current history (“Update Catalan translation”, “Improve backup errors”) and reference issues via `Fixes #123`.
- PRs must describe the user-facing change, note testing evidence (commands + screenshots for UI work), and call out any migration or Flatpak manifest updates.
- Keep branches focused; squash noisy WIP commits before review and force-push only when coordinated.

## Security & Configuration Tips
- Never commit live OTP secrets; anonymize fixtures and prefer generated placeholders.
- Update `build-aux/com.belmoussaoui.Authenticator.Devel.json` and related `data/*.service` files together so Flatpak permissions and DBus services stay in sync.
