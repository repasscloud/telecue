# TeleCue macOS MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a usable, polished native macOS TeleCue application that satisfies the first-milestone definition of done in the supplied build prompt.

**Architecture:** A dependency-free Swift package contains a SwiftUI executable and deterministic XCTest suite. A shared `TeleCueModel` owns script/settings/playback state, `PrompterEngine` owns all pacing mathematics, and an AppKit window controller hosts the dedicated floating SwiftUI prompter view and manages native window behavior.

**Tech Stack:** Swift 6, SwiftUI, AppKit, Foundation, XCTest, Swift Package Manager, shell app-bundle packaging.

**Spec:** `teleprompter-app-build-prompt.md`

## Global Constraints

- All application source, tests, resources, configuration, and project metadata live under `src/macos`.
- Root application namespace and product name are `TeleCue`; command/package naming uses `telecue` where lowercase is conventional.
- The macOS implementation is native SwiftUI/AppKit with no external dependencies or cross-platform UI framework.
- Pacing is 80–250 WPM, defaults to 150 WPM, changes in 5 WPM increments, and is based on elapsed time rather than frame count.
- Preferences use native local storage; no database, network service, account, analytics, or cloud dependency is introduced.
- `.txt`, `.md`, and `.markdown` are accepted as UTF-8 script files.

---

### Task 1: Repository and Swift package foundation

**Files:**
- Create: `.gitignore`, `LICENSE`, `README.md`, `CHANGELOG.md`
- Create: `src/macos/Package.swift`
- Create: `src/windows/README.md`, `src/linux/README.md`
- Create: `scripts/build-macos-app.sh`

**Interfaces:**
- Produces executable product `TeleCue`, test target `TeleCueTests`, and `scripts/build-macos-app.sh [debug|release]` producing `src/macos/build/TeleCue.app`.

- [ ] Create the clean repository layout and Swift package declaration.
- [ ] Add a minimal executable entry point so `swift build --package-path src/macos` resolves the toolchain.
- [ ] Run the build and confirm the package compiles before feature work.

### Task 2: Deterministic script metrics and pacing engine

**Files:**
- Create: `src/macos/Tests/TeleCueTests/ScriptMetricsTests.swift`
- Create: `src/macos/Tests/TeleCueTests/PrompterEngineTests.swift`
- Create: `src/macos/Sources/TeleCue/Models/ScriptMetrics.swift`
- Create: `src/macos/Sources/TeleCue/PrompterEngine/PrompterEngine.swift`

**Interfaces:**
- Produces `ScriptMetrics.wordCount(in:)`, `ScriptMetrics.durationSeconds(wordCount:wpm:)`, `PrompterMetrics`, and a value-semantic `PrompterEngine` with `play(at:)`, `pause(at:)`, `restart()`, `seek(to:at:)`, `update(at:)`, and metric recalculation.

- [ ] Write literal, table-driven word-count and duration tests covering whitespace, punctuation, empty input, and invalid WPM.
- [ ] Run the focused tests and confirm they fail because the types are absent.
- [ ] Implement the smallest metrics code that makes them pass.
- [ ] Write engine tests covering scroll distance, pixels per second, empty/short documents, pause/resume, seeking, WPM changes, and rendered-height changes.
- [ ] Run the focused tests and confirm expected failures.
- [ ] Implement and refactor the elapsed-time engine until all focused and package tests pass without warnings.

### Task 3: Persisted application model and file loading

**Files:**
- Create: `src/macos/Tests/TeleCueTests/SettingsTests.swift`
- Create: `src/macos/Tests/TeleCueTests/ScriptFileLoaderTests.swift`
- Create: `src/macos/Sources/TeleCue/Models/TeleCueSettings.swift`
- Create: `src/macos/Sources/TeleCue/Services/ScriptFileLoader.swift`
- Create: `src/macos/Sources/TeleCue/ViewModels/TeleCueModel.swift`

**Interfaces:**
- Produces Codable `TeleCueSettings` with clamped WPM/font/focus values, `ScriptFileLoader.load(from:)`, and main-actor `TeleCueModel` actions for editing, clearing, pacing, font, focus, mirror, and playback.

- [ ] Write failing normalization and file-type/error tests using temporary real files.
- [ ] Implement settings normalization and UTF-8 text/Markdown loading with user-readable errors.
- [ ] Run focused tests, then the complete suite.
- [ ] Add the observable model and native `UserDefaults` persistence around the tested value types.

### Task 4: Native editor window

