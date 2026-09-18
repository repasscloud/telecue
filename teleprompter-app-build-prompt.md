# Native Teleprompter App — Build Prompt

You are starting a new cross-platform teleprompter application repository.

The goal is to build **truly native desktop applications for macOS, Windows, and Linux**, while keeping the repository clean and keeping **all application source code under `./src`**.

Do not build this as Electron, Tauri, Avalonia, MAUI, Flutter, Qt, or another shared cross-platform UI framework.

The intended platform implementations are:

- **macOS:** Swift + SwiftUI, using AppKit where required for desktop/window behaviour.
- **Windows:** C# + modern .NET + WinUI 3.
- **Linux:** Rust + GTK4.

For the first phase, prioritise the **macOS implementation** and establish the repository structure so Windows and Linux can be added cleanly afterward.

---

## Product goal

Build a small, polished desktop teleprompter application for people recording videos, podcasts, presentations, tutorials, and webcam content.

The application should display a script in a small configurable floating window and scroll it smoothly at a speed that corresponds to natural speaking pace.

The application should feel like a lightweight desktop utility rather than a large editor or production suite.

The initial application does **not** require cloud services, user accounts, analytics, subscriptions, databases, or a web backend.

Everything should work locally.

---

# Repository structure

Keep the root of the repository clean and suitable for GitHub.

Use this general structure:

```text
.
├── .github/
├── .gitignore
├── LICENSE
├── README.md
├── CHANGELOG.md
├── docs/
├── scripts/
└── src/
    ├── macos/
    ├── windows/
    └── linux/
```

All product/application code must live underneath `./src`.

Do not place application projects directly in the repository root.

Platform-specific assets, tests, configuration, project files, and source files should stay inside the corresponding platform directory where practical.

Recommended target structure:

```text
src/
├── macos/
│   ├── Teleprompter.xcodeproj
│   ├── Teleprompter/
│   └── TeleprompterTests/
├── windows/
│   ├── Teleprompter.sln
│   ├── Teleprompter/
│   └── Teleprompter.Tests/
└── linux/
    ├── Cargo.toml
    ├── src/
    └── tests/
```

The exact generated Xcode/WinUI/GTK project structure may differ, but preserve the principle that each platform is fully contained beneath `src/<platform>`.

---

# Phase 1 priority

Start by implementing the **macOS application**.

The Windows and Linux directories may initially contain documentation/placeholders explaining the planned implementation, but do not create fake or non-functional application code merely to populate them.

The macOS version should be usable before moving on to Windows and Linux.

---

# macOS implementation

Use:

- Swift
- SwiftUI
- AppKit where SwiftUI does not expose the required desktop functionality cleanly
- Current stable macOS APIs

Target reasonably recent macOS versions rather than carrying unnecessary compatibility code for very old releases.

The application should be a normal `.app` bundle that can eventually be distributed outside the App Store.

Avoid unnecessary external dependencies.

Prefer native APIs and the Swift standard library.

---

# Core MVP features

Implement the following first.

## 1. Script entry

The user must be able to:

- paste text into the app;
- edit the script;
- load a plain text or Markdown file;
- clear the current script.

Markdown does not need rich rendering in the first version. It may initially be treated as readable plain text with sensible cleanup if needed.

The app should count words automatically.

Show at least:

- word count;
- estimated reading duration based on the selected WPM.

Example:

```text
742 words · approximately 4m 57s at 150 WPM
```

---

## 2. Words-per-minute based pacing

The primary speed control must be expressed in **words per minute**, not an arbitrary speed level.

Suggested range:

```text
80–250 WPM
```

Default:

```text
150 WPM
```

Allow fine adjustments, preferably in 5 WPM increments.

The scroll engine must calculate scrolling speed using:

```text
word count
selected WPM
rendered scrollable document height
available viewport height
```

The basic duration calculation is:

```text
durationSeconds = wordCount / wordsPerMinute * 60
```

The effective scrollable distance should account for viewport size so the application does not overscroll unnecessarily.

Conceptually:

```text
scrollableDistance = max(0, contentHeight - viewportHeight)
pixelsPerSecond = scrollableDistance / durationSeconds
```

Do not bind speed directly to frame count.

Use elapsed time so scrolling remains stable if frame timing varies.

---

## 3. Smooth scrolling

Scrolling must appear continuous.

Do not implement line-by-line stepping.

Use an animation/display timer appropriate for macOS and compute position from elapsed time.

The desired model is approximately:

```text
scrollPosition += pixelsPerSecond * elapsedSeconds
```

Prefer a display-linked or animation-friendly timing mechanism rather than a coarse one-second timer.

Avoid animation APIs that continuously create new implicit animations and drift away from the intended WPM.

The scroll engine should be easy to test independently from the UI where practical.

---

## 4. Play / pause / restart

Controls must include:

- Play
- Pause
- Restart from beginning

When paused, the scroll position must remain unchanged.

