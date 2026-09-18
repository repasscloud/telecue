# Changelog

All notable changes to TeleCue will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and the project uses semantic versioning.

## [Unreleased]

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