**Files:**
- Create: `src/macos/Sources/TeleCue/App/TeleCueApp.swift`
- Create: `src/macos/Sources/TeleCue/Views/EditorView.swift`
- Create: `src/macos/Sources/TeleCue/Views/Controls/WPMControl.swift`
- Create: `src/macos/Sources/TeleCue/Views/Controls/ScriptStatusView.swift`

**Interfaces:**
- Consumes `TeleCueModel` and the native open panel.
- Produces an editable script surface, Open/Clear/Open Prompter actions, WPM and font controls, word count, estimated duration, file error alerts, and app commands.

- [ ] Build the restrained graphite/soft-blue native layout with readable labels and accessibility identifiers.
- [ ] Wire `.txt`, `.md`, and `.markdown` selection through `NSOpenPanel` to the tested loader.
- [ ] Implement native menu commands for Open, Clear, play/pause, restart, WPM, font size, mirror, focus, and presentation.
- [ ] Build the package and address compiler diagnostics before continuing.

### Task 5: Floating prompter window and smooth scrolling

**Files:**
- Create: `src/macos/Sources/TeleCue/App/PrompterWindowController.swift`
- Create: `src/macos/Sources/TeleCue/Views/PrompterView.swift`
- Create: `src/macos/Sources/TeleCue/Views/PrompterTextView.swift`
- Create: `src/macos/Sources/TeleCue/Views/FocusGuideOverlay.swift`

**Interfaces:**
- Produces a reusable AppKit floating panel with remembered frame, native always-on-top behavior, optional borderless mode, smooth display-linked offset updates, focus dimming/rule, mirror transform, and manual scrolling while paused or running.

- [ ] Host the SwiftUI prompter in an AppKit panel sized initially to 900×250 and set its level to floating.
- [ ] Measure rendered document and viewport sizes and feed them to the engine.
- [ ] Drive scrolling from elapsed timestamps using `TimelineView(.animation)` while preserving pause/resume position.
- [ ] Implement drag/wheel manual positioning and rebase elapsed timing after seeking.
- [ ] Add the adjustable focus band, toggleable dimming, horizontal mirror mode, and minimal hover controls.
- [ ] Persist window frame on move/resize and restore it safely onto an available screen.
- [ ] Build and manually launch the bundle to exercise editor-to-prompter flow.

### Task 6: Keyboard behavior and native window lifecycle

**Files:**
- Modify: `src/macos/Sources/TeleCue/App/TeleCueApp.swift`
- Modify: `src/macos/Sources/TeleCue/App/PrompterWindowController.swift`
- Modify: `src/macos/Sources/TeleCue/Views/PrompterView.swift`

**Interfaces:**
- Produces Space, R, Up, Down, Command-Plus, Command-Minus, M, F, and Escape behavior without interfering with script editing.

- [ ] Add local key handling scoped to the prompter panel and command-menu equivalents available app-wide.
- [ ] Toggle borderless presentation/fullscreen-style behavior while retaining the floating frame.
- [ ] Ensure Escape exits presentation mode and closing/reopening the prompter does not lose model state.
- [ ] Run package tests and build the app bundle.

### Task 7: Documentation, CI, and packaging

**Files:**
- Complete: `README.md`, `CHANGELOG.md`
- Create: `.github/workflows/macos.yml`
- Complete: `scripts/build-macos-app.sh`
- Create: `src/macos/Resources/Info.plist`

**Interfaces:**
- Produces documented build/test commands and an unsigned local `TeleCue.app` bundle suitable for launching with `open`.

- [ ] Package the release executable and Info.plist into the app bundle with stable `au.com.telecue.TeleCue` identity.
- [ ] Add macOS CI for `swift test` and release build.
- [ ] Document platform status, requirements, commands, shortcuts, layout, screenshots placeholder, roadmap, and known MVP limitations.
- [ ] Record the initial MVP under an Unreleased changelog section.

### Task 8: Full verification and visual review

**Files:**
- Modify only files implicated by verification failures or visible defects.

**Interfaces:**
- Produces fresh evidence that the package tests, release build, app bundle, and launch smoke check succeed.

- [ ] Run `swift test --package-path src/macos` and confirm zero failures and zero warnings.
- [ ] Run `swift build -c release --package-path src/macos` and confirm zero errors and zero warnings.
- [ ] Run `scripts/build-macos-app.sh release`, inspect the bundle, and validate its Info.plist.
- [ ] Launch `src/macos/build/TeleCue.app`, inspect both windows, exercise controls and shortcuts, and fix visible/runtime issues.
- [ ] Re-run the complete test/build/package sequence after the final fix.