Restart should return to the start cleanly.

---

## 5. Manual positioning

The user should be able to manually scroll while paused.

If practical, allow manual repositioning while running and resume from the new position without jumping.

---

## 6. Font controls

Provide:

- increase font size;
- decrease font size;
- readable default font size;
- configurable line spacing if straightforward.

When the font size changes, recalculate the scroll metrics so the selected WPM remains approximately correct.

---

## 7. Teleprompter presentation mode

The app should have a dedicated teleprompter/presentation mode separate from script editing.

Presentation mode should support:

- dark background;
- bright readable text;
- minimal controls;
- resizable window;
- optional borderless presentation window;
- always-on-top behaviour;
- remembering the last window dimensions and position.

This window is expected to be positioned close to a webcam.

It should work well as a short, wide floating window such as approximately:

```text
900 × 250
```

but must remain freely resizable.

---

## 8. Focus / reading guide

Implement a visual reading focus area.

The current reading area should be visually stronger than text above and below it.

A reasonable first design is:

```text
older text         dimmed

CURRENT READING    bright
--------------------------
focus position

upcoming text      dimmed
```

This may be implemented using masks, gradients, overlays, or another performant native technique.

The user should be able to disable this feature.

The focus position should ideally be configurable vertically, because users may want the text close to the webcam position.

---

## 9. Mirror mode

Provide horizontal mirror mode for use with physical teleprompter glass.

The text area should flip horizontally without breaking scrolling behaviour.

---

## 10. Keyboard shortcuts

At minimum implement:

```text
Space       Play / pause
R           Restart
Up          Increase WPM
Down        Decrease WPM
Cmd +       Increase font size
Cmd -       Decrease font size
M           Toggle mirror mode
F           Toggle presentation/fullscreen-style mode
Esc         Leave presentation/fullscreen mode where appropriate
```

Choose native conventions where they conflict with the above.

Document all shortcuts in the README.

---

# Settings

Persist useful local preferences between launches.

At minimum remember:

- WPM;
- font size;
- focus mode enabled/disabled;
- focus position if configurable;
- mirror mode;
- teleprompter window dimensions;
- teleprompter window position.

Use native local settings storage.

Do not introduce a database.

---

# UX expectations

Keep the UI restrained and utility-focused.

Do not create a giant dashboard.

A sensible main window might have:

```text
┌──────────────────────────────────────────────────────┐
│ Open   Save?   Clear        150 WPM     ▶ / ⏸       │
├──────────────────────────────────────────────────────┤
│                                                      │
│ Script editor                                        │
│                                                      │
├──────────────────────────────────────────────────────┤
│ 742 words · 4m 57s             Open Prompter        │
└──────────────────────────────────────────────────────┘
```

And the floating teleprompter window might resemble:

```text
┌──────────────────────────────────────────────────────┐
│          previous content, visually dimmed           │
│                                                      │
│             CURRENT SENTENCE IS HERE                 │
│             AND EASY TO READ                         │
│ ---------------------------------------------------- │
│               upcoming content                      │
└──────────────────────────────────────────────────────┘
```

Avoid excessive chrome while the actual prompt is running.

---

# Architecture

Do not over-engineer the first version.

However, keep presentation logic separate enough from platform UI code that the application is testable and understandable.

For macOS, a reasonable conceptual split is:

```text
App/
Models/
Services/
Views/
ViewModels/        optional if useful
PrompterEngine/
```

The `PrompterEngine` should own calculations such as:

- WPM duration;
- scroll velocity;
- current progress;
- play/pause state where useful.

The UI should not contain duplicated pacing mathematics scattered across views.

Do not introduce a dependency-injection framework unless there is a concrete need.

---

# Testing

Add tests for logic that can be tested deterministically.

At minimum test:

- word counting;
- WPM-to-duration calculation;
- pixels-per-second calculation;
- zero/empty document handling;
- very short document handling;
- changing WPM;
- changing rendered height;
- pause/resume timing calculations if separated from the UI.

UI automation tests are optional for the MVP.

---

# Windows plan

Do not implement Windows before the macOS MVP works unless there is a compelling repository/bootstrap reason.

When Windows work starts, use:

- C#
- modern .NET
- WinUI 3 / Windows App SDK

The Windows application should be a genuinely native Windows desktop application.

Do not use MAUI.

It should implement the same product behaviour, but it does not need to share source code with macOS.

Keep all Windows source under:

```text
src/windows/
```

---

# Linux plan

When Linux work starts, use:

- Rust
- GTK4

Prefer native GTK components and standard Rust ecosystem libraries with a small dependency footprint.

Keep all Linux source under:

```text
src/linux/
```

The initial supported packaging target can be decided later, likely beginning with a common desktop Linux distribution/package format.

Do not block the macOS MVP on Linux packaging decisions.

---

# Cross-platform philosophy

The applications should have equivalent behaviour, but they do not need pixel-identical interfaces.

Each implementation should follow the conventions of its operating system.

