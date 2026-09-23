# Changelog

All notable changes to TeleCue will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project uses semantic versioning.

## [Unreleased]

### Changed

- The prompter engine, script model, settings, Markdown parsing, script rendering, and shared SwiftUI controls now live in a platform-neutral `TeleCueCore` library that builds for macOS 14 and iOS 17, in preparation for an iPhone and iPad app. The macOS app is now a thin shell over it; its behaviour is unchanged.

## [0.2.0] - 2026-09-23

### Added

- Markdown scripts (`.md`, `.markdown`) are now formatted in the prompter: headings are larger and bold, `**bold**` and `*italic*` are styled, lists show bullets or numbers, quotes are italic, and code is shown in a coloured monospaced font (code blocks left-aligned). Tables, diagram code blocks (Mermaid, PlantUML, Graphviz, D2), images, raw HTML, horizontal rules, and YAML front matter are hidden. Line breaks within a paragraph are kept as written. `.txt` scripts are still shown exactly as written.

### Fixed

- Word count and reading-time estimates for Markdown scripts count only the words spoken, not Markdown syntax, list bullets and numbers, or hidden content.

## [0.1.1] - 2026-09-19

### Fixed

- macOS release packaging now code-signs the fully assembled `TeleCue.app` bundle (executable, `Info.plist`, and resources) instead of relying on the stale ad-hoc signature left on the bare executable by `swift build`. This fixes Gatekeeper reporting the Homebrew-installed app as "damaged" (`code has no resources but signature indicates they must be present`).
- Release workflow now fails the build if `codesign --verify --deep --strict` does not pass, both right after signing and again after extracting the release ZIP, so a malformed `.app` can no longer reach a GitHub Release.

## [0.1.0] - 2026-09-17

### Added

- Native macOS TeleCue editor and always-on-top floating prompter window.
- UTF-8 plain text and Markdown file loading.
- Live word count and WPM-based reading-duration estimate.
- Elapsed-time smooth scrolling with play, pause, restart, and manual seek.
- Adjustable WPM, font size, line spacing model, and reading-focus position.
- Toggleable focus guide, horizontal mirror, and borderless presentation mode.
- Persistent local settings and prompter window placement.
- macOS keyboard shortcuts and native menu commands.
- Deterministic pacing, settings, model, and file-loading tests.
- Local `.app` packaging script and macOS continuous integration workflow.
- Automatic build-number increment on every `build-macos-app.sh` run, with `--major`, `--minor`, and `--revision` flags to bump the marketing version and reset the build number to 1.

### Fixed

- Copyright line break in the About panel now renders on two lines instead of collapsing to one.

[0.2.0]: https://github.com/repasscloud/telecue/compare/v0.1.1...v0.2.0
[0.1.1]: https://github.com/repasscloud/telecue/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/repasscloud/telecue/releases/tag/v0.1.0