Do not create abstractions purely for the sake of making the three codebases look identical.

If shared logic becomes substantial later, consider introducing a shared core at that point.

Do **not** create a Rust/C ABI/FFI shared core during the first phase.

The current logic is too small to justify that complexity.

---

# File support

For the initial version support opening:

```text
.txt
.md
.markdown
```

UTF-8 should be assumed where appropriate.

Handle file errors cleanly.

Do not crash if a file is empty or malformed.

---

# Future features — do not implement unless the MVP is stable

Design so these could reasonably be added later, but do not prematurely build them:

- script library;
- multiple saved scripts;
- remote control from a phone;
- Bluetooth/media-key controls;
- automatic speech-following;
- microphone-based pacing;
- AI script cleanup;
- AI rewriting;
- presenter notes;
- markers/chapters;
- multiple monitors;
- countdown before scrolling;
- custom themes;
- opacity control;
- text alignment options;
- margin controls;
- hotkey configuration;
- OSC/MIDI/Stream Deck integration;
- network synchronization;
- cloud sync.

Keep the first version small.

---

# Documentation

Create a useful root `README.md` containing:

- what the project is;
- current platform status;
- screenshots section placeholder;
- supported operating systems;
- development requirements;
- how to build the macOS project;
- how to run tests;
- keyboard shortcuts;
- repository layout;
- roadmap showing Windows and Linux as planned platforms.

Also create:

```text
CHANGELOG.md
```

using a simple maintainable format.

Add appropriate `.gitignore` rules for:

- Xcode;
- Swift build output;
- Visual Studio / .NET;
- Rust/Cargo;
- macOS metadata;
- editor temporary files.

Do not ignore source files or package lock files that should be committed for reproducible builds.

---

# GitHub

Prepare the project so it is suitable for a public GitHub repository.

Do not commit:

- generated build products;
- developer-specific paths;
- secrets;
- signing certificates;
- provisioning profiles;
- machine-specific configuration.

A `.github/workflows` directory may be created if useful.

For the first pass, a macOS CI workflow that builds/tests the project is desirable if it can be added cleanly.

Do not spend excessive time on release automation before the app itself works.

---

# Coding expectations

Prefer simple, readable implementations.

Avoid unnecessary abstractions.

Use comments where behaviour is non-obvious, particularly around:

- timing;
- scroll calculations;
- native window-level handling;
- AppKit integration.

Avoid comments that simply restate the code.

Use clear names.

Handle edge cases rather than silently allowing NaN, divide-by-zero, negative scroll speed, or invalid UI state.

---

# Initial execution plan

Start work in this order:

1. Inspect the repository and preserve any existing relevant files.
2. Establish the root repository structure.
3. Create the native macOS project beneath `src/macos`.
4. Implement the script editor.
5. Implement word counting and estimated duration.
6. Implement the isolated WPM/scroll calculation engine and tests.
7. Implement the floating teleprompter window.
8. Implement smooth timed scrolling.
9. Implement play/pause/restart.
10. Implement WPM controls.
11. Implement font controls.
12. Implement always-on-top/native floating-window behaviour.
13. Implement focus/read-guide mode.
14. Implement mirror mode.
15. Implement keyboard shortcuts.
16. Persist settings and window placement.
17. Add file-open support for `.txt` and Markdown.
18. Add/finish tests.
19. Write/update `README.md` and `CHANGELOG.md`.
20. Add basic macOS CI if practical.
21. Build and run the app and fix compile/runtime issues.
22. Leave clear notes for the future Windows and Linux ports.

---

# Important instructions while working

Do not merely generate scaffolding and stop.

Build a functioning macOS MVP.

Run builds and tests throughout development.

If the repository already contains files or conventions, inspect them first and integrate with them rather than blindly replacing them.

Make reasonable implementation decisions without repeatedly asking questions unless a decision would fundamentally change the product.

When a native API is required for behaviour such as always-on-top windows, use the native API rather than weakening the feature to avoid platform-specific code.

Keep application source under `./src`.

Keep the repository root clean.

At the end, provide a concise summary containing:

- files/directories created;
- what is working;
- commands used to build/test;
- any remaining limitations;
- recommended next development step.

---

# Definition of done for the first milestone

The macOS application should be considered MVP-complete when I can:

1. Launch the app.
2. Paste or open a script.
3. See its word count and estimated speaking duration.
4. Set approximately 150 WPM.
5. Open a small floating teleprompter window.
6. Position that window immediately below or near my webcam.
7. Press Space to begin smooth scrolling.
8. Pause and resume without the text jumping.
9. Adjust WPM while reading.
10. Adjust font size.
11. Restart the script.
12. Keep the window above other applications.
13. Toggle a reading-focus effect.
14. Toggle horizontal mirror mode.
15. Quit and relaunch the app with sensible settings restored.

The result should be a small, reliable native teleprompter rather than a prototype demonstrating scrolling text.
